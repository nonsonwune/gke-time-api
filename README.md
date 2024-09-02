# Time API GKE Project

This project deploys a simple Time API to Google Kubernetes Engine (GKE) using Terraform for Infrastructure as Code (IaC) and GitHub Actions for Continuous Deployment (CD).

## Project Overview

The API returns the current time and an email address when accessed via a GET request. It is containerized using Docker and deployed to a GKE cluster. The entire infrastructure is managed using Terraform, and a CI/CD pipeline is implemented using GitHub Actions.

## Infrastructure Components

- Google Kubernetes Engine (GKE) cluster
- VPC networking and subnets
- NAT gateway for managing egress traffic
- Firewall rules for secure communication
- Kubernetes resources (Namespaces, Deployments, Services)

## Local Setup and Testing

### Prerequisites
- Google Cloud SDK
- Terraform
- kubectl
- Docker
- Python 3.7+

### Detailed Steps to Run Locally

1. Clone the repository:
   ```
   git clone https://github.com/nonsonwune/gke-time-api.git
   cd gke-time-api
   ```

2. Set up Google Cloud credentials:
   ```
   gcloud auth application-default login
   ```

3. Set your GCP project ID:
   ```
   export PROJECT_ID=time-api-gke-project-434215
   gcloud config set project $PROJECT_ID
   ```

4. Enable necessary GCP APIs:
   ```
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable cloudresourcemanager.googleapis.com
   gcloud services enable monitoring.googleapis.com
   ```

5. Initialize Terraform:
   ```
   cd terraform
   terraform init
   ```

6. Plan and apply the Terraform configuration:
   ```
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

7. Configure kubectl to use the new cluster:
   ```
   gcloud container clusters get-credentials time-api-gke-cluster --zone us-central1-a --project $PROJECT_ID
   ```

8. Verify the deployment:
   ```
   kubectl get pods -n time-api
   kubectl get services -n time-api
   ```

9. Test the API:
   ```
   curl http://34.69.20.46/time
   ```

### Running Tests

To run the unit tests for the API:

1. Install the required packages:
   ```
   pip install flask requests
   ```

2. Run the tests:
   ```
   python -m unittest test_app.py
   ```

## CI/CD Pipeline

The project uses GitHub Actions for CI/CD. On each push to the main branch, the pipeline:
1. Builds the Docker image
2. Pushes it to Google Container Registry
3. Updates the Terraform configuration
4. Applies the Terraform changes
5. Verifies that the API is accessible by running a test

The latest successful GitHub Actions workflow run can be found at:
[https://github.com/nonsonwune/gke-time-api/actions/runs/10665784024](https://github.com/nonsonwune/gke-time-api/actions/runs/10665784024)

## Monitoring and Alerting

Basic monitoring and alerting are set up using Google Cloud Monitoring. An alert will be triggered if the CPU utilization of the GKE nodes exceeds 80% for 5 minutes.

## Security Policies

- Terraform policies are in place to prevent accidental destruction of the GKE cluster.
- A NAT gateway is set up to manage outbound traffic from the GKE cluster.
- Firewall rules are implemented to secure the infrastructure.

## Accessing the Deployed API

The API can be accessed at: `http://34.69.20.46/time`

This will return the current time and an email address in JSON format.

## Known Limitations and Future Improvements

- The current monitoring setup is basic and could be expanded to cover more metrics.
- Secret management could be improved by using a dedicated secret management solution.
- The API could be extended to provide more functionality.

## Scaling the Application

To scale the application:

1. Adjust the number of replicas in the Kubernetes deployment:
   ```
   kubectl scale deployment time-api -n time-api --replicas=3
   ```

2. To scale the GKE cluster, modify the `gke_num_nodes` variable in `terraform/terraform.tfvars` and reapply the Terraform configuration.

