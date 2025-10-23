#!/bin/bash
#####################################################################
# Author:Emmanuel Blancquart
# mail:big_pannard@msn.com
# cp_image.sh --source [folderPath] --destination [DestinationPath]
# --Source Folder Source
# --Destination Folder Destination
#####################################################################

VERSION="V.0.0"
LOG_TAG_NAME="Image_Copier"

function log_info (){
    echo "$1"
    logger -t ${LOG_TAG_NAME} -p local0.info  "$1"
}



if [ "$#" -eq 0 -o "$#" -ne 4 ]; then
    log_info "Usage: $0 --source [folderPath] --destination [DestinationPath]"
    log_info "Example: $0 --source /home/user/Pictures --destination /mnt/backup/Pictures"
    log_info "Error: Invalid number of parameters."
    log_info "Received $# parameters."
    log_info "<<Received parameters: $*>>"
    log_info "Script Exiting"
    exit 1
else
    log_info "Script Starting"
    log_info "Script Version ${VERSION}"
    log_info "Parameters received: $#"
    
    while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source) SOURCE_FOLDER="$2"; 
        log_info "Source Folder set to ${SOURCE_FOLDER}";
        shift 
        ;;
        --destination) DESTINATION_FOLDER="$2"; 
        log_info "Destination Folder set to ${DESTINATION_FOLDER}";
        shift 
        ;;
        *) echo "Unknown parameter passed: $1"; 
        log_info "Script Exiting";
        exit 1 
        ;;
    esac
    shift
    done
fi

# Check if source folder exists
echo "--------------------------------"
log_info "Checking if source folder ${SOURCE_FOLDER} exists..."
if [ ! -d "${SOURCE_FOLDER}" ]; then
    log_info "Error: Source folder ${SOURCE_FOLDER} does not exist."
    log_info "Script Exiting"
    exit 1
else
    log_info "Source folder ${SOURCE_FOLDER} exists."
fi  

# Check if destination folder exists
log_info "Checking if destination folder ${DESTINATION_FOLDER} exists..."
if [ ! -d "${DESTINATION_FOLDER}" ]; then
    log_info "Error: Destination folder ${DESTINATION_FOLDER} does not exist."n
    read -p "Do you want to create it now? (y/n): " create_dest
    if [[ "$create_dest" == "y" || "$create_dest" == "Y" ]]; then
        mkdir -p "${DESTINATION_FOLDER}"
        log_info "Destination folder ${DESTINATION_FOLDER} created."
    else
        log_info "Destination folder creation declined by user."   
        log_info "Script Exiting"
        exit 1
    fi
else
    log_info "Destination folder ${DESTINATION_FOLDER} exists."
fi

# Copy images from source to destination
log_info "Starting to copy images from ${SOURCE_FOLDER} to ${DESTINATION_FOLDER}..."

find $SOURCE_FOLDER -type f -print0 | 
while IFS= read -r -d '' fichier; do
  type=$(mimetype --output-format %m "$fichier")
  case "$type" in
    image/*) 
        if [ ! -f "$DESTINATION_FOLDER/$(basename "$fichier")" ]; then
            log_info "Copying image: $fichier to $DESTINATION_FOLDER"
            cp -v "$fichier" "$DESTINATION_FOLDER"
        else
            log_info "Image already exists at destination new filename will be created for: $fichier"
            base_name=$(basename "$fichier")
            extension="${base_name##*.}" 
            filename="${base_name%.*}"
            counter=1
            new_filename="${filename}_copy${counter}.${extension}"
            while [ -f "$DESTINATION_FOLDER/$new_filename" ]; do
                counter=$((counter + 1))
                new_filename="${filename}_copy${counter}.${extension}"
            done
            log_info "Copying image as new file: $new_filename"
            cp -v "$fichier" "$DESTINATION_FOLDER/$new_filename"

        fi

    ;;
    *) 
        echo "Skipping non-image file: $fichier"
  esac
done
