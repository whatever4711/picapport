$ErrorActionPreference = 'Stop';

if (! (Test-Path Env:\APPVEYOR_REPO_TAG_NAME)) {
  Write-Host "No version tag detected. Skip publishing."
  exit 0
}

$image = $env:REPO

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

$os = If ($isWindows) {"windows"} Else {"linux"}
docker tag picapport "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME"
docker push "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME"

if ($isWindows) {
  # windows
  $ErrorActionPreference = 'SilentlyContinue';
  npm install -g rebase-docker-image
  $ErrorActionPreference = 'Stop';

  Write-Host "Rebasing image to produce 2016/1607 variant"
  rebase-docker-image `
   "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME" `
   -s stefanscherer/nanoserver:1809 `
   -t "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1607" `
   -b stefanscherer/nanoserver:sac2016

  Write-Host "Rebasing image to produce 1709 variant"
  rebase-docker-image `
   "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME" `
   -s stefanscherer/nanoserver:1809 `
   -t "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1709" `
   -b stefanscherer/nanoserver:1709

  Write-Host "Rebasing image to produce 1803 variant"
  rebase-docker-image `
   "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME" `
   -s stefanscherer/nanoserver:1809 `
   -t "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1803" `
   -b stefanscherer/nanoserver:1803

  Write-Host "Rebasing image to produce 1903 variant"
  rebase-docker-image `
   "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME" `
   -s stefanscherer/nanoserver:1809 `
   -t "$($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1903" `
   -b stefanscherer/nanoserver:1903

} else {
  # Linux
  if ($env:ARCH -eq "s390x") {
    # The last in the build matrix
    docker -D manifest create "$($image):$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-i386-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-ppc64le-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-s390x-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1607" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1709" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1803" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1903"
    docker manifest annotate "$($image):$env:APPVEYOR_REPO_TAG_NAME" "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm --variant v6
    docker manifest annotate "$($image):$env:APPVEYOR_REPO_TAG_NAME" "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm64 --variant v8
    docker manifest push "$($image):$env:APPVEYOR_REPO_TAG_NAME"

    Write-Host "Pushing manifest $($image):latest"
    docker -D manifest create "$($image):latest" `
      "$($image):linux-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-i386-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-ppc64le-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-s390x-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1607" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1709" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1803" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1903"
    docker manifest annotate "$($image):latest" "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm --variant v6
    docker manifest annotate "$($image):latest" "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm64 --variant v8
    docker manifest push "$($image):$env:APPVEYOR_REPO_TAG_NAME"

    $result = Invoke-WebRequest -Uri "https://hooks.microbadger.com/images/whatever4711/picapport/h54qEvKKiyj8evp5FLbwRCouqks=" -Method POST
  }
}
