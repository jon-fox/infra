import json

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    uri = request['uri']

    # Remove .html from URLs (redirect users)
    if uri.endswith(".html"):
        return {
            "status": "301",
            "statusDescription": "Moved Permanently",
            "headers": {
                "location": [{
                    "key": "Location",
                    "value": uri[:-5]  # Removes .html
                }]
            }
        }

    # Ensure S3 receives a valid file request
    if not uri.endswith("/") and "." not in uri:
        request.uri += ".html"  # Append .html for S3 compatibility

    return request
