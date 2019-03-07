$ErrorActionPreference = 'Stop';
$VERSION=(type VERSION)
$VERSION=$VERSION -replace '\.','-'
$DATE=([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")

echo "Building Picapport $VER at $DATE"

docker build -t $env:REPO`:windows-amd64 --build-arg BUILD_DATE=$DATE --build-arg VERSION=$VERSION -f Dockerfile.windows .

echo | set /p="$env:DOCKER_PASS" | docker login -u $env:DOCKER_USER --password-stdin
docker push $env:REPO`:windows-amd64
docker logout
