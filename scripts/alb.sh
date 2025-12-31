# To configure the current aws cluster
aws eks update-kubeconfig \
    --region us-east-1 \
    --name URL_Shortner_EKS_Cluster

# Setup OIDC Provider to our EKS Cluster
eksctl utils associate-iam-oidc-provider \
    --cluster URL_Shortner_EKS_Cluster \
    --approve \
    --region us-east-1

# To check OIDC URL
aws eks describe-cluster 
    --name URL_Shortner_EKS_Cluster \
    --query "cluster.identity.oidc.issuer" 
    --output text

# Download the ALB permission IAM Polciy document to use in the future
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

# Create an IAM policy using the policy downloaded in the previous step
# Run inside of the scripts folder (CRITICLE)
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create ALB Controller role
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://trust-policy.json

# Attach the policy to the role
aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::108772197183:policy/AWSLoadBalancerControllerIAMPolicy

# Create the Kubernetes service account
kubectl create serviceaccount aws-load-balancer-controller -n kube-system

# Annotate the service account
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::108772197183:role/AmazonEKSLoadBalancerControllerRole

# To check the service accounts
# Should annotate correctly like Annotations: eks.amazonaws.com/role-arn: arn:aws:iam::108772197183:role/AmazonEKSLoadBalancerControllerRole
kubectl get serviceaccounts -n kube-system
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# Install the EKS Charts
helm repo add eks https://aws.github.io/eks-charts

# Update repos
helm repo update eks

# Install aws-load-balancer-controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=URL_Shortner_EKS_Cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
  --set region=us-east-1 \
  --set vpcId=vpc-067877948c516afdc

# If you want to upgrade use this
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=URL_Shortner_EKS_Cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-067877948c516afdc

# Get load balancer controllers
kubectl get deployment -n kube-system aws-load-balancer-controller