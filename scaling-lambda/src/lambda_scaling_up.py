import boto3
import time

sqs = boto3.client('sqs')
ssm = boto3.client('ssm')
sns = boto3.client('sns')
autoscaling = boto3.client('autoscaling')

QUEUE_URL = ssm.get_parameter(Name="/sqs/audio_processing/url")['Parameter']['Value']
AUTO_SCALING_GROUP = ssm.get_parameter(Name="/asg/name")['Parameter']['Value']
SNS_TOPIC = ssm.get_parameter(Name="/sns/scaling_topic_arn")['Parameter']['Value']

MESSAGES_PER_INSTANCE = 10  # Customize based on processing capacity of each instance

def notify_scaling_action(desired_capacity):
    try:
        print(f"Sending SNS notification for scaling action. New desired capacity: {desired_capacity}")
        message = f"Scaling action taken. New desired capacity: {desired_capacity}"
        sns.publish(
            TopicArn=SNS_TOPIC,
            Message=message,
            Subject="Auto Scaling Notification"
        )
        print("SNS notification sent successfully")
    except Exception as e:
        print(f"Error sending SNS notification: {e}")

def get_queue_length():
    response = sqs.get_queue_attributes(
        QueueUrl=QUEUE_URL,
        AttributeNames=['ApproximateNumberOfMessages']
    )
    return int(response['Attributes']['ApproximateNumberOfMessages'])

def lambda_handler(event, context):
    # First read of queue length
    initial_queue_length = get_queue_length()
    # Wait for 10 seconds to allow SQS to become eventually consistent
    time.sleep(10)
    # Second read of queue length
    second_queue_length = get_queue_length()
    
    # Use the maximum value from the two checks
    queue_length = max(initial_queue_length, second_queue_length)
    
    # Calculate the required number of EC2 instances based on your MESSAGES_PER_INSTANCE factor
    required_instances = (queue_length + MESSAGES_PER_INSTANCE - 1) // MESSAGES_PER_INSTANCE  # Ceiling division
    
    # Get current ASG capacity and bounds
    asg_response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[AUTO_SCALING_GROUP]
    )
    asg = asg_response['AutoScalingGroups'][0]
    current_capacity = asg['DesiredCapacity']
    min_size = asg['MinSize']
    max_size = asg['MaxSize']

    print(f"Queue length: {queue_length}, Required instances: {required_instances}, Current capacity: {current_capacity}")
    print(f"ASG min size: {min_size}, max size: {max_size}")
    
    # Ensure the desired capacity is within bounds
    desired_capacity = max(min_size, min(required_instances, max_size))
    
    # if no instances and queue length is greater than or equal to 1, start with 1 instance
    if current_capacity == 0 and queue_length >= 1:
        print(f"No instances available, starting with 1 instance for queue length {queue_length}")
        desired_capacity = 1

    # Ensure desired capacity is at least 1 if there are messages in the queue
    if queue_length > 0 and desired_capacity < 1:
        desired_capacity = 1

    # Update the ASG if the capacity needs adjustment
    if desired_capacity != current_capacity:
        print(f"Updating ASG desired capacity to {desired_capacity}")
        autoscaling.update_auto_scaling_group(
            AutoScalingGroupName=AUTO_SCALING_GROUP,
            DesiredCapacity=desired_capacity
        )
        notify_scaling_action(desired_capacity)
    else:
        print("No scaling action required")
    
    return {
        'queue_length': queue_length,
        'desired_capacity': desired_capacity
    }
