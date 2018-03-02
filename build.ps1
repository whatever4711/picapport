echo $REPO

([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t $picapport --build-arg --build-arg BUILD_DATE=%([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")%  -f Dockerfile.windows .
