#!/bin/bash
##################################################################################################
# Author:big_pannard
# mail:big_pannard@msn.com
# cp_image.sh --source [folderPath] --destination [DestinationPath] [--size minFileSize]
# Description: Copy image files from source folder to destination folder
# with optional minimum file size filter.
# --Source Folder Source
# --Destination Folder Destination
# --Size Minimum file size (e.g., 100k, 2M)
##################################################################################################

VERSION="V.0.0"
LOG_TAG_NAME="Image_Copier"

#  Log message to syslog
#  $1 = level (0=info,1=info,2=warn,3=err)
#  $2 = message 
function log_info (){
    LOCAL0='info'
    # Set log level
    case "$1" in
        0) ;;
        1) LOCAL0='info' ;;
        2) LOCAL0='warn' ;;
        3) LOCAL0='err'  ;;
        *) LOCAL0='info' ;;
    esac
    # if level is not 0 log the message into syslog
    if [ "$1" -ne 0 ]; then
        logger -t ${LOG_TAG_NAME} -p local0.${LOCAL0}  "$2"
    fi

}

# Check foler name ends with /
function check_folder_slash(){
    folderPath="$1"
    if [[ "${folderPath: -1}" != "/" ]]; then
        folderPath="${folderPath}/"
    fi
}

#  Print message to console and log to syslog if level is not 0
#  $1 = level (0=info,1=info,2=warn,3=err)
#  $2 = message
function printMessage(){
    echo "$2"
    # if level is not 0 log the message into syslog
    if [ "$1" -ne 0 ]; then
        log_info "$1" "$2"
    fi
}

function check_parameters(){
    while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source) 
            SOURCE_FOLDER="$2"; 
            echo "Source Folder set to ${SOURCE_FOLDER}"
            shift 
        ;;
        --destination) 
            DESTINATION_FOLDER="$2"; 
            echo "Destination Folder set to ${DESTINATION_FOLDER}"
            shift 
        ;;
        --size) 
            SIZE="$2"; 
            echo "Minimum file size set to ${SIZE}"
            shift
        ;;
        *) 
            echo "Unknown parameter passed: $1"
            echo "Script Exiting";
            return 1
        ;;
    esac
        shift
    done

    if [ -z "$SOURCE_FOLDER" ] || [ -z "$DESTINATION_FOLDER" ]; then
        return 1
    else
        check_folder_slash "$SOURCE_FOLDER"
        SOURCE_FOLDER=$folderPath        
        check_folder_slash "$DESTINATION_FOLDER"
        DESTINATION_FOLDER=$folderPath
        echo "Parameters validated."
        echo "Source Folder: ${SOURCE_FOLDER}"
        echo "Destination Folder: ${DESTINATION_FOLDER}"    
        return 0
    fi
}

check_parameters "$@"
if [ "$?" -ne 0 ]; then
    echo "Usage: $0 --source [folderPath] --destination [DestinationPath] [--size minFileSize]"
    echo "Example: $0 --source /home/user/Pictures --destination /mnt/backup/Pictures --size 200k"
    echo "Error: Invalid or missing parameters."
    echo "Script Exiting"
    exit 1
fi


# Check if source folder exists
echo "--------------------------------"
printMessage 0 "Checking if source folder ${SOURCE_FOLDER} exists..."
if [ ! -d "${SOURCE_FOLDER}" ]; then
    printMessage 0 "Error: Source folder ${SOURCE_FOLDER} does not exist."
    printMessage 0 "Script Exiting"
    exit 1
else
    printMessage 0 "Source folder ${SOURCE_FOLDER} exists."
fi  

# Check if destination folder exists
printMessage 0 "Checking if destination folder ${DESTINATION_FOLDER} exists..."
if [ ! -d "${DESTINATION_FOLDER}" ]; then
    printMessage 0 "Error: Destination folder ${DESTINATION_FOLDER} does not exist."n
    read -p "Do you want to create it now? (y/n): " create_dest
    if [[ "$create_dest" == "y" || "$create_dest" == "Y" ]]; then
        mkdir -p "${DESTINATION_FOLDER}"
        printMessage 0 "Destination folder ${DESTINATION_FOLDER} created."
    else
        printMessage 3 "Destination folder creation declined by user."   
        printMessage 3 "Script Exiting"
        exit 1
    fi
fi

printMessage 0 "Destination folder ${DESTINATION_FOLDER} exists."

# Copy images from source to destination
printMessage 0 "Starting to copy images from ${SOURCE_FOLDER} to ${DESTINATION_FOLDER}..."

# Get image mime types from mime.types file
EXTENTIONS=$(grep -i "^image" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' | sed -e 's/ / \-o \-iname *\./g' | sed -e 's/\-o \-iname \*\.$//g' )
EXTENTIONS="'*.${EXTENTIONS}"


/usr/bin/find $SOURCE_FOLDER -type f -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -size +500k -print0  |
while IFS= read -r -d '' fichier; do
    echo "File found: $fichier"
    # if [ ! -f "$DESTINATION_FOLDER/$(basename "$fichier")" ]; then
    #     printMessage 0 "Copying image: $fichier to $DESTINATION_FOLDER"
    #     cp -v "$fichier" "$DESTINATION_FOLDER"
    # else
    #     printMessage 0 "Image already exists at destination new filename will be created for: $fichier"
    #     base_name=$(basename "$fichier")
    #     extension="${base_name##*.}" 
    #     filename="${base_name%.*}"
    #     counter=1
    #     new_filename="${filename}_copy${counter}.${extension}"
    #     while [ -f "$DESTINATION_FOLDER/$new_filename" ]; do
    #         counter=$((counter + 1))
    #         new_filename="${filename}_copy${counter}.${extension}"
    #     done
    #     printMessage 0 "Copying image as new file: $new_filename"
    #     cp -v "$fichier" "$DESTINATION_FOLDER/$new_filename"
    #     counter=1
    # fi
done
