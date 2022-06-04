# github-action-runner-tf
Terraform to spin up a vm that will allow for running github actions

## Commands to run

* Setup: `terraform init`
* Plan: `terraform plan -var="project=[project-name]"`
* Apply: `terraform apply -var="project=[project-name]"`
* Output private key: `terraform output tls_private_key`

## Commands to run on the machine

### Follow Github Actions Self-Hosted Runner instructions

* On your repo: Settings -> Actions -> Runners -> New Self-Hosted Runner
* Run all commands listed

### Install docker engine

* curl -fsSL https://get.docker.com -o get-docker.sh
* sudo sh get-docker.sh
* sudo chmod 666 /var/run/docker.sock


### Install zip

* sudo apt-get -y install zip
