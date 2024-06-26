# URL Shortener: DevOps-Centric Project

## Overview
This project is a DevOps-centric URL shortener designed to showcase my proficiency in modern DevOps tools and practices.

## Features
- **GitHub Actions:** Automated CI/CD pipelines for building, testing, and deploying the application.
- **ArgoCD:** GitOps continuous delivery tool to manage the Kubernetes resources.
- **Kubernetes:** Scalable container orchestration to manage the application deployment, scaling, and operations.
- **Helm:** Helm charts to define, install, and upgrade the Kubernetes application.
- **Terraform:** Infrastructure as Code (IaC) to provision and manage the EKS infrastructure.
- **Shell:** For an easy-to-use, all-in-one deployment script - All you need is an AWS Access key!
- **React:** For user interface.
- **Flask:** For handling backend logic and API endpoints.
- **MongoDB:** For data storage.

## Usage

### Deployment using EKS

1. **Ensure Prerequisites are installed:**
   - AWS CLI
   - ArgoCD CLI
   - kubectl
   - Helm
   - Terraform

2. **Run the Deployment Script:**
   ```sh
   ./start-eks.sh
   
### Deployment using Minikube

1. **Ensure Prerequisites are installed:**
   - Docker
   - Minikube
   - ArgoCD CLI
   - kubectl
   - Helm

2. **Run the Deployment Script:**
    ```sh
    ./start-legacy.sh
    ```

## Architecture Diagram
![image](https://github.com/galg-gh/url-shortener/assets/91409344/8368c9eb-33e6-4d1f-9e24-e898e7801381)

<p align="center">
<img src="https://github.com/galg-gh/url-shortener/assets/91409344/d35923a5-67fe-4af5-9a8f-6cea3f6231a7" />
</p>

## Contribution
Feel free to open issues or submit pull requests for improvements and bug fixes. Contributions are welcome!
