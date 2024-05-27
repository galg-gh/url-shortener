#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to handle errors and exit if a command fails
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Function to set AWS credentials using user input
set_aws_credentials() {
    echo "Please enter your AWS credentials."
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
    read -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    read -p "AWS Region: " AWS_REGION

    AWS_DEFAULT_REGION="$AWS_REGION"

    # Verify AWS credentials
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "$AWS_DEFAULT_REGION"

    # Validate credentials
    aws sts get-caller-identity >/dev/null 2>&1
    check_success "AWS credentials validation"
}

# Function to initialize and apply Terraform configuration
apply_terraform() {
    echo "Initializing and applying Terraform configuration..."

    if command_exists terraform; then
        cd deployment/eks/terraform || exit 1
        terraform init
        check_success "terraform init"

        terraform apply -auto-approve
        check_success "terraform apply"

        # Return to the original directory
        cd - >/dev/null || exit 1

    else
        echo "Terraform is not installed. Please install Terraform and try again."
        exit 1
    fi
}

# Function to configure AWS CLI and create EKS cluster
configure_aws_eks() {
    echo "Configuring AWS CLI and creating EKS cluster..."

    if command_exists aws; then
        aws eks update-kubeconfig --name your-cluster-name --region "$AWS_DEFAULT_REGION"
        check_success "aws eks update-kubeconfig"

    else
        echo "AWS CLI is not installed. Please install AWS CLI and try again."
        exit 1
    fi
}

# Function to install ArgoCD
install_argocd() {
    echo "Installing ArgoCD..."

    if command_exists kubectl; then
        kubectl create namespace argocd
        check_success "kubectl create namespace argocd"

        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        check_success "kubectl apply ArgoCD install.yaml"

        kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
        check_success "kubectl patch svc argocd-server LoadBalancer"

        kubectl patch svc argocd-server -n argocd --type='merge' -p '{"spec": {"type": "LoadBalancer", "ports": [{"name": "http", "nodePort": 30114, "port": 8080, "protocol": "TCP" ,"targetPort": 8080}]}}'
        check_success "kubectl patch svc argocd-server ports"

        echo "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
        check_success "kubectl wait for ArgoCD readiness"

    else
        echo "kubectl is not installed. Please install kubectl and try again."
        exit 1
    fi
}

# Function to apply ArgoCD application YAML file
apply_argocd_app() {
    echo "Applying ArgoCD application YAML file..."

    kubectl apply -n argocd -f ./deployment/legacy/argocd/app.yaml
    check_success "kubectl apply ArgoCD app.yaml"

    if command_exists argocd; then
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        check_success "kubectl get ArgoCD admin secret"

        argocd login 127.0.0.1:8080 --username admin --password ${PASSWORD} --insecure
        check_success "argocd login"
        sleep 10 # Give some time for ArgoCD login to establish
        argocd app get url-app --refresh
        check_success "argocd app get url-app"

    else
        echo "argocd CLI is not installed. Please install argocd and try again."
        exit 1
    fi
}

# Main function to orchestrate the script execution
main() {
    set_aws_credentials
    apply_terraform
    configure_aws_eks
    install_argocd
    apply_argocd_app

    echo "Run stop-legacy.sh to stop deployment"
}

# Execute the main function
main
