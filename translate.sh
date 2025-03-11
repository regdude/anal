#!/bin/bash
podman run -ti --rm -p 5000:5000 --name libretranslate libretranslate/libretranslate

URL="http://127.0.0.1:5000/translate_file"
FILE="/home/user/Downloads/README.md"
SAVEPATH="/home/user/Downloads"
SAVENAME="README"
SAVEEXT="md"
declare -a TARGET=("fr" "zh" "de" "es")
TEMPFILE="$SAVEPATH/$SAVENAME.txt"

/bin/cp -rf "$FILE" "$TEMPFILE"


for i in "${TARGET[@]}"
do
	response=$(curl -s -w "%{http_code}" -F "target=$i" -F "source=en" -F "file=@$TEMPFILE" $URL)
	http_code=$(tail -n1 <<< "$response")
	content=$(sed '$ d' <<< "$response")
	if [[ $http_code -ne 200 ]]; then
        	echo "ERROR: HTTP status $http_code"
        	exit 1
	fi

	DOWNLOAD=$(echo $content | jq -r '.translatedFileUrl')

	response=$(curl -s -o "$SAVEPATH/$SAVENAME.$i.$SAVEEXT" -w "%{http_code}" $DOWNLOAD)

	if [[ $http_code -ne 200 ]]; then
        	echo "ERROR: Download HTTP status not $http_code"
        	exit 1
	fi
done
rm "$TEMPFILE"
podman stop libretranslate
echo "OK"
