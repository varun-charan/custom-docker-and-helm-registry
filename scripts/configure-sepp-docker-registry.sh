#!/bin/bash

echo -e "\e[38;5;126m ############################################################\e[0m"
echo -e "\e[38;5;126m     START CONFIGURE SEPP DOCKER AND HELM REGISTRY SCRIPT    \e[0m"
echo -e "\e[38;5;126m ############################################################\e[0m"

##################################################################################################################

# Source the configuration file
source ~/configuration.env

##################################################################################################################

echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 2. Install all required software on local VM.... "

    echo -e "\e[38;5;20m#########################################################################################################\e[0m"
    echo "Installing docker-engine"
    sudo yum -y install docker-engine
    sudo systemctl start docker.service
    sudo systemctl enable docker.service
    echo "Installing docker-engine.... Done!!!"
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"


    # Configure Registry
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"
    echo "Configure Registry.... "
    sudo mkdir -p /var/lib/registry/conf.d
    sudo cd /var/lib/registry/conf.d

sudo bash -c 'cat > /etc/ssl/openssl.cnf << EOF
[req]
req_extensions = SAN
distinguished_name = req_distinguished_name
 
[req_distinguished_name]
 
[SAN]
subjectAltName=DNS:${DOCKER_REGISTRY_VM_NAME}
EOF'

sudo bash -c 'source /home/cloud-user/configuration.env; cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://www-some-proxy.com:80" "HTTPS_PROXY=http://www-some-proxy.com:80" "NO_PROXY=localhost,127.0.0.1,${DOCKER_REGISTRY_VM_NAME}"
EOF'
sudo bash -c 'chmod 0444 /etc/systemd/system/docker.service.d/http-proxy.conf'
  
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /var/lib/registry/conf.d/${DOCKER_REGISTRY_VM_NAME}.key -x509 -days 365 -subj "/C=US/ST=WA/L=Seattle/O=Oracle/OU=CGBU/CN=${DOCKER_REGISTRY_VM_NAME}" -reqexts SAN -config /etc/ssl/openssl.cnf -out /var/lib/registry/conf.d/${DOCKER_REGISTRY_VM_NAME}.crt

    sudo chmod 600 /var/lib/registry/conf.d/${DOCKER_REGISTRY_VM_NAME}.key
    sudo mkdir -p /etc/docker/certs.d/${DOCKER_REGISTRY_VM_NAME}:5000
    sudo cp /var/lib/registry/conf.d/${DOCKER_REGISTRY_VM_NAME}.crt /etc/docker/certs.d/${DOCKER_REGISTRY_VM_NAME}:5000/ca.crt
    sudo docker container prune -f
    sudo docker run -d -p 5000:5000 --name registry --restart=always \
         -v /var/lib/registry:/registry_data:Z \
         -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registry_data \
         -e REGISTRY_HTTP_TLS_KEY=/registry_data/conf.d/${DOCKER_REGISTRY_VM_NAME}.key \
         -e REGISTRY_HTTP_TLS_CERTIFICATE=/registry_data/conf.d/${DOCKER_REGISTRY_VM_NAME}.crt \
         -e REGISTRY_STORAGE_DELETE_ENABLED=true \
         registry:2
    if [ $? -ne 0 ]; then
        echo "Docker Registry container FAILED!!! Terminating script...."
        exit -1
    fi

    sudo mkdir -p /var/opt/charts /var/charts
    sudo docker run -d --restart always -p 8081:8081 \
         -e PORT=8081 \
         -e DEBUG=1 \
         -e STORAGE="local" \
         -e STORAGE_LOCAL_ROOTDIR="/var/opt/charts" \
         -e DEPTH=0 -v /var/charts:/var/opt/charts:Z \
         chartmuseum/chartmuseum:latest
    if [ $? -ne 0 ]; then
        echo "Helm Registry container FAILED!!! Terminating script...."
        exit -1
    fi

    sudo docker ps

    echo "Configuring Registry.... Done!!!"
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"

echo
echo "Step 2. Install all required software on local VM.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

echo
echo -e "\e[38;5;126m ############################################################\e[0m"
echo -e "\e[38;5;126m      END CONFIGURE SEPP DOCKER AND HELM REGISTRY SCRIPT     \e[0m"
echo -e "\e[38;5;126m ############################################################\e[0m"


