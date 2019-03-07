$ErrorActionPreference = 'Stop';
$VERSION=(type VERSION)
$IMAGE = "alpine:latest"
$VERSION=$VERSION -replace '\.','-'
$DATE=([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host Starting build

echo "Building Picapport $VER at $DATE"

if ($isWindows){
  docker build -t $env:REPO --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION -f Dockerfile.windows .
} else {
  docker build -t $env:REPO --build-arg IMAGE="$env:ARCH/$IMAGE" --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION --build-arg "ARCH=$env:ARCH" -f Dockerfile .
}

docker images

#echo $env:DOCKER_PASS | docker login -u $env:DOCKER_USER --password-stdin
#docker push $env:REPO`:windows-amd64
#docker logout
