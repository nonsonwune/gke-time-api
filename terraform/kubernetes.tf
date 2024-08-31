resource "null_resource" "kubernetes_resources" {
  depends_on = [google_container_cluster.time_api_cluster, google_container_node_pool.time_api_nodes]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.time_api_cluster.name} \
        --zone ${google_container_cluster.time_api_cluster.location} \
        --project ${var.project_id}

      kubectl create namespace time-api

      kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: time-api
  namespace: time-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: time-api
  template:
    metadata:
      labels:
        app: time-api
    spec:
      containers:
      - name: time-api
        image: gcr.io/${var.project_id}/time-api:${var.image_tag}
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        readinessProbe:
          httpGet:
            path: /time
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /time
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: time-api
  namespace: time-api
spec:
  selector:
    app: time-api
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
EOF
    EOT
  }
}
