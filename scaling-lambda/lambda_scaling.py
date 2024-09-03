import json
import boto3
import os

autoscaling = boto3.client('autoscaling')

def lambda_handler(event, context):
    message = event['Records'][0]['Sns']['Message']
    asg_name = os.environ['AUTOSCALING_GROUP_NAME']
    
    response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[asg_name]
    )
    
    desired_capacity = response['AutoScalingGroups'][0]['DesiredCapacity']

    if 'scale up' in message.lower():
        autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=desired_capacity + 1
        )
        return {
            'statusCode': 200,
            'body': json.dumps('Scaled Up')
        }
    
    elif 'scale down' in message.lower():
        autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=desired_capacity - 1
        )
        return {
            'statusCode': 200,
            'body': json.dumps('Scaled Down')
        }
    
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid Command')
        }
