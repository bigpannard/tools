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
FOLDER_PATH=""

#  Log message to syslog
#  $1 = level (0=info,1=info,2=warn,3=err,default=info)
#  $2 = message 
function log_info (){
    LOCAL0='info'
    # Set log level
    # Information from the first parameter
    case "$1" in
        0) LOCAL0='info';;
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
# $1 = folder path
# returns folderPath variable with trailing slash
# this method modifies global variable FOLDER_PATH
function check_folder_slash(){
    FOLDER_PATH="$1"
    if [[ "${FOLDER_PATH: -1}" != "/" ]]; then
        FOLDER_PATH="${FOLDER_PATH}/"
    fi
}

#  PrintM print a message to console and log to syslog if level is not 0
#  $1 = level (0=info,1=info,2=warn,3=err,default=info)
#  $2 = message
function printM(){
    echo "$2"
    # if level is not 0 log the message into syslog
    if [ "$1" -ne 0 ]; then
        log_info "$1" "$2"
    fi
}

# Check_parameters function to validate input parameters
# $1 = source folder
# $2 = destination folder
# $3 = size (optional)
# returns 0 if parameters are valid, 1 otherwise    
function check_parameters(){
    while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source) 
            SOURCE_FOLDER="$2"; 
            printM 0 "Source Folder set to ${SOURCE_FOLDER}"
            shift 
        ;;
        --destination) 
            DESTINATION_FOLDER="$2"; 
            printM 0 "Destination Folder set to ${DESTINATION_FOLDER}"
            shift 
        ;;
        --size) 
            SIZE="$2"; 
            printM 0 "Minimum file size set to ${SIZE}"
            shift
        ;;
        *) 
            # if unknown parameter is passed
            # print error and exit
            printM 3 "Unknown parameter passed: $1"
            printM 3 "Script Exiting";
            return 1
        ;;
    esac
        shift
    done

    # Validate required parameters
    # Source and Destination folders must be provided
    # If not, return 1
    if [ -z ${SOURCE_FOLDER} ] || [ -z ${DESTINATION_FOLDER} ]; then
        return 1
    else
        check_folder_slash "${SOURCE_FOLDER}"
        SOURCE_FOLDER=$FOLDER_PATH        
        check_folder_slash "$DESTINATION_FOLDER"
        DESTINATION_FOLDER=$FOLDER_PATH
        printM 0 "Parameters validated."
        printM 0 "Source Folder: ${SOURCE_FOLDER}"
        printM 0 "Destination Folder: ${DESTINATION_FOLDER}"    
        return 0
    fi
}

# Main script execution starts here
# Check input parameters
check_parameters "$@"
if [ "$?" -ne 0 ]; then
    # Invalid parameters
    # Print usage message and exit with error code 1
    echo "Usage: $0 --source [folderPath] --destination [DestinationPath] [--size minFileSize]"
    echo "Example: $0 --source /home/user/Pictures --destination /mnt/backup/Pictures --size 200k"
    printM 3 "Error: Invalid or missing parameters."
    printM 3 "Script Exiting"
    exit 1
fi


# Check if source folder exists
printM 0 "Checking if source folder ${SOURCE_FOLDER} exists..."
if [ ! -d "${SOURCE_FOLDER}" ]; then
    printM 3 "Error: Source folder ${SOURCE_FOLDER} does not exist."
    printM 3 "Script Exiting"
    exit 1
else
    # if source folder exists
    # print message and log it
    printM 0 "Source folder ${SOURCE_FOLDER} exists."
fi  

# Check if destination folder exists
printM 0 "Checking if destination folder ${DESTINATION_FOLDER} exists..."
if [ ! -d "${DESTINATION_FOLDER}" ]; then
    printM 0 "Error: Destination folder ${DESTINATION_FOLDER} does not exist."n
    read -p "Do you want to create it now? (y/n): " CREATE_DEST
    if [[ "${CREATE_DEST}" == "y" || "{$CREATE_DEST}" == "Y" ]]; then
        mkdir -p "${DESTINATION_FOLDER}"
        printM 0 "Destination folder ${DESTINATION_FOLDER} created."
    else
        printM 3 "Destination folder creation declined by user."   
        printM 3 "Script Exiting"
        exit 1
    fi
else
    # if destination folder exists
    # print message and log it
    printM 0 "Destination folder ${DESTINATION_FOLDER} exists."
fi

# Copy images from source to destination
printM 0 "Starting to copy images from ${SOURCE_FOLDER} to ${DESTINATION_FOLDER}..."

# Get image mime types from mime.types file
EXTENTIONS=($(grep -i "^image" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' ))

# Build find command arguments
ARGS=( "( -iname *."${EXTENTIONS[0]})
unset EXTENTIONS[0]
for EXT in "${EXTENTIONS[@]}"; do
    ARGS+=("-o" "-iname *."${EXT})
done
ARGS+=( ")")
ARGS+=("-print0")

FILE_COPIED=0
FILE_RENAMED=0
FILE_NOT_COPIED=()


while IFS= read -r -d '' FICHIER <&3; do
    printM 0 "File found: $FICHIER"
    if [ ! -f "$DESTINATION_FOLDER/$(basename "$FICHIER")" ]; then
        printM 0 "Copying image: $FICHIER to $DESTINATION_FOLDER"
        cp -v "$FICHIER" "$DESTINATION_FOLDER"
        if [ "$?" -eq 0 ]; then
            FILE_COPIED=$((FILE_COPIED+1))
        else
            printM 2 "Warning: Failed to copy $FICHIER"
            FILE_NOT_COPIED+=("$FICHIER")
        fi
    else
        printM 0 "Image already exists at destination new filename will be created for: $FICHIER"
        BASE_NAME=$(basename "$FICHIER")
        EXT="${BASE_NAME##*.}" 
        FILENAME="${BASE_NAME%.*}"
        let COUNTER=1
        NEW_FILENAME="${FILENAME}_c${COUNTER}.${EXT}"
        while [ -f "${DESTINATION_FOLDER}/${NEW_FILENAME}" ]; do
            let COUNTER+=1
            NEW_FILENAME="${FILENAME}_c${COUNTER}.${EXT}"
        done
        printM 0 "Copying image as new file: $NEW_FILENAME"
        cp -v "$FICHIER" "$DESTINATION_FOLDER/$NEW_FILENAME"
        if [ "$?" -eq 0 ]; then
            FILE_COPIED=$((FILE_COPIED+1))
            FILE_RENAMED=$((FILE_RENAMED+1))
        else
            printM 2 "Warning: Failed to copy $FICHIER as $NEW_FILENAME"
            FILE_NOT_COPIED+=("$FICHIER")
        fi
        COUNTER=0
    fi
done 3< <(find ${SOURCE_FOLDER} ${ARGS[@]})

printM 0 "Image copy process completed."
printM 0 "Total files copied: $FILE_COPIED"
printM 0 "Total files renamed due to duplicates: $FILE_RENAMED"
if [ "${#FILE_NOT_COPIED[@]}" -gt 0 ]; then
    printM 2 "Files that could not be copied:"
    for FILE in "${FILE_NOT_COPIED[@]}"; do
        printM 2 "$FILE"
    done
fi  