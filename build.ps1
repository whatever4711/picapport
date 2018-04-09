$ErrorActionPreference = 'Stop';
set VERSION=(type VERSION)
set DATE=([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t $env:REPO`:windows-amd64 --build-arg BUILD_DATE=%DATE% --build-arg VERSION=%VERSION% -f Dockerfile.windows .

docker login -u $env:DOCKER_USER -p $env:DOCKER_PASS

docker push $env:REPO`:windows-amd64
