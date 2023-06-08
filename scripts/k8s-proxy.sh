#!/bin/bash

# Set the output file path
output_file="container_images.csv"

# Output header
echo "Project,Cluster,Namespace,Pod,Image" > "$output_file"

# Get a list of all GCP projects
projects=$(gcloud projects list --format="value(projectId)")

# Assuming your CSV file is named 'projects.csv' and is in the same directory
csv_file="projects.csv"

# Loop through each project
for project in $projects; do
  echo "Processing project: $project"
 
  # Get the corresponding proxy for the project from the CSV file
  proxy=$(awk -F "," -v project="$project" '$1 == project {print $3}' "$csv_file")

  # Setting the http proxy
  export https_proxy=$proxy

  # Get a list of all GKE clusters in the project
  clusters=$(gcloud container clusters list --project=$project --format="value(name)")

  # Loop through each cluster
  for cluster in $clusters; do
    echo "Connecting to cluster: $cluster"

    # Get the credentials for the cluster
    gcloud container clusters get-credentials "$cluster" --project=$project

    # Get the list of all pods in all namespaces
    pods=$(kubectl get pods --all-namespaces --output=jsonpath="{range .items[*]}{.metadata.namespace},{.metadata.name}{'\n'}{end}")

    # Loop through each pod
    while IFS=',' read -r namespace pod; do
      # Get the list of containers in the pod
      containers=$(kubectl get pod "$pod" --namespace="$namespace" --output=jsonpath="{range .spec.containers[*]}{.name}{'\n'}{end}")

      # Loop through each container
      while read -r container; do
        # Get the image used by the container
        image=$(kubectl get pod "$pod" --namespace="$namespace" --output=jsonpath="{.spec.containers[?(@.name==\"$container\")].image}")

        # Output the project, cluster, namespace, pod, and image in CSV format
        echo "$project,$cluster,$namespace,$pod,$image" >> "$output_file"
      done <<< "$containers"
    done <<< "$pods"

    echo "Finished collecting images for cluster: $cluster"
    echo ""
  done

  # Unset the proxy settings after each iteration
  unset https_proxy

  echo "Finished processing project: $project"
  echo ""
done