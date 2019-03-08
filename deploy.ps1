$ErrorActionPreference = 'Stop';

function Retry-Command
{
    param (
    [Parameter(Mandatory=$true)][string]$command,
    [Parameter(Mandatory=$true)][hashtable]$args,
    [Parameter(Mandatory=$false)][int]$retries = 5,
    [Parameter(Mandatory=$false)][int]$secondsDelay = 2
    )

    # Setting ErrorAction to Stop is important. This ensures any errors that occur in the command are
    # treated as terminating errors, and will be caught by the catch block.
    $args.ErrorAction = "Stop"

    $retrycount = 0
    $completed = $false

    while (-not $completed) {
        try {
            & $command @args
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
  Write-Host "No version tag detected. Publishing latest."
  $TAG = 'latest'
} else {
  $TAG = $env:APPVEYOR_REPO_TAG_NAME
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
docker tag picapport "$($image):$os-$env:ARCH-$TAG"
Retry-Command -Command 'docker push "$($image):$os-$env:ARCH-$TAG"' -Args @args{} -Verbose

if ($isWindows) {
  # Windows
  Write-Host "Rebasing image to produce 1709 variant"
  npm install -g rebase-docker-image
  rebase-docker-image `
    "$($image):$os-$env:ARCH-$TAG" `
    -t "$($image):$os-$env:ARCH-$TAG-1709" `
    -b microsoft/nanoserver:1709

  Write-Host "Rebasing image to produce 1803 variant"
  npm install -g rebase-docker-image
  rebase-docker-image `
    "$($image):$os-$env:ARCH-$TAG" `
    -t "$($image):$os-$env:ARCH-$TAG-1803" `
    -b microsoft/nanoserver:1803

  Write-Host "Rebasing image to produce 1809 variant"
  npm install -g rebase-docker-image
  rebase-docker-image `
    "$($image):$os-$env:ARCH-$TAG" `
    -s microsoft/nanoserver:sac2016 `
    -t "$($image):$os-$env:ARCH-$TAG-1809" `
    -b stefanscherer/nanoserver:10.0.17763.253

} else {
  # Linux
  if ($env:ARCH -eq "s390x") {
    # The last in the build matrix
    docker -D manifest create "$($image):$TAG" `
      "$($image):linux-amd64-$TAG" `
      "$($image):linux-i386-$TAG" `
      "$($image):linux-arm32v6-$TAG" `
      "$($image):linux-arm64v8-$TAG" `
      "$($image):linux-ppc64le-$TAG" `
      "$($image):linux-s390x-$TAG" `
      "$($image):windows-amd64-$TAG" `
      "$($image):windows-amd64-$TAG-1709" `
      "$($image):windows-amd64-$TAG-1803" `
      "$($image):windows-amd64-$TAG-1809"
    docker manifest annotate "$($image):$TAG" "$($image):linux-arm-$TAG" --os linux --arch arm --variant v6
    docker manifest annotate "$($image):$TAG" "$($image):linux-arm64-$TAG" --os linux --arch arm64 --variant v8
    docker manifest push "$($image):$TAG"

#    Write-Host "Pushing manifest $($image):latest"
#    docker -D manifest create "$($image):latest" `
#      "$($image):linux-amd64-$TAG" `
#      "$($image):linux-i386-$TAG" `
#      "$($image):linux-arm-$TAG" `
#      "$($image):linux-arm64-$TAG" `
#      "$($image):linux-ppc64le-$TAG" `
#      "$($image):linux-s390x-$TAG" `
#      "$($image):windows-amd64-$TAG" `
#      "$($image):windows-amd64-$TAG-1709" `
#      "$($image):windows-amd64-$TAG-1803" `
#      "$($image):windows-amd64-$TAG-1809"
#    docker manifest annotate "$($image):latest" "$($image):linux-arm-$TAG" --os linux --arch arm --variant v6
#    docker manifest annotate "$($image):latest" "$($image):linux-arm64-$TAG" --os linux --arch arm64 --variant v8
#    docker manifest push "$($image):latest"
  }
}
