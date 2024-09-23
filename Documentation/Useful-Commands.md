![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Useful Commands🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [📝Commands](#📝Commands)
3. [🔗Links](#🔗links)

---

## 📝Commands

- Gcloud
```bash
gcloud init # Initialize gcloud

sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin # Install gcloud package for kubernetes

gcloud services enable container.googleapis.com # Enable the container.googleapis.com service
gcloud services enable compute.googleapis.com # Enable the compute.googleapis.com service

gcloud container clusters create $cluster_name --region=$zone --min-nodes=$min_nodes --max-nodes=$max_nodes --enable-ip-alias --machine-type=n1-standard-4 --disk-size=20GB --enable-autoscaling # Create a cluster

gcloud container clusters get-credentials $cluster_name --region=$zone # Get the credentials of a cluster

gcloud container clusters delete $cluster_name --region=$zone -q # Delete a cluster

gcloud compute disks list --filter="zone:$zone" --format="value(NAME)" | xargs -I {} gcloud compute disks delete {} --zone=$zone --quiet # Delete all disks in a zone
```

- kubernetes
```bash
kubectl top nodes # Get the usage of all nodes

kubectl top pods --all-namespaces # Get the usage of all pods

kubectl get all # Get all resources

kubectl get nodes # Get all nodes

kubectl get pods # Get all pods

kubectl get deployments # Get all deployments

kubectl get services # Get all services

kubectl get pvc # Get all persistent volume claims

kubectl get pv # Get all persistent volumes

kubectl apply -f https://github.com/EliasDeHondt/IntegrationProject2/blob/main/Scripts/apllication.yaml # Apply a yaml file

kubectl delete -f https://github.com/EliasDeHondt/IntegrationProject2/blob/main/Scripts/apllication.yaml # Delete a yaml file

kubectl delete pvc <pvc-name> # Delete a persistent volume claim

kubectl logs <pod-name> # Get the logs of a pod

kubectl cp /home/elias/disney_bitconnect.mp4 default/jellyfin-79747bf6c7-wx7nj:/media/disney_bitconnect.mp4 # Copy a file to a pod in a container
```

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com