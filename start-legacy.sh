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

# Function to start Minikube
start_minikube() {
    echo "Starting Minikube..."
    if command_exists minikube; then
        minikube start
        check_success "minikube start"

        minikube addons enable ingress
        check_success "minikube addons enable ingress"

        # Check for sudo privileges or prompt for password
        if ! sudo -v; then
            echo "Waiting for user to enter password for sudo..."
            sudo -v
            check_success "sudo password entry"
        fi

        # Run minikube tunnel and wait for user to enter password if required
        nohup minikube tunnel > /dev/null 2>&1 &
        sleep 10 # Give some time for the tunnel to establish

        if ps aux | grep -v grep | grep "minikube tunnel" > /dev/null; then
            echo "minikube tunnel succeeded"
        else
            echo "Error: minikube tunnel failed"
            exit 1
        fi

    else
        echo "Minikube is not installed. Please install Minikube and try again."
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
    start_minikube
    install_argocd
    apply_argocd_app

    echo "Run stop-legacy.sh to stop deployment"
}

# Execute the main function
main
