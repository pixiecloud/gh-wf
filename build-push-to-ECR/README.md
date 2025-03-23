## Create an ECR Repo: xcite
call it: xcite

## Add the following variables: 

AWS_ACCESS_KEY_ID
AWS_ACCOUNT_NUMBER
AWS_ECR_REPO
AWS_REGION
AWS_SECRET_ACCESS_KEY


## Run image
```sh
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-number>.dkr.ecr.us-east-1.amazonaws.com

docker pull <your-account-number>.dkr.ecr.us-east-1.amazonaws.com/xcite:latest

docker run -itdp 8088:8088 <your-account-number>.dkr.ecr.us-east-1.amazonaws.com/xcite:latest
```