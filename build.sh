#!/usr/bin/env bash

docker build -t sanoopsadique/iac:latest .
echo Do you want to pull the image to docker hub - y/n:?
read choice
if [ $choice == 'y' ]
    then
        docker push sanoopsadique/iac:latest
fi
    
    