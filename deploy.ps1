$ErrorActionPreference = 'Stop';

function Retry-Command
{
    param (
    [Parameter(Mandatory=$true)][string]$command,
    [Parameter(Mandatory=$false)][int]$retries = 5,
    [Parameter(Mandatory=$false)][int]$secondsDelay = 2
    )

    $retrycount = 0
    $completed = $false

    while (-not $completed) {
        try {
            $command 2>&1
            Write-Verbose ("Command [{0}] succeeded." -f $command)
            $completed = $true
        } catch {
            if ($retrycount -ge $retries) {
                Write-Verbose ("Command [{0}] failed the maximum number of {1} times." -f $command, $retrycount)
                throw
            } else {
                Write-Verbose ("Command [{0}] failed. Retrying in {1} seconds." -f $command, $secondsDelay)
                Start-Sleep $secondsDelay
                $retrycount++
            }
        }
    }
}

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
Retry-Command -Command "docker push $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME" -Verbose

if ($isWindows) {
  # Windows
  Write-Host "Rebasing image to produce 1709 variant"
  npm install -g rebase-docker-image
  Retry-Command -Command "rebase-docker-image `
    $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME `
    -t $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1709 `
    -b microsoft/nanoserver:1709" -Verbose

  Write-Host "Rebasing image to produce 1803 variant"
  npm install -g rebase-docker-image
  Retry-Command -Command "rebase-docker-image `
    $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME `
    -t $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1803 `
    -b microsoft/nanoserver:1803" -Verbose

  Write-Host "Rebasing image to produce 1809 variant"
  npm install -g rebase-docker-image
  Retry-Command -Command "rebase-docker-image `
    $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME `
    -s microsoft/nanoserver:sac2016 `
    -t $($image):$os-$env:ARCH-$env:APPVEYOR_REPO_TAG_NAME-1809 `
    -b stefanscherer/nanoserver:10.0.17763.253" -Verbose

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
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1709" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1803" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1809"
    docker manifest annotate "$($image):$env:APPVEYOR_REPO_TAG_NAME" "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm --variant v6
    docker manifest annotate "$($image):$env:APPVEYOR_REPO_TAG_NAME" "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm64 --variant v8
    Retry-Command -Command "docker manifest push $($image):$env:APPVEYOR_REPO_TAG_NAME" -Verbose

    Write-Host "Pushing manifest $($image):latest"
    docker -D manifest create "$($image):latest" `
      "$($image):linux-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-i386-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-ppc64le-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):linux-s390x-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1709" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1803" `
      "$($image):windows-amd64-$env:APPVEYOR_REPO_TAG_NAME-1809"
    docker manifest annotate "$($image):latest" "$($image):linux-arm32v6-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm --variant v6
    docker manifest annotate "$($image):latest" "$($image):linux-arm64v8-$env:APPVEYOR_REPO_TAG_NAME" --os linux --arch arm64 --variant v8
    Retry-Command -Command "docker manifest push $($image):latest" -Verbose

    Invoke-WebRequest -Uri ("https://hooks.microbadger.com/images/whatever4711/picapport/h54qEvKKiyj8evp5FLbwRCouqks=") -Method POST
  }
}
