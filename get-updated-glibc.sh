#!/usr/bin/env bash

docker build --squash -t "brettdah/centos6-novsyscall:1.0.0" .

echo "Here come the builds :"
docker build --squash -t "brettdah/centos6-novsyscall:1.0.0" .

echo "building builder image to extract all rpms"
docker build --target centos-with-vsyscall -t "builder:1" .

echo "launching container :"
docker run --detach --name test1 -it builder:1

if [ ! -d "./files/rpms" ]
then
	mkdir -p ./files/rpms
fi

# Geting the ID of the container
container=docker ps | grep "test1" | awk '{print $1}'

# Copying the rpms into local folder
echo "getting the rpms"
docker cp ${container}:/rpms/x86_64/ ./files/rpms

docker rm ${container}
