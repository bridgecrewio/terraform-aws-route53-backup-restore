[![Maintained by Bridgecrew.io](https://img.shields.io/badge/maintained%20by-bridgecrew.io-blueviolet)](https://bridgecrew.io)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/bridgecrewio/terraform-aws-route53-backup-restore.svg?label=latest)](https://github.com/bridgecrewio/terraform-aws-route53-backup-restore/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)
[![CircleCI](https://circleci.com/gh/bridgecrewio/terraform-aws-route53-backup-restore.svg?style=svg)](https://circleci.com/gh/bridgecrewio/terraform-aws-route53-backup-restore)

# Setup Route53 Backup 
Amazon Route53 is a managed DNS web service. Route53 is often a mission critical asset in the organization. 
 
The following tool enables:
 1. Create route53 backup bucket 
 2. Backup of Route53 DNS Records
 3. Backup of Route53 Health checks
 4. Restore capability to both of the above

## Architecture
### Backup data flow
![backup](https://github.com/bridgecrewio/terraform-aws-route53-backup-restore/blob/master/images/backup.png)
### Restore data flow
![restore](https://github.com/bridgecrewio/terraform-aws-route53-backup-restore/blob/master/images/restore.png)
## Prerequisites:
* Valid access keys at `~/.aws/credentials` with a default profile configured or matching [AWS Environment Variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)  
* `Python` ,`Pipenv` & `npm` installed on the host running the tool

## Integrate backup & restore module using terraform
This module can be integrated into an existing terraform framework. To add it, simply add the following module to your 
terraform code:
```
module "route53-backup-restore" {
  source      = "bridgecrewio/route53-backup-restore/aws"
  aws_profile = "dev"
  region      = "us-east-1"
  interval    = "120"
  retention   = "14"
}
``` 
Please note that all the above values are the default values, and therefore these specific values can be omitted.

## Deploy backup & restore lambdas manually
 
```bash
git clone https://github.com/bridgecrewio/terraform-aws-route53-backup-restore.git
cd terraform-aws-route53-backup-restore
npm i 
sls deploy --backup-interval ${INTERVAL_IN_MINUTES} --retention-period ${RETENTION_PERIOD} --region ${REGION} --aws-profile ${PROFILE}
```
### Deployment parameters:

| Key             | Description                                             | Default value |
|-----------------|---------------------------------------------------------|---------------|
| profile         | AWS profile, from the AWS credentials file, to be used  | default       |
| region          | Region of resources to be deployed                      | us-east-1     |
| backup-interval | Interval, in minutes, of scheduled backup               | 120 minutes   |
| retention-period| The time, in days, the backup is stored for             | 14            |


## Manually triggering route53 backup 
using aws CLI - trigger `backup-route53` lambda.
```bash
aws lambda invoke --function-name backup-route53 --profile ${profile} --region ${region} --output text /dev/stdout
```
## Restoring data from bucket
using aws CLI - trigger `restore-route53` lambda.
```bash
aws lambda invoke --function-name restore-route53 --profile ${profile} --region ${region} --output text /dev/stdout
```

## Route53 backup bucket security configuration
When the lambda creates the S3 bucket it ensures that it has:
* Bucket versioning enabled
* Data encrypted at rest
* Data encrypted at transport
* Bucket is set to private
* Bucket has lifecycle policy that deletes files older than `retention-period` days