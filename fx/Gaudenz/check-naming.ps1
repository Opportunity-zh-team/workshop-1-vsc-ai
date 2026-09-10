[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot 'ScrDashboard.yaml')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$prefixRules = @{
    'Button' = 'Btn'
    'Checkbox' = 'Chk'
    'ComboBox' = 'Cmb'
    'Container' = 'Con'
    'DatePicker' = 'Dtp'
    'Dropdown' = 'Drp'
    'Gallery' = 'Gal'
    'GroupContainer' = 'Con'
    'HtmlText' = 'Html'
    'Icon' = 'Ico'
    'Label' = 'Lbl'
    'Rectangle' = 'Rec'
    'Screen' = 'Scr'
    'TextInput' = 'Txt'
    'Timer' = 'Tmr'
    'Toggle' = 'Tgl'
}

function Get-ControlType {
    param([string]$Value)

    $typeName = ($Value -replace '^Classic/', '') -replace '@.*$', ''
    return $typeName
}

function Test-PascalCase {
    param([string]$Name)

    return $Name -match '^[A-Z][A-Za-z0-9]*$'
}

function Add-Violation {
    param(
        [System.Collections.Generic.List[object]]$List,
        [string]$File,
        [int]$Line,
        [string]$Severity,
        [string]$Name,
        [string]$Message
    )

    $List.Add([pscustomobject]@{
        File = $File
        Line = $Line
        Severity = $Severity
        Name = $Name
        Message = $Message
    })
}

$files = @()
if (Test-Path -LiteralPath $Path -PathType Leaf) {
    $files = @(Get-Item -LiteralPath $Path)
}
elseif (Test-Path -LiteralPath $Path -PathType Container) {
    $files = @(Get-ChildItem -LiteralPath $Path -Filter '*.yaml' -File -Recurse)
}
else {
    throw "Path not found: $Path"
}

$violations = [System.Collections.Generic.List[object]]::new()
$allNames = @{}

foreach ($file in $files) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $relativeFile = $file.FullName
    $workspaceRoot = (Resolve-Path $PSScriptRoot).Path
    if ($relativeFile.StartsWith($workspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativeFile = $relativeFile.Substring($workspaceRoot.Length).TrimStart('\', '/')
    }

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $screenMatch = [regex]::Match($line, '^\s{2}([A-Za-z][A-Za-z0-9_]*)\:\s*$')
        if ($screenMatch.Success -and $index -gt 0 -and $lines[$index - 1] -match '^Screens:\s*$') {
            $screenName = $screenMatch.Groups[1].Value
            if (-not (Test-PascalCase $screenName)) {
                Add-Violation $violations $relativeFile ($index + 1) 'ERROR' $screenName 'Screen name must be PascalCase.'
            }
            elseif (-not $screenName.StartsWith('Scr')) {
                Add-Violation $violations $relativeFile ($index + 1) 'ERROR' $screenName 'Screen name must start with Scr.'
            }
        }

        $nameMatch = [regex]::Match($line, '^(\s*)-\s+([A-Za-z][A-Za-z0-9_]*)\:\s*$')
        if (-not $nameMatch.Success) {
            continue
        }

        $name = $nameMatch.Groups[2].Value
        $indent = $nameMatch.Groups[1].Value.Length
        $controlType = $null
        $controlLine = $index + 1

        while ($controlLine -lt $lines.Count) {
            $nextLine = $lines[$controlLine]
            if ([string]::IsNullOrWhiteSpace($nextLine)) {
                $controlLine++
                continue
            }

            $nextIndent = ($nextLine -replace '\S.*$', '').Length
            if ($nextIndent -le $indent) {
                break
            }

            $controlMatch = [regex]::Match($nextLine, '^\s+Control:\s+([^\s]+)')
            if ($controlMatch.Success) {
                $controlType = Get-ControlType $controlMatch.Groups[1].Value
                break
            }
            $controlLine++
        }

        if (-not $controlType -or -not $prefixRules.ContainsKey($controlType)) {
            continue
        }

        if ($allNames.ContainsKey($name)) {
            Add-Violation $violations $relativeFile ($index + 1) 'ERROR' $name "Duplicate name; first seen in $($allNames[$name])."
        }
        else {
            $allNames[$name] = "${relativeFile}:$($index + 1)"
        }

        $expectedPrefix = $prefixRules[$controlType]
        if (-not (Test-PascalCase $name)) {
            Add-Violation $violations $relativeFile ($index + 1) 'ERROR' $name 'Control name must be PascalCase.'
        }
        if (-not $name.StartsWith($expectedPrefix)) {
            Add-Violation $violations $relativeFile ($index + 1) 'ERROR' $name "Expected prefix '$expectedPrefix' for $controlType."
        }
    }
}

if ($violations.Count -eq 0) {
    Write-Host "Naming check passed: $($files.Count) YAML file(s) scanned."
    exit 0
}

Write-Host "Naming check failed: $($violations.Count) issue(s) found."
foreach ($violation in $violations | Sort-Object File, Line, Name) {
    Write-Host ("{0} {1}:{2} {3} - {4}" -f $violation.Severity, $violation.File, $violation.Line, $violation.Name, $violation.Message)
}
exit 1
