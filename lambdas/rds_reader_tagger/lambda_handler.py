import os

import boto3

from lambda_shared import get_logger, json_response


EVENT_ID = "RDS-EVENT-0005"
logger = get_logger(__name__)


def _non_aws_tags(tags):
    return {
        tag["Key"]: tag["Value"]
        for tag in tags
        if not tag["Key"].startswith("aws:")
    }


def _sync_reader_tags(rds, cluster_arn, reader):
    reader_id = reader["DBInstanceIdentifier"]
    reader_arn = reader["DBInstanceArn"]

    desired_tags = _non_aws_tags(
        rds.list_tags_for_resource(ResourceName=cluster_arn)["TagList"]
    )
    current_tags = _non_aws_tags(
        rds.list_tags_for_resource(ResourceName=reader_arn)["TagList"]
    )

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
        "reader_id": reader_id,
        "tags_added": [tag["Key"] for tag in tags_to_add],
        "tags_removed": tag_keys_to_remove,
        "changed": bool(tags_to_add or tag_keys_to_remove),
    }


def _get_cluster(rds, cluster_id):
    return rds.describe_db_clusters(DBClusterIdentifier=cluster_id)["DBClusters"][0]


def _sync_cluster_readers(rds, cluster_id, reader_ids=None):
    cluster = _get_cluster(rds, cluster_id)
    cluster_arn = cluster["DBClusterArn"]
    reader_id_set = set(reader_ids or [])

    results = []
    for member in cluster.get("DBClusterMembers", []):
        if member.get("IsClusterWriter"):
            continue

        reader_id = member["DBInstanceIdentifier"]
        if reader_id_set and reader_id not in reader_id_set:
            continue

        reader = rds.describe_db_instances(DBInstanceIdentifier=reader_id)["DBInstances"][0]
        results.append(_sync_reader_tags(rds, cluster_arn, reader))

    return {
        "ok": True,
        "cluster_id": cluster_id,
        "mode": "scan" if not reader_ids else "event",
        "readers_checked": len(results),
        "readers_changed": sum(1 for result in results if result["changed"]),
        "results": results,
    }


def lambda_handler(event, context):
    event = event or {}
    detail = event.get("detail", {})
    reader_id = detail.get("SourceIdentifier", "").strip()
    event_id = detail.get("EventID", "").strip()
    expected_cluster_id = os.environ["EXPECTED_CLUSTER_IDENTIFIER"]

    rds = boto3.client("rds", region_name=os.environ["AWS_REGION"])

    if not detail:
        result = _sync_cluster_readers(rds, expected_cluster_id)
        logger.info(
            "rds_reader_tagger_scan_complete",
            extra={
                "event": "rds_reader_tagger_scan_complete",
                "request_id": context.aws_request_id,
                **result,
            },
        )
        return json_response(200, result)

    if event_id != EVENT_ID:
        raise ValueError(f"Unexpected EventID: {event_id}")

    if not reader_id:
        raise ValueError("Missing SourceIdentifier in RDS event detail")

    reader = rds.describe_db_instances(DBInstanceIdentifier=reader_id)["DBInstances"][0]
    cluster_id = reader.get("DBClusterIdentifier", "")
    if cluster_id != expected_cluster_id:
        logger.info(
            "rds_reader_tagger_cluster_mismatch",
            extra={
                "event": "rds_reader_tagger_cluster_mismatch",
                "request_id": context.aws_request_id,
                "reader_id": reader_id,
                "cluster_id": cluster_id,
                "expected_cluster_id": expected_cluster_id,
            },
        )
        return json_response(
            200,
            {
                "ok": True,
                "skipped": True,
                "reason": "cluster_mismatch",
                "reader_id": reader_id,
                "cluster_id": cluster_id,
                "expected_cluster_id": expected_cluster_id,
            },
        )

    result = _sync_cluster_readers(rds, cluster_id, reader_ids=[reader_id])
    logger.info(
        "rds_reader_tagger_event_complete",
        extra={
            "event": "rds_reader_tagger_event_complete",
            "request_id": context.aws_request_id,
            "source_event_id": event_id,
            "source_reader_id": reader_id,
            **result,
        },
    )
    return json_response(200, result)
