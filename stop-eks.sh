cd deployment/eks/terraform || exit 1
terraform destroy -auto-approve

# Return to the original directory
cd - >/dev/null || exit 1
