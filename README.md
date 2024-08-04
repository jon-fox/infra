# infra
common infra repo for projects

aws ec2 describe-images --filters "Name=architecture,Values=x86_64" --query "Images[*].[ImageId,Name,Description]" --output table

aws ec2 describe-images --filters "Name=architecture,Values=arm64" --query "Images[*].[ImageId,Name,Description]" --output table

https://cloud-images.ubuntu.com/locator/ec2/