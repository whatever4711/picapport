$ErrorActionPreference = 'Stop';

echo $env:REPO`:windows-amd64

([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t $env:REPO --build-arg BUILD_DATE=%([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")% -f Dockerfile.windows .
