# Dispatch a Codex CLI run against a git worktree, detached, writing a sentinel quartet.
#
#   .\dispatch.ps1 -Name <sentinel> -Worktree <path> -Brief <file> [-Model M] [-Effort E]
#
# Windows note: the restricted sandbox modes (-s workspace-write / read-only) fail here
# with CreateProcessWithLogonW 1385 — the agent cannot run even `Get-Location`. Bypassing
# the sandbox is what makes the run work at all, which is why the brief carries the
# guardrails instead: forbidden git verbs, where results may be written, what is read-only.
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$Worktree,
  [Parameter(Mandatory=$true)][string]$Brief,
  [string]$Model  = $(if ($env:CODEX_MODEL) { $env:CODEX_MODEL } else { 'gpt-5-codex' }),
  [string]$Effort = 'medium'
)

$ErrorActionPreference = 'Stop'
$wt    = (Resolve-Path $Worktree).Path
$brief = (Resolve-Path $Brief).Path

# Preflight: a half-removed worktree keeps its files but loses its .git pointer, so git
# walks up and resolves it to the MAIN repository. Dispatching there edits the trunk.
# Test-Path cannot see this — only git's own resolution can.
$resolvedRaw = (git -C $wt rev-parse --show-toplevel 2>$null)
$resolvedRef = (git -C $wt rev-parse --abbrev-ref HEAD 2>$null)
# Normalise both sides through Resolve-Path rather than comparing strings: git reports
# forward slashes, and drive-letter case or a symlink is enough to make a raw compare
# reject a perfectly valid tree — a guard that always refuses guards nothing.
$resolvedTop = if ($resolvedRaw) { (Resolve-Path $resolvedRaw -ErrorAction SilentlyContinue).Path } else { $null }
if (-not $resolvedTop -or $resolvedTop -ne $wt) {
  throw "preflight FAILED: '$wt' resolves to '$resolvedRaw' (branch '$resolvedRef'). Probably a half-removed worktree; dispatching would edit the main repo."
}
Write-Output "preflight ok: $wt -> $resolvedRef"

$runs = if ($env:CODEX_RUNS) { $env:CODEX_RUNS } else { Join-Path (git -C $wt rev-parse --show-toplevel).Replace('/','\') '.codex-runs' }
New-Item -ItemType Directory -Force -Path $runs | Out-Null
$log = "$runs\$Name.log"; $out = "$runs\$Name.out"; $exit = "$runs\$Name.exit"
Remove-Item $exit, $out -Force -ErrorAction SilentlyContinue

# --ignored is required: plain --porcelain hides ignored paths, so a run that wrote
# 100MB of node_modules shows a clean tree and the snapshot proves nothing.
git -C $wt status --porcelain --ignored | Out-File -FilePath "$runs\$Name.before" -Encoding UTF8

# The brief goes in on stdin so multi-line quoting never has to survive a shell.
$inner = @"
Set-Location '$wt'
`$p = Get-Content -Raw '$brief'
`$p | codex exec -m $Model -c model_reasoning_effort='"$Effort"' ``
  --dangerously-bypass-approvals-and-sandbox -o '$out' - *> '$log'
`$LASTEXITCODE | Set-Content '$exit'
"@
$enc  = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
$proc = Start-Process pwsh -ArgumentList '-NoProfile','-EncodedCommand',$enc -WindowStyle Hidden -PassThru
Write-Output "$Name PID=$($proc.Id) worktree=$(Split-Path $wt -Leaf) model=$Model effort=$Effort"
