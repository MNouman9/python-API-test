# Python API Deployment on AWS ECS  

## Overview  
This repository contains a simple Python API that returns the current date and time upon receiving a request. The project involves:  
- Dockerizing the application  
- Deploying it on AWS ECS  
- Providing a local testing setup using Docker Compose  

## Assumptions  
- The task required deploying the API on AWS, but no specific instructions were provided. Therefore, ECS was chosen as the deployment platform.  
- A pre-existing VPC was assumed, and the default VPC was used for deploying the Load Balancer.  

## Deployment  

### **Local Deployment**  
A `docker-compose.yml` file is included to facilitate local testing. Run the following command to start the application locally:  
```sh
cd python-API
docker-compose up --build -d
```
You can test the application by running `http://localhost:8000/datetime`

### **AWS Deployment**  
The application is deployed on AWS using Terraform. The infrastructure provisioning includes:  
- ECS cluster for running the containerized application  
- Load Balancer for external access  
- Required networking configurations  

## Potential Improvements  
While the current Terraform implementation is functional, it can be enhanced by:  
- Adopting a modular approach for better code organization  
- Utilizing variable files (`tfvars`) for improved configuration management
