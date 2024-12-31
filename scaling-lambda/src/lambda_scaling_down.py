import boto3

sqs = boto3.client('sqs')
ssm = boto3.client('ssm')
autoscaling = boto3.client('autoscaling')

QUEUE_URL = ssm.get_parameter(Name="/sqs/audio_processing/url")['Parameter']['Value']
AUTO_SCALING_GROUP = ssm.get_parameter(Name="/asg/name")['Parameter']['Value']

def lambda_handler(event, context):
    # Get the queue attributes
    response = sqs.get_queue_attributes(
        QueueUrl=QUEUE_URL,
        AttributeNames=[
            'ApproximateNumberOfMessages',       # Messages waiting to be processed
            'ApproximateNumberOfMessagesNotVisible'  # In-flight messages
        ]
    )
    queue_length = int(response['Attributes']['ApproximateNumberOfMessages'])
    in_flight_messages = int(response['Attributes']['ApproximateNumberOfMessagesNotVisible'])
    
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
    else:
        print(f"No scaling action needed. Queue length = {queue_length}, In-flight = {in_flight_messages}, ASG capacity = {current_capacity}")
    
    return {
        'queue_length': queue_length,
        'in_flight_messages': in_flight_messages,
        'current_capacity': current_capacity
    }
