#!/bin/bash
list="images-full.txt"
output="images.tar.gz"

usage () {
    echo "USAGE: $0 "
    echo "  [ --image-list | -l ] text file with the list of images to save; one image per line."
    echo "  [ --output     | -o ] output tar.gz file to be generated; an archive of all saved docker images."
    echo "  [ --help       | -h ] Usage message"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--output)
        output="$2"
        shift # past argument
        shift # past value
        ;;
        -l|--image-list)
        list="$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        help="true"
        shift
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done

if [[ $help ]]; then
    usage
    exit 0
fi

# pull each image from the list
pulled=""
count=0
total=$(cat $list | wc -l)

while IFS= read -r i; do
    [ -z "${i}" ] && continue

    (( count++ ))
    echo ""
    echo "### Handling image ${count}/${total} ###"
    if docker pull "${i}" > /dev/null 2>&1; then
        echo "Image pulled successfully: ${i}"
        pulled="${pulled} ${i}"
    else
        if docker inspect "${i}" > /dev/null 2>&1; then
            pulled="${pulled} ${i}"		
        else
            echo "Image pull failed: ${i}"
        fi
    fi
done < "${list}"
echo "finished pulling all $(echo ${pulled} | wc -w | tr -d '[:space:]') images"

echo "Creating ${output} with $(echo ${pulled} | wc -w | tr -d '[:space:]') images"
docker save $(echo ${pulled}) | gzip --stdout > ${output}

echo "Finished creating archive:"
ls -lah ${output}
