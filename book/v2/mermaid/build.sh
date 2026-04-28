#!/bin/bash
for filename in `ls -1 . | grep -v -e png -e .sh`; do INPUT=`basename $filename .md`; docker run --rm -u `id -u`:`id -g` -v ./:/data minlag/mermaid-cli -i ${INPUT}.md -o ${INPUT}.png; done

find . -type f -name "*-1.png" -exec bash -c 'mv "$0" "${0%-1.png}.png"' {} \;
mv ./*.png ../images
