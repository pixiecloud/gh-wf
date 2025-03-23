name: Argo CD GitOps CI/CD

on:
  push:
    branches:
      - main

jobs:
  build:
    name: Build and Push the image
    runs-on: ubuntu-latest

    steps:
    - name: Check out code
      uses: actions/checkout@v2

    - name: Bump version
      id: bump_version
      run: |
        chmod +x build-push-to-ECR/bump_version.sh && ./build-push-to-ECR/bump_version.sh
        new_version=$(cat VERSION)
        echo "::set-output name=new_version::$new_version"

    - name: Build the Docker image
      run: |
        cd build-push-to-ECR
        docker build -t ${{ steps.bump_version.outputs.new_version }} .

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${{ steps.bump_version.outputs.new_version }}'
        format: 'table'
        exit-code: '0'
        ignore-unfixed: true
        vuln-type: 'os,library'
        severity: 'MEDIUM,HIGH,CRITICAL'
        output: 'trivy-report.txt'

    - name: Upload Trivy report
      uses: actions/upload-artifact@v3
      with:
        name: trivy-report
        path: build-push-to-ECR/trivy-report.txt

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Tag and Push Docker image to Amazon ECR
      run: |
        IMAGE_TAG=${{ steps.bump_version.outputs.new_version }}
        ECR_REGISTRY=${{ secrets.AWS_ACCOUNT_NUMBER }}.dkr.ecr.us-east-1.amazonaws.com
        REPOSITORY=xcite
        docker tag $IMAGE_TAG $ECR_REGISTRY/$REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$REPOSITORY:$IMAGE_TAG
        docker tag $IMAGE_TAG $ECR_REGISTRY/$REPOSITORY:latest
        docker push $ECR_REGISTRY/$REPOSITORY:latest

  deploy:
    name: Deploy to Argo CD
    runs-on: ubuntu-latest
    needs: build

    steps:
    - name: Check out code
      uses: actions/checkout@v4

    - name: Check VERSION file content
      run: cat VERSION

    - name: Print WorkflowTemplate.yaml before update
      run: cat build-push-to-gh/WorkflowTemplate.yaml