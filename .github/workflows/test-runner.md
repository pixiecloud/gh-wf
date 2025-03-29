name: Test Self-Hosted Runner

on:
  push:
    branches:
      - main
jobs:
  test-runner:
    runs-on: [self-hosted]

    steps:
    - name: Print runner hostname and environment info
      run: |
        echo "Hello from the self-hosted runner!"
        echo "Hostname: $(hostname)"
        echo "OS Info:"
        uname -a
        echo "Current directory:"
        pwd
        echo "Directory listing:"
        ls -lah
        echo "Can I reach SonarQube?"
        curl -I https://sonarqube.pixiescloud.com || echo "Cannot reach SonarQube"
