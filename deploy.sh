#!/bin/bash

# Step 1: Update the server and install necessary dependencies
echo "Updating package list..."
sudo apt-get update
#1
echo "Installing necessary dependencies..."
sudo apt-get install -y ca-certificates curl || { echo "Failed to install dependencies. Exiting."; exit 1; }

# Step 2: Add Docker's official GPG key
echo "Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || { echo "Failed to add GPG key. Exiting."; exit 1; }
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 3: Add Docker repository to Apt sources
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Failed to add Docker repository. Exiting."; exit 1; }

# Step 4: Update package index again
echo "Updating package index..."
sudo apt-get update || { echo "Failed to update package index. Exiting."; exit 1; }

# Step 5: Install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Failed to install Docker. Exiting."; exit 1; }

# Step 6: Navigate to the backend app folder
echo "Navigating to the backend app folder..."
cd ~/app/src/NetflixMovieCatalog || { echo "Failed to navigate to the app folder. Exiting."; exit 1; }

# Step 7: Stop and remove existing containers (if any)
echo "Stopping and removing existing Docker containers (if any)..."
docker-compose down || true

# Step 8: Generate a self-signed certificate for HTTPS if not already created
if [ ! -f cert.pem ] || [ ! -f key.pem ]; then
  echo "Generating self-signed certificate..."
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost" || { echo "Failed to generate certificate. Exiting."; exit 1; }
fi

# Step 9: Modify the Python file to include SSL context for HTTPS
echo "Modifying app.py for HTTPS..."
if ! sed -i "s|app.run(port=8080, host='0.0.0.0')|app.run(port=8080, host='0.0.0.0', ssl_context=('cert.pem', 'key.pem'))|" app.py; then
  echo "Failed to modify app.py. Exiting."
  exit 1
fi

# Step 10: Pull the latest Docker image from the registry (if using a registry)
# Example (uncomment if using a registry):
# docker pull <your-docker-registry>/netflix-backend:latest

# Step 11: Build and start the new backend container
echo "Building and starting the backend container..."
if ! docker-compose up --build -d; then
  echo "Failed to start Docker containers. Exiting."
  exit 1
fi

# Step 12: Cleanup unused images to free up space
echo "Cleaning up unused Docker images..."
docker system prune -f || true

echo "Backend service with HTTPS configured successfully!"
