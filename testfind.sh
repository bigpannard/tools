#!/bin/bash

#EXTENTIONS=$(grep -i "^image" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' | sed -e 's/ / \-o \-iname *\./g' | sed -e 's/\-o \-iname \*\.$//g' )
EXTENTIONS=$(grep -i "^image" /etc/mime.types | awk '$2!=""{print $2,$3,$4,$5,$6}' | tr -d "\n" | tr -s '[:space:]' )
args=($EXTENTIONS)
echo "Args array initial: ${args[@]}"
echo "Args array length: ${#args[@]}"
for ext in "${args[@]}"; do
    echo "Extension processed: $ext"
done


# echo "Testing find command"
# find ${SOURCE_FOLDER} -type f \( -iname \*.jpeg -o -iname \*.jpg -o -iname \*.png -o -iname \*.gif \) -print0 |
# while IFS= read -r -d '' fichier; do
#     echo "File found: $fichier"
# done