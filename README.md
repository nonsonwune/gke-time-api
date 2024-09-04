# Time API GKE Project

## Project Overview

This project deploys a simple Time API to Google Kubernetes Engine (GKE) using Terraform for Infrastructure as Code (IaC) and GitHub Actions for Continuous Integration and Deployment (CI/CD). The API returns the current time when accessed via a GET request.

## Infrastructure Components

- Google Kubernetes Engine (GKE) cluster
- VPC networking and subnets
- NAT gateway for managing egress traffic
- Firewall rules for secure communication
- Kubernetes resources (Namespaces, Deployments, Services, ConfigMaps, and Ingress)

## API Functionality

The API provides the following information when accessed:

- Current time (in Africa/Lagos timezone)
- Email address
- Timezone

## Prerequisites

- Google Cloud SDK
- Terraform
- kubectl
- Docker
- Python 3.9+

## Local Setup and Testing

1. Clone the repository:

   ```
   git clone https://github.com/your-username/time-api-gke-project.git
   cd time-api-gke-project
   ```

2. Set up Google Cloud credentials:

   ```
   gcloud auth application-default login
   ```

3. Set your GCP project ID:

   ```
   export PROJECT_ID=your-project-id
   gcloud config set project $PROJECT_ID
   ```

4. Enable necessary GCP APIs:

   ```
   gcloud services enable compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com monitoring.googleapis.com
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
   curl http://EXTERNAL_IP/time
   ```
   Replace EXTERNAL_IP with the LoadBalancer's external IP address.

## Running Tests

To run the unit tests for the API:

1. Install the required packages:

   ```
   pip install -r requirements.txt
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
5. Updates the Kubernetes manifest with the correct PROJECT_ID and IMAGE_TAG
6. Deploys the updated Kubernetes resources
7. Verifies that the API is accessible by running a test with retries

## Monitoring and Alerting

Basic monitoring and alerting are set up using Google Cloud Monitoring. An alert will be triggered if the CPU utilization of the GKE nodes exceeds 80% for 5 minutes.

## Security Measures

- Terraform policies prevent accidental destruction of the GKE cluster.
- A NAT gateway manages outbound traffic from the GKE cluster.
- Firewall rules secure the infrastructure.
- Network policies control traffic within the cluster.
- Workload Identity is used for secure authentication between GKE and GCP services.

## Accessing the Deployed API

The API can be accessed at: `http://EXTERNAL_IP/time`

Replace EXTERNAL_IP with the LoadBalancer's external IP address, which can be obtained using:

```
kubectl get service time-api -n time-api
```

## Scaling the Application

To scale the application:

1. Adjust the number of replicas in the Kubernetes deployment:

   ```
   kubectl scale deployment time-api -n time-api --replicas=3
   ```

2. The GKE cluster now uses node auto-provisioning with a maximum of 5 nodes. It will automatically scale based on resource demands.

## Resource Management

- CPU requests have been set to 50m and limits to 100m.
- Memory requests are set to 64Mi and limits to 128Mi.
- These settings ensure efficient resource utilization and prevent resource starvation.

## Improvements Made

1. Implemented Workload Identity for secure authentication.
2. Adjusted resource requests and limits for better performance and efficiency.
3. Enabled node auto-provisioning for automatic scaling.
4. Enhanced the CI/CD pipeline with better error handling and verification steps.
5. Improved the Kubernetes manifest with proper variable substitution.

## Future Improvements

- Implement HTTPS for secure communication
- Enhance monitoring and logging capabilities
- Implement more comprehensive security measures
- Optimize for high availability and disaster recovery
- Implement a staging environment for testing before production deployment

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
