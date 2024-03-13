#!/bin/bash

# DOCKER MIGRATOR
## Migrate your docker images from one server to another

################################
# Prerequisites
# Make sure you have docker installed
# have enough storage available
################################


usage="################################################################
Docker Image Migrator: Migrate your docker images from your local setup to a 
remote destination server
################################################################

dim [-h] [-u remote_username] [-s remote_address]
    where:
        -h  show this help text
        -u  remote username of destination server
        -s  remote ip address of destination server"



remote_address=$username@$ip_address

function is_docker_installed(){
    docker images > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    echo "True"
    else
        echo "False"
    fi
}

function generate_passwordless_communication(){
    if [[ -z $ip_address ]]; then
    echo "Please specify the remote IP address with the -s flag"
    elif [[ -z $username ]]; then
    echo "Please specify the remote username with the -u flag"
    else
    echo "Generating one-time password"
    ssh-copy-id $remote_address
    # echo $remote_address
    fi
}

function extract_docker_images_and_save_in_temp_folder(){
    for i in $(docker images --format "{{.Repository}}:{{.Tag}}")
    do 
        a=$(echo $i | tr "/" "_") && docker save -o /tmp/dimfiles_$a $i && docker rmi $i
        # a=$(echo $i | tr "/" "_") && touch /tmp/dimfiles_$a && echo "image_$i"
    done
}

function transfer_docker_images_and_load_on_remote_server(){
    image_path="/tmp/dimfiles_*"
    for i in $(ls $image_path)
    do
        scp $i $remote_address:/tmp/. && ssh $remote_address docker load -i $i && ssh $remote_address rm -rf $i && rm $i
        # scp $i $remote_address:/tmp/. && ssh $remote_address rm -rf $i && rm $i
    done
}

function start_migration(){
    local exec_status=$(is_docker_installed)
    if [[ $exec_status == "False" ]]; then
    echo -e "\n#####################\nPlease Install Docker on your machine to continue\ndocker images command doesn't work\n#####################"
    else
        echo "Starting Migration Now....."
        echo -e "\nDo you want to generate a one-time password?? Y/n"
        read answer
        if [[ $answer == "n" ]]; 
        then
            echo "Skipping One-Time Password Generation....."
            extract_docker_images_and_save_in_temp_folder
            transfer_docker_images_and_load_on_remote_server
        else
            echo "Generating one time password"
            generate_passwordless_communication
            extract_docker_images_and_save_in_temp_folder
            transfer_docker_images_and_load_on_remote_server
            
        fi   
    fi
}

# Entrypoint for the migration script

while getopts ":hu:s:" opt; do
  case $opt in
    h) 
    echo "$usage"
    exit
    ;;
    u) 
    username="$OPTARG"
    ;;
    s) 
    ip_address="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
    -*) echo "$usage"
    ;;
  esac
  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

if [[ -z $ip_address ]]; then
echo "$usage"
elif [[ -z $username ]]; then
echo "$usage"
else
    start_migration
fi