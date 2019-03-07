$ErrorActionPreference = 'Stop';
$VERSION=(type VERSION)
$IMAGE = "alpine:latest"
$QEMU_ARCH = $env:ARCH -replace 'arm32.*','arm' -replace 'arm64.*','aarch64' -replace 'amd64','x86_64'
$VERSION=$VERSION -replace '\.','-'
$DATE=([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host Starting build

echo "Building Picapport $VER at $DATE"

if ($isWindows){
  docker build -t picapport --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION -f Dockerfile.windows .
} else {
  docker run --rm --privileged "multiarch/qemu-user-static:register" --reset
  docker build -t picapport --build-arg IMAGE="$env:ARCH/$IMAGE" --build-arg QEMU=$QEMU_ARCH --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION --build-arg "ARCH=$env:ARCH" -f Dockerfile .
}

docker images

#echo $env:DOCKER_PASS | docker login -u $env:DOCKER_USER --password-stdin
#docker push $env:REPO`:windows-amd64
#docker logout
