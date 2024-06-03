#!/bin/bash

# Main function to orchestrate the script execution
main() {
    set_aws_credentials
    apply_terraform
    configure_aws_eks
    install_aws_load_balancer_controller
    install_argocd
    apply_argocd_app
    echo 
    echo "ArgoCD URL:" $ARGOCD_URL
    echo "ArgoCD Password:" $PASSWORD
    echo 
    echo "App URL:" $APP_URL
    echo 
    echo "Enjoy!"
    echo 
    echo "Run stop-eks.sh to stop deployment"
    echo 

}

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

    # Verify AWS credentials
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "$AWS_REGION"

    # Validate credentials
    aws sts get-caller-identity >/dev/null 2>&1
    check_success "AWS credentials validation"
}

# Function to initialize and apply Terraform configuration and EKS
apply_terraform() {
    echo "Initializing and applying Terraform configuration..."

    if command_exists terraform; then
        cd deployment/eks/terraform || exit 1
        terraform init
        check_success "terraform init"

        terraform apply -auto-approve
        check_success "terraform apply"

        ROLE_ARN=$(terraform show -json | jq '.values.root_module.resources[] | select(.address == "aws_iam_role.alb-ingress-controller-role") | .values.arn')
        check_success "Getting ROLE ARN"
        # Return to the original directory
        cd - >/dev/null || exit 1

    else
        echo "Terraform is not installed. Please install Terraform and try again."
        exit 1
    fi
}

# Function to configure AWS CLI and update the local kubeconfig
configure_aws_eks() {
    echo "Configuring AWS CLI and creating EKS cluster..."

    if command_exists aws; then
        aws eks update-kubeconfig --name url-app-cluster --region "$AWS_REGION"
        check_success "aws eks update-kubeconfig"
    else
        echo "AWS CLI is not installed. Please install AWS CLI and try again."
        exit 1
    fi
}

# Function to install AWS Load Balancer Controller using Helm
install_aws_load_balancer_controller() {
    echo "Installing AWS Load Balancer Controller using Helm..."

    if command_exists helm; then

        helm template deployment/eks/helm/alb --set alb.arn=$ROLE_ARN | kubectl apply -f -
        check_success "helm install aws-load-balancer-iamserviceaccount"

        helm repo add eks https://aws.github.io/eks-charts
        helm repo update
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            --set clusterName=url-app-cluster \
            --set serviceAccount.create=false \
            --set serviceAccount.name=alb-ingress-controller
        check_success "helm install aws-load-balancer-controller"

        sleep 30

    else
        echo "Helm is not installed. Please install Helm and try again."
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

        echo "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
        check_success "kubectl wait for ArgoCD readiness"
        ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
    else
        echo "kubectl is not installed. Please install kubectl and try again."
        exit 1
    fi
}

# Function to apply ArgoCD application YAML file
apply_argocd_app() {
    echo "Applying ArgoCD application YAML file..."

    kubectl apply -n argocd -f ./deployment/eks/argocd/app.yaml
    check_success "kubectl apply ArgoCD app.yaml"

    if command_exists argocd; then
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        check_success "kubectl get ArgoCD admin secret"
        sleep 10

        while argocd login ${ARGOCD_URL} --username admin --password ${PASSWORD} --insecure ; [ $? -ne 0 ];do
            sleep 10
        done
        
        check_success "argocd login"

        sleep 10 # Give some time for ArgoCD login to establish

        argocd app get url-app --refresh
        check_success "argocd app get url-app"

        while [ -z $APP_URL ]; do
            echo "Waiting for end point..."
            APP_URL=$(kubectl get ingress -n url-app -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
            [ -z "$APP_URL" ] && sleep 10
        done

        argocd app set url-app -p web.env.apiURL=http://$APP_URL/shorten
    else
        echo "argocd CLI is not installed. Please install argocd and try again."
        exit 1
    fi
}

# Execute the main function
main
