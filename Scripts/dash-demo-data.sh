#!/bin/bash
############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 05/11/2024                                        #
############################################################
# sudo chmod +x dash-demo-data.sh
# sudo ./dash-demo-data.sh
# kubectl delete namespace dash-demo-data
# kubectl get all -n dash-demo-data

# Number of services and other resources to create for the demo
COUNT=20

# Namespace for demo resources
NAMESPACE="dash-demo-data"

# Create a namespace for the demo
kubectl create namespace $NAMESPACE

# Loop to create multiple mini-services, deployments, and ingresses
for i in $(seq 1 $COUNT); do
    # Create a deployment
    kubectl create deployment demo-deployment-$i --image=nginx --replicas=1 -n $NAMESPACE

    # Create a service for each deployment
    kubectl expose deployment demo-deployment-$i --type=ClusterIP --port=80 -n $NAMESPACE

    # Create a job
    kubectl create job demo-job-$i --image=busybox -- /bin/sh -c "echo Hello from job $i; sleep 10" -n $NAMESPACE

    # Optional: Create an Ingress
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress-$i
  namespace: $NAMESPACE
spec:
  rules:
  - host: "demo$i.local"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-deployment-$i
            port:
              number: 80
EOF

done

echo "Demo resources created. $COUNT deployments, services, jobs, and ingresses are running in the $NAMESPACE namespace."