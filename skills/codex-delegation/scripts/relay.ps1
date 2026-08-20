# Relay: resume a finished Codex session with a follow-up brief, keeping its context.
#
#   .\relay.ps1 -From <sentinel> -Name <new sentinel> -Worktree <path> -Brief <file>
#
# Use when a read-only reviewer has finished and its findings are the follow-up work.
# It already holds the whole branch in context; a fresh run would re-read all of it.
param(
  [Parameter(Mandatory=$true)][string]$From,
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$Worktree,
  [Parameter(Mandatory=$true)][string]$Brief,
  [string]$Model  = $(if ($env:CODEX_MODEL) { $env:CODEX_MODEL } else { 'gpt-5-codex' }),
  [string]$Effort = 'medium'
)

$ErrorActionPreference = 'Stop'
$wt    = (Resolve-Path $Worktree).Path
$brief = (Resolve-Path $Brief).Path
$runs  = if ($env:CODEX_RUNS) { $env:CODEX_RUNS } else { Join-Path (git -C $wt rev-parse --show-toplevel).Replace('/','\') '.codex-runs' }
$fromLog = "$runs\$From.log"
if (-not (Test-Path $fromLog)) { throw "not found: $fromLog" }

# Codex prints its own session id into the transcript. Failing to find it must stop the
# run: silently starting a fresh session would be indistinguishable, from the outside,
# from a successful relay — while carrying none of the context that justified relaying.
$sid = (Select-String -Path $fromLog -Pattern 'session id:\s*([0-9a-fA-F-]{36})' |
        Select-Object -First 1).Matches.Groups[1].Value
if (-not $sid) { throw "no session id found in $fromLog" }

# Same normalisation as dispatch.ps1 — see the note there.
$resolvedRaw = (git -C $wt rev-parse --show-toplevel 2>$null)
$resolvedTop = if ($resolvedRaw) { (Resolve-Path $resolvedRaw -ErrorAction SilentlyContinue).Path } else { $null }
if (-not $resolvedTop -or $resolvedTop -ne $wt) { throw "preflight FAILED: '$wt' resolves to '$resolvedRaw'" }
Write-Output "preflight ok: $wt (relay $sid from $From)"

$log = "$runs\$Name.log"; $out = "$runs\$Name.out"; $exit = "$runs\$Name.exit"
Remove-Item $exit, $out -Force -ErrorAction SilentlyContinue
git -C $wt status --porcelain --ignored | Out-File -FilePath "$runs\$Name.before" -Encoding UTF8

# `codex exec resume` carries the session's own cwd and rejects -C, so enter the tree.
$inner = @"
Set-Location '$wt'
`$p = Get-Content -Raw '$brief'
`$p | codex exec resume '$sid' -m $Model -c model_reasoning_effort='"$Effort"' ``
  --dangerously-bypass-approvals-and-sandbox -o '$out' - *> '$log'
`$LASTEXITCODE | Set-Content '$exit'
"@
$enc  = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
$proc = Start-Process pwsh -ArgumentList '-NoProfile','-EncodedCommand',$enc -WindowStyle Hidden -PassThru
Write-Output "$Name PID=$($proc.Id) worktree=$(Split-Path $wt -Leaf) relayed=$sid"
