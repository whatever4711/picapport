$ErrorActionPreference = 'Stop';

echo $env:REPO

([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t $env:REPO:windows-amd64 --build-arg BUILD_DATE=%([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")% -f Dockerfile.windows .
