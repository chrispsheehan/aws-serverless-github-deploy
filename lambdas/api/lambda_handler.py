import json

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({"message": "Hello from Lambda!"})
    }
    return response
