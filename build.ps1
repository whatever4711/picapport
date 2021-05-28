$ErrorActionPreference = 'Stop'
$VERSION = type VERSION
$VERSION = $VERSION -replace '\.','-'
$IMAGE = "alpine:latest"
$QEMU_ARCH = $env:ARCH -replace 'arm32.*','arm' -replace 'arm64.*','aarch64' -replace 'amd64','x86_64'
$DATE = ([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")
$VCS_REF = git rev-parse --short HEAD
$VCS_URL = git config --get remote.origin.url

Write-Host Starting deploy
if (!(Test-Path ~/.docker)) { mkdir ~/.docker }
# "$env:DOCKER_PASS" | docker login --username "$env:DOCKER_USER" --password-stdin
# docker login with the old config.json style that is needed for manifest-tool
$auth =[System.Text.Encoding]::UTF8.GetBytes("$($env:DOCKER_USER):$($env:DOCKER_PASS)")
$auth64 = [Convert]::ToBase64String($auth)
@"
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$auth64"
    }
  },
  "experimental": "enabled"
}
"@ | Out-File -Encoding Ascii ~/.docker/config.json

Write-Host Starting build

echo "Building Picapport v$VERSION at $DATE"

docker version

if ($isWindows){
  docker build -t picapport --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION --build-arg VCS_REF=$VCS_REF --build-arg VCS_URL=$VCS_URL -f Dockerfile.windows .
} else {
  docker run --rm --privileged "multiarch/qemu-user-static:register" --reset
  docker build -t picapport --build-arg IMAGE="$env:ARCH/$IMAGE" --build-arg QEMU=$QEMU_ARCH --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION --build-arg "ARCH=$env:ARCH" --build-arg VCS_REF=$VCS_REF --build-arg VCS_URL=$VCS_URL -f Dockerfile .
}

docker images

docker inspect picapport
