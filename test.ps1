Write-Host Starting test

#if ($env:ARCH -ne "amd64") {
Write-Host "Arch $env:ARCH detected. Skip testing."
exit 0
#}

#$ErrorActionPreference = 'SilentlyContinue';
#docker kill patest
#docker rm -f patest
#
#$ErrorActionPreference = 'Stop';
#Write-Host Starting container
#docker run --name patest -p 8080:80 -d $env:REPO`:windows-amd64
#Start-Sleep 10
#
#docker logs patest
#
#$ErrorActionPreference = 'SilentlyContinue';
#docker kill patest
#docker rm -f patest
