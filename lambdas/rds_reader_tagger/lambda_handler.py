import os

import boto3


EVENT_ID = "RDS-EVENT-0005"


def _non_aws_tags(tags):
    return {
        tag["Key"]: tag["Value"]
        for tag in tags
        if not tag["Key"].startswith("aws:")
    }


def lambda_handler(event, context):
    detail = event.get("detail", {})
    reader_id = detail.get("SourceIdentifier", "").strip()
    event_id = detail.get("EventID", "").strip()
    expected_cluster_id = os.environ["EXPECTED_CLUSTER_IDENTIFIER"]

    if event_id != EVENT_ID:
        raise ValueError(f"Unexpected EventID: {event_id}")

    if not reader_id:
        raise ValueError("Missing SourceIdentifier in RDS event detail")

    rds = boto3.client("rds", region_name=os.environ["AWS_REGION"])

    reader = rds.describe_db_instances(DBInstanceIdentifier=reader_id)["DBInstances"][0]
    cluster_id = reader.get("DBClusterIdentifier", "")
    if cluster_id != expected_cluster_id:
        return {
            "ok": True,
            "skipped": True,
            "reason": "cluster_mismatch",
            "reader_id": reader_id,
            "cluster_id": cluster_id,
            "expected_cluster_id": expected_cluster_id,
        }

    cluster = rds.describe_db_clusters(DBClusterIdentifier=cluster_id)["DBClusters"][0]

    cluster_arn = cluster["DBClusterArn"]
    reader_arn = reader["DBInstanceArn"]

    desired_tags = _non_aws_tags(rds.list_tags_for_resource(ResourceName=cluster_arn)["TagList"])
    current_tags = _non_aws_tags(rds.list_tags_for_resource(ResourceName=reader_arn)["TagList"])

    tags_to_add = [
        {"Key": key, "Value": value}
        for key, value in desired_tags.items()
        if current_tags.get(key) != value
    ]
    tag_keys_to_remove = [
        key for key in current_tags.keys() if key not in desired_tags
    ]

    if tags_to_add:
        rds.add_tags_to_resource(ResourceName=reader_arn, Tags=tags_to_add)

    if tag_keys_to_remove:
        rds.remove_tags_from_resource(ResourceName=reader_arn, TagKeys=tag_keys_to_remove)

    return {
        "ok": True,
        "reader_id": reader_id,
        "cluster_id": cluster_id,
        "tags_added": [tag["Key"] for tag in tags_to_add],
        "tags_removed": tag_keys_to_remove,
    }
