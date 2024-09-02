# Time API GKE Project

This project deploys a simple Time API to Google Kubernetes Engine (GKE) using Terraform and GitHub Actions for CI/CD.

## Local Setup and Testing

### Prerequisites
- Google Cloud SDK
- Terraform
- kubectl
- Docker

### Steps to Run Locally

1. Clone the repository:
   ```
   git clone https://github.com/your-username/gke-time-api.git
   cd gke-time-api
   ```

2. Set up Google Cloud credentials:
   ```
   gcloud auth application-default login
   ```

3. Initialize Terraform:
   ```
   cd terraform
   terraform init
   ```

4. Plan and apply the Terraform configuration:
   ```
   terraform plan
   terraform apply
   ```

5. Configure kubectl to use the new cluster:
   ```
   gcloud container clusters get-credentials time-api-gke-cluster --zone us-central1-a --project your-project-id
   ```

6. Test the API:
   ```
   kubectl get services -n time-api
   curl http://EXTERNAL_IP/time
   ```

### Running Tests

To run the unit tests for the API:

```
python -m unittest test_app.py
```

## CI/CD Pipeline

The project uses GitHub Actions for CI/CD. On each push to the main branch, the pipeline:
1. Builds the Docker image
2. Pushes it to Google Container Registry
3. Updates the Terraform configuration
4. Applies the Terraform changes
5. Tests the deployed API

## Monitoring

Basic monitoring and alerting are set up using Google Cloud Monitoring. An alert will be triggered if the API latency exceeds 1 second.

## Security Policies

A Terraform policy is in place to prevent accidental destruction of the GKE cluster.

