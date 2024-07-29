# AWS ECR

## get your repo’s URL and password

go to ECR service on AWS console:

[https://us-east-2.console.aws.amazon.com/ecr/repositories?region=us-east-2](https://us-east-2.console.aws.amazon.com/ecr/repositories?region=us-east-2)

select the repo (or create a new one), then click **view push commands**

copy this command from the top of the pop-up (**don’t run it**):

```bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 11223344.dkr.ecr.us-east-2.amazonaws.com
```

this is the **repo URL**:

```bash
11223344.dkr.ecr.us-east-2.amazonaws.com
```

run this to print the ECR repo password to terminal:

```bash
aws ecr get-login-password --region us-east-2
```

## define your ECR repo in  environment

go to **Containers** → **add new registry**:

```bash
# URL:
11223344.dkr.ecr.us-east-2.amazonaws.com

# USER:
AWS

# PASS:
<**PREVIOUSLY_GENERATED_PASSWORD>**
```