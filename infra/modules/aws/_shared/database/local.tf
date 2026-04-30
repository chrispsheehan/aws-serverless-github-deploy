locals {
  username_prefix             = "app"
  username_suffix_length      = 8
  master_username             = "${local.username_prefix}${random_string.db_user_suffix.result}"
  ssm_name_prefix             = "/${var.environment}/${var.project_name}/${var.database_name}"
  database_ssm_name           = "${local.ssm_name_prefix}/db-name"
  readonly_endpoint_ssm_name  = "${local.ssm_name_prefix}/readonly-endpoint"
  readwrite_endpoint_ssm_name = "${local.ssm_name_prefix}/readwrite-endpoint"

  cluster_identifier       = "${var.project_name}-${var.environment}-${var.database_name}-aurora"
  subnet_group_name        = "${var.project_name}-${var.environment}-${var.database_name}-rds-subnet-group"
  security_group_name      = "${var.project_name}-${var.environment}-${var.database_name}-postgres-sg"
  serverless_database_name = replace(var.database_name, "-", "_")

  postgres_engine         = "aurora-postgresql"
  postgres_instance_class = "db.serverless"
  postgres_backup_window  = "07:00-09:00"

  recovery_profiles = {
    dev = {
      backup_retention_period = 1
      deletion_protection     = false
      skip_final_snapshot     = true
      final_snapshot_prefix   = null
      restore_drill_cadence   = "never"
      restore_drill_schedule  = null
      target_rpo_minutes      = 1440
      target_rto_minutes      = 240
      minimum_reader_count    = 0
    }
    standard = {
      backup_retention_period = 7
      deletion_protection     = true
      skip_final_snapshot     = false
      final_snapshot_prefix   = "final"
      restore_drill_cadence   = "monthly"
      restore_drill_schedule  = "rate(30 days)"
      target_rpo_minutes      = 15
      target_rto_minutes      = 60
      minimum_reader_count    = 1
    }
    critical = {
      backup_retention_period = 35
      deletion_protection     = true
      skip_final_snapshot     = false
      final_snapshot_prefix   = "final"
      restore_drill_cadence   = "weekly"
      restore_drill_schedule  = "rate(7 days)"
      target_rpo_minutes      = 5
      target_rto_minutes      = 30
      minimum_reader_count    = 2
    }
  }

  recovery_profile = local.recovery_profiles[var.recovery_class]

  subnet_ids_ordered = tolist(var.subnet_ids)
  subnet_azs_all     = [for id in local.subnet_ids_ordered : data.aws_subnet.selected[id].availability_zone]
  subnet_azs         = distinct(local.subnet_azs_all)
  reader_count       = min(length(local.subnet_azs), max(var.rds_max_reader_count, local.recovery_profile.minimum_reader_count))

  final_snapshot_identifier = local.recovery_profile.skip_final_snapshot ? null : format(
    "%s-%s",
    local.cluster_identifier,
    local.recovery_profile.final_snapshot_prefix,
  )

  restore_drill = merge(
    {
      enabled      = false
      mode         = "manual"
      use_pitr     = true
      retain_hours = 4
    },
    {
      schedule_expression = local.recovery_profile.restore_drill_schedule
    },
    var.restore_drill,
  )

  restore_drill_state_machine_enabled = local.restore_drill.enabled
  restore_drill_schedule_enabled = local.restore_drill.enabled && contains(
    ["scheduled", "manual_and_scheduled"],
    local.restore_drill.mode,
  ) && local.restore_drill.schedule_expression != null
  restore_drill_identifier_prefix = substr("${local.cluster_identifier}-drill", 0, 30)
  restore_drill_instance_class    = "db.serverless"
  restore_drill_retention_seconds = local.restore_drill.retain_hours * 3600

  restore_drill_state_machine_definition = jsonencode({
    Comment = "Restore-drill skeleton for ${local.cluster_identifier}"
    StartAt = "PrepareContext"
    States = {
      PrepareContext = {
        Type = "Pass"
        Parameters = {
          "source_cluster_identifier"  = aws_rds_cluster.aurora_postgres.cluster_identifier
          "db_subnet_group_name"       = aws_db_subnet_group.default.name
          "vpc_security_group_ids"     = [var.database_security_group_id]
          "publicly_accessible"        = var.publicly_accessible
          "scratch_suffix.$"           = "States.ArrayGetItem(States.StringSplit(States.UUID(), '-'), 0)"
          "use_latest_restorable_time" = local.restore_drill.use_pitr
          "retention_seconds"          = local.restore_drill_retention_seconds
        }
        Next = "BuildIdentifiers"
      }
      BuildIdentifiers = {
        Type = "Pass"
        Parameters = {
          "source_cluster_identifier.$"   = "$.source_cluster_identifier"
          "db_subnet_group_name.$"        = "$.db_subnet_group_name"
          "vpc_security_group_ids.$"      = "$.vpc_security_group_ids"
          "publicly_accessible.$"         = "$.publicly_accessible"
          "scratch_suffix.$"              = "$.scratch_suffix"
          "use_latest_restorable_time.$"  = "$.use_latest_restorable_time"
          "retention_seconds.$"           = "$.retention_seconds"
          "restore_cluster_identifier.$"  = format("States.Format('{}-{}', '%s', $.scratch_suffix)", local.restore_drill_identifier_prefix)
          "restore_instance_identifier.$" = format("States.Format('{}-{}-writer', '%s', $.scratch_suffix)", local.restore_drill_identifier_prefix)
        }
        Next = "StartRestore"
      }
      StartRestore = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:restoreDBClusterToPointInTime"
        Parameters = {
          "SourceDBClusterIdentifier.$" = "$.source_cluster_identifier"
          "DBClusterIdentifier.$"       = "$.restore_cluster_identifier"
          "RestoreType"                 = "copy-on-write"
          "UseLatestRestorableTime.$"   = "$.use_latest_restorable_time"
          "Engine"                      = local.postgres_engine
          "DBSubnetGroupName.$"         = "$.db_subnet_group_name"
          "VpcSecurityGroupIds.$"       = "$.vpc_security_group_ids"
          "DeletionProtection"          = false
          "Tags" = [
            {
              "Key"   = "RestoreDrill"
              "Value" = "true"
            },
            {
              "Key"   = "SourceCluster"
              "Value" = aws_rds_cluster.aurora_postgres.cluster_identifier
            },
          ]
        }
        Next = "WaitForCluster"
      }
      WaitForCluster = {
        Type    = "Wait"
        Seconds = 60
        Next    = "DescribeCluster"
      }
      DescribeCluster = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:describeDBClusters"
        Parameters = {
          "DBClusterIdentifier.$" = "$.restore_cluster_identifier"
        }
        ResultPath = "$.cluster_status"
        Next       = "ClusterReady"
      }
      ClusterReady = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.cluster_status.DBClusters[0].Status"
            StringEquals = "available"
            Next         = "CreateScratchInstance"
          },
        ]
        Default = "WaitForCluster"
      }
      CreateScratchInstance = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:createDBInstance"
        Parameters = {
          "DBClusterIdentifier.$"  = "$.restore_cluster_identifier"
          "DBInstanceIdentifier.$" = "$.restore_instance_identifier"
          "DBInstanceClass"        = local.restore_drill_instance_class
          "Engine"                 = local.postgres_engine
          "PubliclyAccessible.$"   = "$.publicly_accessible"
        }
        Next = "WaitForInstance"
      }
      WaitForInstance = {
        Type    = "Wait"
        Seconds = 60
        Next    = "DescribeInstance"
      }
      DescribeInstance = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:describeDBInstances"
        Parameters = {
          "DBInstanceIdentifier.$" = "$.restore_instance_identifier"
        }
        ResultPath = "$.instance_status"
        Next       = "InstanceReady"
      }
      InstanceReady = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.instance_status.DBInstances[0].DBInstanceStatus"
            StringEquals = "available"
            Next         = "RetentionWindow"
          },
        ]
        Default = "WaitForInstance"
      }
      RetentionWindow = {
        Type        = "Wait"
        SecondsPath = "$.retention_seconds"
        Next        = "DeleteScratchInstance"
      }
      DeleteScratchInstance = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:deleteDBInstance"
        Parameters = {
          "DBInstanceIdentifier.$" = "$.restore_instance_identifier"
          "SkipFinalSnapshot"      = true
          "DeleteAutomatedBackups" = true
        }
        Next = "WaitBeforeClusterDelete"
      }
      WaitBeforeClusterDelete = {
        Type    = "Wait"
        Seconds = 300
        Next    = "DeleteScratchCluster"
      }
      DeleteScratchCluster = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:rds:deleteDBCluster"
        Parameters = {
          "DBClusterIdentifier.$" = "$.restore_cluster_identifier"
          "SkipFinalSnapshot"     = true
        }
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 120
            MaxAttempts     = 10
            BackoffRate     = 1.5
          },
        ]
        End = true
      }
    }
  })
}
