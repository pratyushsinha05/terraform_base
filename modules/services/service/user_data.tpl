#!/bin/bash
yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user

docker pull ${docker_image_url}
docker run -d --name ${service_name} -p ${app_port}:${app_port} ${docker_image_url}
