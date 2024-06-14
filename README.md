# URL Shortener: DevOps-Centric Project

## Overview
This project is a DevOps-centric URL shortener designed to showcase proficiency in modern DevOps tools and practices. It leverages GitHub Actions for CI/CD, ArgoCD for GitOps, Kubernetes (K8s) for container orchestration, Helm for application deployment, Terraform for infrastructure as code, and Amazon EKS for managed Kubernetes clusters.

## Features
- **GitHub Actions:** Automated CI/CD pipelines for building, testing, and deploying the application.
- **ArgoCD:** GitOps continuous delivery tool to manage Kubernetes resources.
- **Kubernetes (K8s):** Scalable container orchestration to manage application deployment, scaling, and operations.
- **Helm:** Helm charts to define, install, and upgrade Kubernetes applications.
- **Terraform:** Infrastructure as Code (IaC) to provision and manage cloud infrastructure.
- **Amazon EKS:** Managed Kubernetes service to simplify running Kubernetes on AWS.
- **Frontend:** React-based user interface.
- **Backend:** Flask for handling backend logic and API endpoints.
- **Database:** MongoDB for data storage.

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
