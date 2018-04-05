echo %REPO%

([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")


docker build -t %REPO% --build-arg BUILD_DATE=%([datetime]::now).toString("yyyy-MM-ddTHH:mm:ssZ")%  -f Dockerfile.windows .
