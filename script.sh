#!/bin/bash

# Function to check if a command exists
check_command() {
  command -v "$1" &> /dev/null
}

# Function to verify if NVM is properly loaded
verify_nvm() {
  if check_command nvm; then
    echo "NVM is loaded."
  else
    echo "NVM is not loaded. Trying to load manually..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if check_command nvm; then
      echo "NVM successfully loaded."
    else
      echo "Failed to load NVM. Exiting."
      exit 1
    fi
  fi
}

# Update package index and install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y git curl jq
sudo apt install -y nginx

# install aws-cli
snap install aws-cli --classic


#install all Dependieces
sleep 30

# Set up SSH directory
echo "Setting up SSH directory..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add GitHub to known hosts
echo "Adding GitHub to known hosts..."
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# Set up SSH key for Git
echo "Setting up SSH key for Git..."
echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Clone or update private git repository
echo "Cloning/updating private Git repository..."
git clone "${GITHUB_REPO}" /var/www/app || (cd /var/www/app && git pull)

# Retrieve .env file from AWS Secrets Manager
echo "Retrieving .env file from AWS Secrets Manager..."
aws configure set aws_access_key_id "${AWS_ACCESS_KEY}"
aws configure set aws_secret_access_key "${AWS_SECRET_KEY}"
aws configure set region "${AWS_REGION}"

aws secretsmanager get-secret-value --secret-id "${SECRET_NAME}" --query SecretString --output text | jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' > /var/www/app/.env

# Install NVM
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Ensure .bashrc exists for root user
if [ ! -f ~/.bashrc ]; then
    echo "Creating .bashrc..."
    touch ~/.bashrc
fi

# Add NVM and npm paths to .bashrc
echo "Adding NVM and npm paths to .bashrc..."
{
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
    echo 'export PATH="$PATH:$HOME/.npm-global/bin:$NVM_DIR/versions/node/$(nvm version)/bin"'
} >> ~/.bashrc

# Source the updated .bashrc
echo "Sourcing .bashrc..."
source ~/.bashrc

# Verify that NVM is loaded
verify_nvm

# Install Node.js
echo "Installing Node.js..."
nvm install "${NODE_VERSION}"

# Install Yarn and PM2
echo "Installing Yarn and PM2..."
npm install -g yarn pm2

# Install project dependencies
echo "Installing project dependencies..."
cd /var/www/app
yarn install

# Build project
echo "Building project..."
yarn build

# Stop and start PM2 for the project
pm2 stop "nestjs-app" || echo "PM2 service not running"
pm2 delete "nestjs-app" || echo "No PM2 process to delete"
pm2 start /var/www/app/dist/main.js --name "nestjs-app" -i 1 || { echo "PM2 start failed"; exit 1; }
pm2 save || { echo "PM2 save failed"; exit 1; }

# Set up Nginx configuration for the domain
echo "Setting up Nginx for domain: $DOMAIN_NAME..."

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site and reload Nginx
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Source .bashrc again to ensure paths are set
echo "Sourcing .bashrc again..."
source ~/.bashrc

# Check NVM and PM2 one more time to confirm they are working
verify_nvm
check_command pm2 && echo "PM2 is available." || { echo "PM2 is not available. Exiting."; exit 1; }

echo "Setup completed successfully!"