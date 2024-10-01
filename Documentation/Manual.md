![logo](https://eliasdh.com/assets/media/images/logo-github.png)

# 💙🤍Manual🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [📚Explanation](#📚explanation)
4. [✨Steps](#✨steps)
   1. [👉Step 0: Preparations](#👉step-0-preparations)
   2. [👉Step 1: Set Up The Google Cloud Environment](#👉step-1-set-up-the-google-cloud-environment)
   3. [👉Step 2: Clone The GitHub Repository](#👉step-2-clone-the-github-repository)
   4. [👉Step 3: Run The Script](#👉step-3-run-the-script)
5. [📚Reference](#📚reference)
6. [📦Extra](#📦extra)
   1. [📦Extra: Troubleshooting](#📦extra-troubleshooting)
7. [🔗Links](#🔗links)

---

## 🖖Introduction

Deze handleiding biedt een diepgaande gids voor het implementeren van een **Kubernetes-georkestreerd cluster** in **Google Cloud Platform (GCP)**, specifiek gericht op het hosten van een **Jellyfin-streamingplatform**. Jellyfin fungeert als een open-source mediaserver, terwijl **MySQL** wordt ingezet als relationele database voor datamanagement en persistentie. Het gebruik van Kubernetes zorgt voor een geautomatiseerde schaalbaarheid, failover-mechanismen, en beheer van de lifecycle van de applicaties.

Het primaire doel van deze handleiding is om gebruik te maken van **Infrastructure-as-Code (IaC)** om de implementatie te optimaliseren en te automatiseren. Door een scriptgedreven aanpak kunnen DevOps-professionals fouttolerante en herhaalbare infrastructuren opzetten, wat resulteert in lagere onderhoudskosten en verbeterde betrouwbaarheid.

Gedurende deze handleiding zul je onder andere ontdekken hoe je de Google Cloud-omgeving configureert, een volledig functionerend Kubernetes-cluster initieert, en zowel Jellyfin als MySQL via containerisatie in deze omgeving draait. We zullen dieper ingaan op de YAML-manifesten die Kubernetes-resources, zoals Deployments, StatefulSets, Persistent Volume Claims (PVC’s), en Services, definiëren. Verder wordt uitgelegd hoe de Horizontal Pod Autoscaler (HPA) ingezet kan worden om dynamisch te schalen op basis van de CPU-load. Zie [Application](/Scripts/application.yaml)

Door deze handleiding te volgen, ben je in staat om een schaalbaar en robuust video-streamingplatform te implementeren dat bestand is tegen verkeerspieken en ontworpen is voor hoge beschikbaarheid en beveiliging.

## 📚Explanation

**Project Description: Jellyfin Streaming Platform**

1. **_Introduction_**

   - Dit project richt zich op het opzetten van een streamingplatform voor video's, gebruikmakend van de open-source Jellyfin mediaserver. Het platform is geconfigureerd binnen een Kubernetes-cluster en maakt gebruik van een MySQL-database voor gegevensopslag en persistentie. De gekozen technologieën zorgen voor schaalbaarheid, hoge beschikbaarheid en beveiliging.

2. **_Technologieën_**

   - Jellyfin:

     - Open-source mediaserver voor het streamen van video's.
     - Jellyfin werkt via HTTP op poort 8096 en wordt toegankelijk gemaakt via een LoadBalancer-service op poorten 80 (HTTP) en 443 (HTTPS).

   - MySQL:

     - Relationale database die gebruikersgegevens en metadata beheert.
     - Geconfigureerd als een StatefulSet met ondersteuning voor master-slave replicatie.
     - MySQL communiceert met Jellyfin via interne Kubernetes-services op poort 3306.

   - Kubernetes:

     - Orkestreert de containers van Jellyfin en MySQL, beheert de schaalbaarheid en de levenscyclus van de applicaties.
     - Persistent Volume Claims (PVC's) worden gebruikt om dataopslag voor zowel Jellyfin- als MySQL-gegevens te garanderen.

   - Persistent Storage:

     - PVC's garanderen data-integriteit en persistentie voor zowel de configuratie- en mediagegevens van Jellyfin als de gegevensopslag van MySQL.

   - Horizontal Pod Autoscaler (HPA):
     - Automatiseert de schaalvergroting van de Jellyfin-deployment op basis van CPU-gebruik. Het minimum aantal replicas is 1 en het maximum 10.

3. **_Communicatie tussen Technologieën_**

   - Jellyfin ontvangt mediaverzoeken van gebruikers en slaat deze op in de MySQL-database.
   - MySQL is toegankelijk via een headless service, waardoor communicatie tussen pods zonder specifieke IP-adressen mogelijk is.
   - De applicaties communiceren binnen het Kubernetes-cluster, wat latentie vermindert en efficiëntie verhoogt.

4. **_Beveiliging_**

   - Databasewachtwoorden en configuratie-instellingen worden beheerd via omgevingsvariabelen om te voorkomen dat gevoelige informatie hardcoded in containers wordt opgeslagen.
   - Gebruikerscommunicatie met Jellyfin verloopt via HTTPS om gegevens tijdens overdracht te versleutelen.

5. **_Redundantie en Beschikbaarheid_**

   - StatefulSet-configuratie van MySQL biedt redundantie via master-slave replicatie om gegevensintegriteit te waarborgen.
   - Jellyfin's HPA en meerdere replicas waarborgen beschikbaarheid bij pieken in het verkeer.

6. **_Positieve Aspecten_**

   - Schaalbaarheid: Het systeem kan eenvoudig worden opgeschaald met toenemende gebruikersvraag.
   - Open Source: Gebruik van open-source technologieën minimaliseert licentiekosten en biedt flexibiliteit voor maatwerk.
   - Hoge Beschikbaarheid: Kubernetes en StatefulSets zorgen voor een betrouwbare en robuuste infrastructuur.

7. **_Negatieve Aspecten_**

   - Complexiteit: Beheer van Kubernetes vereist expertise en kan een hogere leercurve vergen.
   - Kosten: Schalen van applicaties kan afhankelijk van de cloudprovider resulteren in hogere kosten.

8. **_Conclusie_**
   - Dit project biedt een krachtige basis voor het opzetten van een schaalbaar, veilig video streaming platform met Jellyfin, MySQL en Kubernetes. Met goede monitoring en beheer kan deze architectuur voldoen aan zowel huidige als toekomstige gebruikersbehoeften.

## ✨Steps

### 👉Step 0: Preparations

- Install the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDH-com/Documentation/blob/main/Documentation/Instructions-GCloud-CLI.md)

### 👉Step 1: Set Up The Google Cloud Environment

- Type the following command to initialize the Google Cloud CLI
  ```bash
  gcloud init
  ```
- Press `1` to log in with your Google account.
- Select your Google account.
- The step for selecting a project is not required `CTRL+C` to skip.
- Type the following command to install the Google Cloud package for Kubernetes
  ```bash
  sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
  ```

### 👉Step 2: Clone The GitHub Repository

- Type the following command to clone the GitHub repository

  ```bash
  git clone https://github.com/EliasDeHondt/IntegrationProject2.git
  ```

- Change the directory to the repository
  ```bash
  cd IntegrationProject2/Scripts
  ```

### 👉Step 3: Run The Script

- Type the following command to run the script
  ```bash
  sudo chmod +x Deployment-Script.sh
  ./Deployment-Script.sh
  ```

## 📚Reference

- [Jellyfin](https://jellyfin.org/)
- [MySQL](https://www.mysql.com/)
- [Kubernetes](https://kubernetes.io/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Persistent Volume Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

## 📦Extra

### 📦Extra: Troubleshooting

- Gcloud

```bash
gcloud init # Initialize gcloud

sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin # Install gcloud package for kubernetes

gcloud services enable container.googleapis.com # Enable the container.googleapis.com service

gcloud services enable compute.googleapis.com # Enable the compute.googleapis.com service

gcloud container clusters create cluster-1 --region=us-central1-c --min-nodes=1 --max-nodes=5 --enable-ip-alias --machine-type=n1-standard-4 --disk-size=20GB --enable-autoscaling # Create a cluster

gcloud container clusters get-credentials cluster-1 --region=us-central1-c # Get the credentials of a cluster

gcloud container clusters delete cluster-1 --region=us-central1-c -q # Delete a cluster

gcloud compute disks list --filter="zone:us-central1-c" --format="value(NAME)" | xargs -I {} gcloud compute disks delete {} --zone=us-central1-c --quiet # Delete all disks in a zone
```

- kubernetes

```bash
kubectl top nodes # Get the usage of all nodes

kubectl top pods --all-namespaces # Get the usage of all pods

kubectl get all # Get all resources

kubectl get nodes # Get all nodes

kubectl get pods # Get all pods

kubectl get pods --all-namespaces # Get all pods in all namespaces

kubectl get pods --all-namespaces -o wide # Get all pods in all namespaces with more information

kubectl get deployments # Get all deployments

kubectl get services # Get all services

kubectl get pods -n jellyfin # Get all pods in a namespace

kubectl get services --all-namespaces -o wide # Get all services in all namespaces with more information

kubectl get pvc # Get all persistent volume claims

kubectl get pv # Get all persistent volumes

kubectl apply -f ./application.yaml # Apply a yaml file

kubectl delete -f ./application.yaml # Delete a yaml file

kubectl delete pvc <pvc-name> # Delete a persistent volume claim

kubectl logs <pod-name> # Get the logs of a pod

kubectl cp /home/elias/disney_bitconnect.mp4 default/jellyfin-79747bf6c7-wx7nj:/media/disney_bitconnect.mp4 # Copy a file to a pod in a container
```

### 📦Extra: Deploy and Access the Kubernetes Dashboard

- Refer to the following link for more information: [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

- Get GitHub Repository

```bash
git clone https://github.com/EliasDeHondt/kubernetes-dashboard.git
```

- Install Cert-Manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

- Deploy the Kubernetes Dashboard

```bash
kubectl apply -f ./kubernetes-dashboard/Scripts
# Please modify the necessary configuration files to switch to your domain name.
```

- Access the Kubernetes Dashboard

```bash
kubectl get services -o wide -n ingress-nginx
# Copy the external IP address and put it in your A of AAAA record for your domain name.
```

- Access the Kubernetes Dashboard Token

```bash
sudo chmod +x ./kubernetes-dashboard/Scripts/get-token.sh
sudo ./kubernetes-dashboard/Scripts/get-token.sh
# Copy the token
# Paste the token in the Kubernetes Dashboard
```

- Delete all configurations

```bash
# To delete the Kubernetes Dashboard
kubectl delete -f ./kubernetes-dashboard/Scripts
sudo rm -r ./kubernetes-dashboard
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

## 🔗Links

- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com
