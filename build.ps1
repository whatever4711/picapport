$ErrorActionPreference = 'Stop';

set DATE=([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t $env:REPO`:windows-amd64 --build-arg BUILD_DATE=%DATE% -f Dockerfile.windows .
