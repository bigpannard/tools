# Help page

## Name

cp_image / copy image file from source folder to destination folder

## Synopsis

cp_image --source {SOURCEFOLDER} --destination {DESTINATIONFOLDER} [--size +100k]

## Option

* `--source`: Source folder where the images are stored
* `--destination`: Destination folder where the images will be store (multiple file with the same name will be rename like filename_cX.* where X is a counter)
* `--size`: Is the size parameter from find command e.g. +500k +1M +1G

## Exemple

```bash

    #!/bin/bash
    ./cp_image.sh --source /home/$USER/ --destination /tmp/$USER/IMG/ --size +500k
```

