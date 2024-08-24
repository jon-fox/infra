# infra
common infra repo for projects

aws ec2 describe-images --filters "Name=architecture,Values=x86_64" --query "Images[*].[ImageId,Name,Description]" --output table

aws ec2 describe-images --filters "Name=architecture,Values=arm64" --query "Images[*].[ImageId,Name,Description]" --output table

https://cloud-images.ubuntu.com/locator/ec2/

# for the sso identity taking it and exporting it directly into the terminal worked

export AWS_SHARED_CREDENTIALS_FILE=~/.aws/credentials
export AWS_CONFIG_FILE=~/.aws/config

REGION="us-east-1"
ACCOUNT_ID=""

CREDENTIALS=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/terraform-dev --role-session-name terraform)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com