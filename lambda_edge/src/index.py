import json

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    uri = request['uri']

    # Redirect any .html URL to its equivalent without .html
    if uri.endswith(".html"):
        return {
            "status": "301",
            "statusDescription": "Moved Permanently",
            "headers": {
                "location": [{
                    "key": "Location",
                    "value": uri[:-5]  # Removes '.html' without adding a slash
                }]
            }
        }

    return request
