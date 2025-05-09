name: Argo CD GitOps CI/CD

on:
  push:
    branches:
      - main

jobs:
  build:
    name: Build and Push the image
    runs-on: [self-hosted]

    steps:
    - name: Check out code
      uses: actions/checkout@v2

    - name: Bump version
      id: bump_version
      run: |
        chmod +x build-push-to-gh/bump_version.sh
        ./build-push-to-gh/bump_version.sh
        new_version=$(cat VERSION-GH)
        echo "new_version=$new_version" >> $GITHUB_ENV

    - name: Commit new version and updated WorkflowTemplate.yaml
      run: |
        git config --global user.name 'sosotechnologies'
        git config --global user.email 'sosotech2000@gmail.com'
        git add VERSION-GH build-push-to-gh/WorkflowTemplate.yaml
        git commit -m "Bump version to ${{ env.new_version }}" || echo "No changes to commit"
        git stash
        git pull --rebase origin main
        git stash pop || echo "No stashed changes"
        git push origin main

    - name: Build the Docker image
      run: |
        cd build-push-to-gh
        docker build -t ghcr.io/${{ github.repository }}/node-app:${{ env.new_version }} .

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'ghcr.io/${{ github.repository }}/node-app:${{ env.new_version }}'
        format: 'table'
        exit-code: '0'
        ignore-unfixed: true
        vuln-type: 'os,library'
        severity: 'MEDIUM,HIGH,CRITICAL'
        output: 'build-push-to-gh/trivy-report.txt'

    - name: Package Trivy report
      uses: actions/upload-artifact@v4
      with:
        name: trivy-report
        path: build-push-to-gh/trivy-report.txt

    - name: Push the Docker image to GitHub Container Registry
      run: |
        echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
        docker push ghcr.io/${{ github.repository }}/node-app:${{ env.new_version }}
        docker tag ghcr.io/${{ github.repository }}/node-app:${{ env.new_version }} ghcr.io/${{ github.repository }}/node-app:latest
        docker push ghcr.io/${{ github.repository }}/node-app:latest

  sonar:
    name: SonarQube Code Scan
    runs-on: ubuntu-latest
    needs: build

    steps:
    - name: Check out code
      uses: actions/checkout@v2

    - name: Analyze with SonarQube
      uses: SonarSource/sonarqube-scan-action@v1.1.0
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
      with:
        args: >
          -Dsonar.projectKey=node-app
          -Dsonar.sources=build-push-to-gh

  deploy:
    name: Deploy to Argo
    runs-on: ubuntu-latest
    needs: build

    steps:
    - name: Check out code
      uses: actions/checkout@v2

    - name: Check VERSION-GH file content
      run: cat VERSION-GH

    - name: Print WorkflowTemplate.yaml before update
      run: cat build-push-to-gh/WorkflowTemplate.yaml
