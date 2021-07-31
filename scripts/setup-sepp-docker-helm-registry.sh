#!/bin/bash

echo -e "\e[38;5;126m ########################################################\e[0m"
echo -e "\e[38;5;126m     START SETUP SEPP DOCKER AND HELM REGISTRY SCRIPT    \e[0m"
echo -e "\e[38;5;126m ########################################################\e[0m"

##################################################################################################################

source ./config/configuration.env

##################################################################################################################

# Ask user for verification of his/her inputs
echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 1. Confirm all required user-inputs.... "
echo
echo "Please verify all the inputs in the below table and confirm (Y/N):"

printf "  \x1b[7m%-77s\e[0m\n"  "+===============================================================================+"
printf "  \x1b[7m%-77s\e[0m\n" "| INPUT NAME                           | INPUT VALUE                            |"
printf "  \x1b[7m%-77s\e[0m\n"  "+===============================================================================+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Openstack Password                   | $OPENSTACK_PASSWORD"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| SSH Password                         | $SSHPASS"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Docker Registry VM Name              | $DOCKER_REGISTRY_VM_NAME"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Docker Registry VM Flavor            | $DOCKER_REGISTRY_FLAVOR"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Docker Registry VM Image             | $DOCKER_REGISTRY_IMAGE"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Docker Registry VM Network Name      | $DOCKER_REGISTRY_NETWORK_NAME"
printf "  \x1b[7m%-77s\e[0m\n" "+-------------------------------------------------------------------------------+"
printf "  \x1b[7m%-77s%-3s|\e[0m\n"  "| Docker Registry Key Pair Name        | $DOCKER_REGISTRY_KEY_PAIR_NAME"
printf "  \x1b[7m%-77s\e[0m\n"  "+===============================================================================+"
echo

read -p "  I confirm that the above table has all the right values that I desire for my setup: " USER_CONFIRMATION

if [[ -z $USER_CONFIRMATION || "$USER_CONFIRMATION" == "Y" || "$USER_CONFIRMATION" == "YES" || "$USER_CONFIRMATION" == "y" || "$USER_CONFIRMATION" == "yes" ]]; then
        echo -e "\e[38;5;40m  User confirmation RECEIVED.\e[0m"
else
        echo -e "\e[38;5;196m  User confirmation DENIED!!! Terminating script....\e[0m"
        echo
        exit -1
fi

echo
echo "Step 1. Confirm all required user-inputs.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 2. Install all required software on local VM.... "

    # Install low-level softwares
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"
    echo "Installing low-level softwares like unzip, epel-release, python-pip, python3-pip, sshpass, etc.... "
    sudo yum -y install wget vim
    sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm
    sudo yum -y groupinstall 'Development Tools'
    sudo yum -y install openssl-devel libffi libffi-devel python-pip python3-pip
    sudo yum --enablerepo=epel -y install sshpass
    echo "Installing low-level softwares like unzip, python-pip, python3-pip, sshpass, etc.... Done!!!"
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"


    # Install Terraform
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"
    echo "Installing Terraform and Graphviz.... "
    wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
    sudo unzip terraform_0.11.10_linux_amd64.zip -d /usr/local/bin
    rm terraform_0.11.10_linux_amd64.zip

    # Add graph builder tool for Terraform
    sudo yum -y install graphviz
    echo "Installing Terraform and Graphviz.... Done!!!"
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"


    # Install OpenStack Client
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"
    echo "Installing Openstack Client.... "
    sudo yum -y install https://rdoproject.org/repos/rdo-release.rpm
    sudo yum -y install python-openstackclient
    echo "Installing Openstack Client.... Done!!!"
    echo -e "\e[38;5;20m#########################################################################################################\e[0m"

    # Clean up cached packages
    sudo yum clean all
    sudo rm -rf /var/cache/yum

    # update Locale error message
    export PATH=$PATH:/usr/local/bin/    
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"

echo
echo "Step 2. Install all required software on local VM.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

# Setup Terraform files and Openstack Configuration
echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 3. Setup Terraform files and Openstack Configuration on local VM.... "
echo
sudo mkdir -p /etc/terraform/
sudo chmod 777 /etc/terraform/

sudo cp terraform/*.tf /etc/terraform/
sudo cp config/*openrc.sh /etc/terraform/
source /etc/terraform/*openrc.sh << EOF
${OPENSTACK_PASSWORD}
EOF

find /etc/terraform -type f -exec sed -i -e 's/<DOCKER_REGISTRY_VM_NAME>/'${DOCKER_REGISTRY_VM_NAME}'/g' {} \;
find /etc/terraform -type f -exec sed -i -e 's/<DOCKER_REGISTRY_FLAVOR>/'${DOCKER_REGISTRY_FLAVOR}'/g' {} \;
find /etc/terraform -type f -exec sed -i -e 's/<DOCKER_REGISTRY_IMAGE>/'${DOCKER_REGISTRY_IMAGE}'/g' {} \;
find /etc/terraform -type f -exec sed -i -e 's/<DOCKER_REGISTRY_NETWORK_NAME>/'${DOCKER_REGISTRY_NETWORK_NAME}'/g' {} \;
find /etc/terraform -type f -exec sed -i -e 's/<DOCKER_REGISTRY_KEY_PAIR_NAME>/'${DOCKER_REGISTRY_KEY_PAIR_NAME}'/g' {} \;
find /etc/terraform -type f -exec sed -i -e 's/<SSHPASS>/'${SSHPASS}'/g' {} \;


echo
echo "Step 3. Setup Terraform files and Openstack Configuration on local VM.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

# Run Terraform commands under /etc/terraform to provision Openstack resources
echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 4. Run Terraform commands under /etc/terraform to provision Openstack resources.... "
echo
cd /etc/terraform

terraform init -verify-plugins=false
if [ $? -ne 0 ]; then
    echo -e "\e[38;5;196m Terraform init in /etc/terraform directory FAILED.\e[0m"
    echo -e "\e[38;5;196m Step 4. Run Terraform commands under /etc/terraform to provision Openstack resources.... FAILED!!!\e[0m"
    echo
    echo -e "\e[38;5;20m####################### END: setup-sepp-docker-helm-registry.sh #############################\e[0m"
    exit -1
fi

terraform apply << EOF
yes
EOF
if [ $? -ne 0 ]; then
    echo -e "\e[38;5;196m Terraform apply in /etc/terraform directory FAILED.\e[0m"
    echo -e "\e[38;5;196m Step 4. Run Terraform commands under /etc/terraform to provision Openstack resources.... FAILED!!!\e[0m"
    echo
    echo -e "\e[38;5;20m####################### END: setup-sepp-docker-helm-registry.sh #############################\e[0m"
    exit -1
fi

# Sleep 60 seconds to give the VM network enough time to come up.
echo
echo -e "\e[5;38;5;11m\e[48;5;0mWait 60 seconds for the Docker Registry VM network to come up....\e[0m"
echo
sleep 60

# Go back to original directory
cd -

echo
echo -e "\e[38;5;196m @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\e[0m"
echo -e "\e[38;5;196m @                             IMPORTANT MESSAGE                                    @\e[0m"
echo -e "\e[38;5;196m @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\e[0m"
echo -e "\e[38;5;196m |Go to your Openstack GUI Console and verify if your Docker Registry VM has been created.|\e[0m"
echo -e "\e[38;5;196m |Also, verify that you are able to SSH into the Docker Registry VM using the private key.|\e[0m"
echo -e "\e[38;5;196m |Contact your Infra Admin for the private key file to access your Docker Registry VM.    |\e[0m"
echo -e "\e[38;5;196m @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\e[0m"
echo
echo "Step 4. Run Terraform commands under /etc/terraform to provision Openstack resources.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 5. Configure Docker Registry Host...."
echo

DOCKER_REGISTRY_VM_IP=$(nova list | grep "${DOCKER_REGISTRY_VM_NAME}" | cut -d'=' -f2 | cut -d' ' -f1)

sshpass -p ${SSHPASS} scp -o StrictHostKeyChecking=no config/configuration.env                     cloud-user@${DOCKER_REGISTRY_VM_IP}:~/
sshpass -p ${SSHPASS} scp -o StrictHostKeyChecking=no scripts/configure-varun-docker-registry.sh    cloud-user@${DOCKER_REGISTRY_VM_IP}:~/

sshpass -p ${SSHPASS} ssh -o StrictHostKeyChecking=no cloud-user@${DOCKER_REGISTRY_VM_IP} "~/configure-varun-docker-registry.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[38;5;196m configure-varun-docker-registry.sh script FAILED.\e[0m"
    echo -e "\e[38;5;196m Step 5. Configure Docker Registry Host.... FAILED!!!\e[0m"
    echo
    echo -e "\e[38;5;20m####################### END: setup-sepp-docker-helm-registry.sh #############################\e[0m"
    exit -1
else
    echo "Configured Docker and Helm Registry successfully!"
    echo -e "\e[5;38;5;40m\e[48;5;0mYou can directly access your Docker Registry VM with USERNAME(cloud-user) and PASSWORD(${SSHPASS}).\e[0m" 
fi

echo
echo "Step 5. Configure Docker Registry Host.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

echo
echo -e "\e[38;5;20m#########################################################################################################\e[0m"
echo "Step 6. List of all the instances created.... "
echo

nova list | grep "${DOCKER_REGISTRY_VM_NAME}"

echo
echo "Step 6. List of all the instances created.... Done!!!"
echo -e "\e[38;5;20m#########################################################################################################\e[0m"


##################################################################################################################

echo
echo -e "\e[38;5;126m ########################################################\e[0m"
echo -e "\e[38;5;126m      END SETUP SEPP DOCKER AND HELM REGISTRY SCRIPT     \e[0m"
echo -e "\e[38;5;126m ########################################################\e[0m"


