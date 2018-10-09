#!/bin/bash

vm_name=$1
vm_count=$2
user=$3
password=$4
version=$5
count=1

for i in "${@:6}"
do
  printf -v num "%02d" $count
  sudo su -c "echo $i $vm_name-$num >> /etc/hosts"
  sudo automate-ctl install-runner $vm_name-$num $user --password $password --chefdk-version $version --yes
  count=$((count + 1))
done
