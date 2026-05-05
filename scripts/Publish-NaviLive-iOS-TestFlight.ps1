param(
  [string]$RepoSlug = "kazek5p-git/navi-live",
  [string]$Ref = "main",
  [string]$BuildNumber,
  [switch]$NoUpload,
  [switch]$NoWait
)

$ErrorActionPreference = "Stop"

function Assert-Tooling {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "gh is not available in PATH."
  }
}

function Invoke-GitHub {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  & gh @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "gh command failed: gh $($Arguments -join ' ')"
  }
}

function Assert-RemoteWorkflowSourceReady {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Ref
  )

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is not available in PATH."
  }

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $statusLines = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read git status before TestFlight workflow."
  }

  $allowedDirtyPatterns = @(
    '^\s*M\s+native-ios/project\.yml$',
    '^\s*M\s+native-ios/AppStoreConnect/(TestFlight-what-to-test\.txt|AppStoreConnect-UI-Copy-Pack\.md)$',
    '^\?\?\s+release/testflight/',
    '^\s*M\s+release/testflight/'
  )

  $blockingDirtyLines = @()
  foreach ($line in $statusLines) {
    $isAllowed = $false
    foreach ($pattern in $allowedDirtyPatterns) {
      if ($line -match $pattern) {
        $isAllowed = $true
        break
      }
    }
    if (-not $isAllowed) {
      $blockingDirtyLines += $line
    }
  }

  if ($blockingDirtyLines.Count -gt 0) {
    $preview = ($blockingDirtyLines | Select-Object -First 20) -join "`n"
    throw "Nie uruchamiam TestFlight, bo GitHub Actions buduje z origin/$Ref, a lokalnie sa niezatwierdzone zmiany aplikacji. Zrob commit i push, a potem ponow wysylke. Pliki blokujace:`n$preview"
  }

  & git -C $repoRoot fetch origin $Ref --quiet
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to fetch origin/$Ref before TestFlight workflow."
  }

  $localHead = (& git -C $repoRoot rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read local HEAD before TestFlight workflow."
  }
  $remoteHead = (& git -C $repoRoot rev-parse "origin/$Ref").Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read origin/$Ref before TestFlight workflow."
  }

  if ($localHead -ne $remoteHead) {
    throw "Nie uruchamiam TestFlight, bo lokalny commit $localHead nie jest wypchniety na origin/$Ref ($remoteHead). Zrob git push i ponow wysylke."
  }
}
Assert-Tooling
Assert-RemoteWorkflowSourceReady -Ref $Ref

$uploadValue = if ($NoUpload) { "false" } else { "true" }

Write-Host ""
Write-Host "==> Dispatching Navi Live iOS signed workflow"
Write-Host ("Repo: " + $RepoSlug)
Write-Host ("Ref: " + $Ref)
Write-Host ("Upload to TestFlight: " + $uploadValue)
if (-not [string]::IsNullOrWhiteSpace($BuildNumber)) {
  Write-Host ("Build number override: " + $BuildNumber)
}

$workflowArgs = @("workflow", "run", "ios-signed-testflight.yml", "--repo", $RepoSlug, "--ref", $Ref, "-f", "upload_to_testflight=$uploadValue")
if (-not [string]::IsNullOrWhiteSpace($BuildNumber)) {
  $workflowArgs += @("-f", "build_number_override=$BuildNumber")
}
Invoke-GitHub @workflowArgs

Start-Sleep -Seconds 8

$runJson = gh run list --repo $RepoSlug --workflow "ios-signed-testflight.yml" --branch $Ref --limit 1 --json "databaseId,status,conclusion,headSha"
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($runJson)) {
  throw "Unable to resolve the latest workflow run."
}

$run = $runJson | ConvertFrom-Json | Select-Object -First 1
if (-not $run) {
  throw "No workflow run found after dispatch."
}
$runUrl = "https://github.com/$RepoSlug/actions/runs/$($run.databaseId)"

Write-Host ""
Write-Host "Latest run:"
Write-Host ("- Run ID: " + $run.databaseId)
Write-Host ("- URL: " + $runUrl)
Write-Host ("- Head SHA: " + $run.headSha)
Write-Host ("- Status: " + $run.status)

if (-not $NoWait) {
  Write-Host ""
  Write-Host "==> Waiting for workflow completion"
  & gh run watch $run.databaseId --repo $RepoSlug --exit-status
  if ($LASTEXITCODE -ne 0) {
    throw "Workflow run failed: $runUrl"
  }
}

Write-Host ""
Write-Host "Workflow completed successfully."
Write-Host ("URL: " + $runUrl)
