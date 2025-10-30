#!/bin/bash
##################################################################################################
# Author:big_pannard
# mail:big_pannard@msn.com
# cp_media.sh --source [folderPath] --destination [DestinationPath] [--size minFileSize]
# Description: Copy media files from source folder to destination folder
# with optional minimum file size filter.
# --Source Folder Source
# --Destination Folder Destination
# --Size Minimum file size (e.g., 100k, 2M)
# --images|videos 
##################################################################################################
# Script Version History
# V.0.0 - Initial version
# V.0.1 - Added video mime types
# V.0.2 - Added final report with total files copied and renamed 
# V.0.3 - Added video copy mode
#
##################################################################################################



VERSION="V.0.3"
LOG_TAG_NAME="Media_Copier"
FOLDER_PATH=""
MODE=0
VERBOSE=0

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
    if [ "$VERBOSE" -eq "1" ] || [ "$1" -gt 0 ]; then
        echo -e "$2"
    fi
    
    # if level is not 0 log the message into syslog
    if [ "$1" -gt 0 ]; then
        log_info "$1" "$2"
    fi
}

# Set mode function to set MODE variable
# $1 = mode (1=images,2=videos)
# returns 0 if mode is set, 1 if error  
# Only one mode can be set at a time
function set_mode(){
    if [ "$MODE" -ne 0 ]; then
        printM 3 "Error: Both --images and --videos parameters cannot be used together."
        printM 3 "Script Exiting"
        return 1
    fi
    MODE="$1"
}

# Set source folder function
# $1 = source folder path
# returns SOURCE_FOLDER variable
function set_source_folder(){
    SOURCE_FOLDER="$1"
    # Check if folder ends with /
    check_folder_slash "${SOURCE_FOLDER}"
    SOURCE_FOLDER=$FOLDER_PATH

    # check if source folder exists
    if [ ! -d "${SOURCE_FOLDER}" ]; then
        printM 3 "Error: Source folder ${SOURCE_FOLDER} does not exist."
        printM 3 "Script Exiting"
        exit 1
    fi

    printM 1 "Source Folder set to ${SOURCE_FOLDER}"
}   

# Set destination folder function
# $1 = destination folder path
# returns DESTINATION_FOLDER variable
function set_destination_folder(){
    DESTINATION_FOLDER="$1"
    # Check if folder ends with /
    check_folder_slash "${DESTINATION_FOLDER}"
    DESTINATION_FOLDER=$FOLDER_PATH

    # check if destination folder exists
    if [ ! -d "${DESTINATION_FOLDER}" ]; then
        printM 3 "Error: Destination folder ${DESTINATION_FOLDER} does not exist."

        read -p "Do you want to create it now? (y/n): " CREATE_DEST
        if [[ "${CREATE_DEST}" == "y" || "{$CREATE_DEST}" == "Y" ]]; then
            mkdir -p "${DESTINATION_FOLDER}"
            printM 0 "Destination folder ${DESTINATION_FOLDER} created."
        else
            printM 3 "Destination folder creation declined by user."   
            printM 3 "Script Exiting"
            exit 1
        fi
    fi

    printM 1 "Destination Folder set to ${DESTINATION_FOLDER}"
}

#  Print_help_message
#  Print on screen how use this package
function print_help_message(){
    echo "Usage: $0 --source [folderPath] --destination [DestinationPath] [--size minFileSize] [--images|--videos]"
    echo "Example: $0 --source /home/user/Pictures --destination /mnt/backup/Pictures --size 200k --images"
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
            set_source_folder "$2"; 
            shift 
        ;;
        --destination) 
            set_destination_folder "$2"; 
            shift 
        ;;
        --size) 
            SIZE="$2"; 
            printM 1 "Minimum file size set to ${SIZE}"
            shift
        ;;
        --images) 
            set_mode 1;
            printM 1 "Image mode enabled."
        ;;
        --videos) 
            set_mode 2;
            printM 1 "Video mode enabled."
        ;;
        --verbose) 
            VERBOSE=1;
            printM 1 "Verbose mode enabled."
        ;;
        *) 
            # if unknown parameter is passed
            # print error and exit
            printM 3 "Unknown parameter passed: $1"
            print_help_message
            printM 3 "Script Exiting";
            exit 1
        ;;
    esac
    shift
    done

    # Check if source and destination folders are set
    if [ -z "${SOURCE_FOLDER}" ] || [ -z "${DESTINATION_FOLDER}" ] ; then
        printM 3 "Error: Source and Destination folders must be specified."
        print_help_message
        printM 3 "Script Exiting"
        exit 1
    fi
    # Check if mode is set
    if [ "$MODE" -eq 0 ]; then
        printM 1 "No mode specified. Defaulting to image mode."
        MODE=1
    fi

}

# Get mime types from mime.types file
# $1 = mime type category (e.g., image, video)
# returns EXTENTIONS array with file extensions
function mime_type_parsing(){
    # Get mime types from mime.types file
    EXTENTIONS=($(grep -i "^$1" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' ))
}


# Prepare find command arguments based on EXTENTIONS array
# returns ARGS array with find command arguments
function prepare_args(){
    # Build find command arguments
    ARGS=( "( -iname *."${EXTENTIONS[0]})
    unset EXTENTIONS[0]
    for EXT in "${EXTENTIONS[@]}"; do
        ARGS+=("-o" "-iname *."${EXT})
    done
    ARGS+=( ")")
    ARGS+=("-type" "f")
    if [ ! -z "${SIZE}" ]; then
        ARGS+=("-size" "${SIZE}")
    fi
    ARGS+=("-print0")
}

# Copy images with prepared arguments
function copy_images_prepared_args(){
    # Get image mime types from mime.types file
    #EXTENTIONS=($(grep -i "^image" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' ))
    mime_type_parsing "image"
    prepare_args

}

# Copy videos with prepared arguments
function copy_videos_prepared_args(){
    # Get video mime types from mime.types file
    mime_type_parsing "video"
    prepare_args
}

# Rename a file to allow copy
function rename_file()
{
    printM 0 "\tRename file $1"
    BASE_NAME=$(basename "$1")
    EXT="${BASE_NAME##*.}" 
    FILENAME="${BASE_NAME%.*}"
    let COUNTER=1
    NEW_FILENAME="${FILENAME}_c${COUNTER}.${EXT}"
    while [ -f "$2/${NEW_FILENAME}" ]; do
        let COUNTER+=1
        NEW_FILENAME="${FILENAME}_c${COUNTER}.${EXT}"
    done
    printM 0 "\tRenamed to ${NEW_FILENAME}"
    return 0
}


#########################################################################################
# Main script execution starts here
# Check input parameters
printM 1 "CP_MEDIA version ${VERSION}"
check_parameters "$@"


# Prepare find command arguments based on mode
case ${MODE} in
    1) 
        printM 1 "Image mode selected."
        copy_images_prepared_args 
    ;;
    2) 
        printM 1 "Video mode selected."
        copy_videos_prepared_args 
    ;;
    *) printM 3 "Error: Invalid mode selected. Use --images or --videos."
       printM 3 "Script Exiting"
       exit 1 ;;
esac

FILE_COPIED=0
FILE_RENAMED=0
FILE_NOT_COPIED=()

read -p "Do you want to continue? [y,n]:" START

if [ "${START}" != "y" ]; then
    printM 1 "Process stop by user"
    exit 0
fi

while IFS= read -r -d '' FICHIER <&3; do
    printM 0 "File found: $FICHIER"
    DESTINATION_FILE_NAME="$DESTINATION_FOLDER$(basename "$FICHIER")"
    printM 0 "\tDestination filepath ${DESTINATION_FILE_NAME}"
    # Check if the file already exist into the destination folder
    if [ ! -f "${DESTINATION_FILE_NAME}" ]; then
        printM 0 "\tFile not exist in destiantion folder: ${FICHIER}" 
        printM 0 "\tCopying file: ${FICHIER} to ${DESTINATION_FOLDER}"
        
        # Copy the file to destianation folder
        cp -v "$FICHIER" "$DESTINATION_FOLDER"
        if [ "$?" -eq 0 ]; then
            FILE_COPIED=$((FILE_COPIED+1))
            printM 0 "\tCopy done ${FICHIER}"
        else
            # cp return error code 
            printM 2 "Warning: Failed to copy $FICHIER error "$?
            FILE_NOT_COPIED+=("$FICHIER")
        fi
    else
        # File already exists 
        printM 0 "\tFile already exists at destination, new filename will be created for: $FICHIER"
        SOURCE_SIZE=$(stat -c%s ${FICHIER})
        DESTINATION_SIZE=$(stat -c%s ${DESTINATION_FILE_NAME})
        if ! [ ${SOURCE_SIZE} -eq ${DESTINATION_SIZE} ]; then
            #Same Name but size different
            printM 0 "\tSame Filename but size different source:${SOURCE_SIZE}o destiantion:${DESTINATION_SIZE}o"
            rename_file ${FICHIER} ${DESTINATION_FOLDER}
            printM 0 "\tCopying file with a new name: $NEW_FILENAME"
            cp -v "$FICHIER" "$DESTINATION_FOLDER/$NEW_FILENAME"
            if [ "$?" -eq 0 ]; then
                FILE_COPIED=$((FILE_COPIED+1))
                FILE_RENAMED=$((FILE_RENAMED+1))
                printM 0 "\tCopy done ${FICHIER}"
            else
                printM 2 "\tWarning: Failed to copy $FICHIER as $NEW_FILENAME err:$?"
                FILE_NOT_COPIED+=("$FICHIER")
            fi
        else
            #Same Name, Size = doublons
            printM 0 "\t${FICHIER} considered like doublon"
            FILE_NOT_COPIED+=("${FICHIER}")
        fi
    fi
done 3< <(find ${SOURCE_FOLDER} ${ARGS[@]})

#### PRINT REPORT
printM 1 "##################Final Report#######################################"
printM 1 "File copy process completed."
printM 1 "Total files copied: $FILE_COPIED"
printM 1 "Total files renamed due to duplicates: $FILE_RENAMED"
printM 1 "#####################################################################"
if [ "${#FILE_NOT_COPIED[@]}" -gt 0 ]; then
    printM 2 "Files not be copied: ${#FILE_NOT_COPIED[@]}"
    for FILE in "${FILE_NOT_COPIED[@]}"; do
        printM 2 "$FILE"
    done
    printM 1 "#####################################################################"
fi  