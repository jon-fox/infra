import boto3
import time
import requests

sqs = boto3.client('sqs')
ssm = boto3.client('ssm')
autoscaling = boto3.client('autoscaling')

QUEUE_URL = ssm.get_parameter(Name="/sqs/audio_processing/url")['Parameter']['Value']
AUTO_SCALING_GROUP = ssm.get_parameter(Name="/asg/name")['Parameter']['Value']
ALERTS_WEBHOOK = ssm.get_parameter(Name="/application/discord/webhook")['Parameter']['Value']

def notify_scaling_action(desired_capacity):
    try:
        print(f"Sending notification for scaling action. New desired capacity: {desired_capacity}")
        message = f"Scaling down action taken. New desired capacity after scale down: {desired_capacity}"
        response = requests.post(ALERTS_WEBHOOK, json={"content": message})
        print(f"Notification sent successfully, {response}")
    except Exception as e:
        print(f"Error sending notification: {e}")

def get_queue_attributes():
    response = sqs.get_queue_attributes(
        QueueUrl=QUEUE_URL,
        AttributeNames=[
            'ApproximateNumberOfMessages',
            'ApproximateNumberOfMessagesNotVisible'
        ]
    )
    queue_length = int(response['Attributes'].get('ApproximateNumberOfMessages', 0))
    in_flight_messages = int(response['Attributes'].get('ApproximateNumberOfMessagesNotVisible', 0))
    return queue_length, in_flight_messages

def lambda_handler(event, context):
    # First check
    queue_length, in_flight_messages = get_queue_attributes()

    # Wait a short period (e.g., 10 seconds) and check again
    time.sleep(10)
    queue_length_second, in_flight_messages_second = get_queue_attributes()

    # Use the higher of the two measurements, or decide based on your logic
    queue_length = max(queue_length, queue_length_second)
    in_flight_messages = max(in_flight_messages, in_flight_messages_second)

    # Check ASG current capacity
    asg_response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[AUTO_SCALING_GROUP]
    )
    asg = asg_response['AutoScalingGroups'][0]
    current_capacity = asg['DesiredCapacity']
    min_size = asg['MinSize']
    
    # Determine if scaling down is needed
    if queue_length == 0 and in_flight_messages == 0 and current_capacity > min_size:
        new_capacity = max(min_size, current_capacity - 1)  # Scale down by 1
        autoscaling.update_auto_scaling_group(
            AutoScalingGroupName=AUTO_SCALING_GROUP,
            DesiredCapacity=new_capacity
        )
        print(f"Scaled down ASG to {new_capacity} instances.")
        notify_scaling_action(new_capacity)
    else:
        print(f"No scaling action needed. Queue length = {queue_length}, In-flight = {in_flight_messages}, ASG capacity = {current_capacity}")
    
    return {
        'queue_length': queue_length,
        'in_flight_messages': in_flight_messages,
        'current_capacity': current_capacity
    }
