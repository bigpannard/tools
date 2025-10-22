#!/bin/bash

# Sélectionne la destination avec une boîte de dialogue
DEST=$(zenity --file-selection --directory --title="Sélectionnez la destination" 2>/dev/null)

# S'il n'y a pas de sélection de répertoire de destination ou une annulation, on arrête
[ -z "$DEST" ] && exit

for FILE in "$@"; do
# Le nom initial du lien sera le basename ...
SymL=$(basename "$FILE")

# ... sauf s'il commence par un . qu'il faut supprimer (sinon le lien devient caché)
[ ${SymL:: 1} == "." ] && SymL=${SymL:1}

if [ -h "$DEST/$SymL" ]; then
#zenity --error --text="Le fichier $SymL existe déjà dans $DEST."
zenity --error --text="Le lien symbolique $SymL existe déjà dans $DEST."

else
ln -s "$(realpath "$FILE")" "$DEST/$SymL"
fi
done

