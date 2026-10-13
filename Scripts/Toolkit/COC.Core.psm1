Set-StrictMode -Version Latest

function Assert-CocUsb {
    param([Parameter(Mandatory)][string]$Root)
    $full = [IO.Path]::GetFullPath($Root)
    if ($full -notmatch '^[A-Za-z]:\\$') { throw 'USB volume root required.' }
    $letter = $full.Substring(0,1)
    $disk = Get-Partition -DriveLetter $letter -ErrorAction Stop | Get-Disk -ErrorAction Stop
    $volume = Get-Volume -DriveLetter $letter -ErrorAction Stop
    if ($disk.FriendlyName -ne 'Lexar USB Flash Drive' -or $disk.BusType -ne 'USB' -or
        $disk.SerialNumber.Trim() -ne 'CONFIGURE_USB_SERIAL' -or $disk.PartitionStyle -ne 'MBR' -or
        $volume.FileSystemLabel -ne 'COC_USB_1' -or $volume.FileSystem -ne 'exFAT' -or
        $disk.Size -ne 61865984000) { throw 'USB identity mismatch. No operation authorized.' }
    $null = Assert-CocPath -Root $full -Path $full
    $volume
}

function Assert-CocPath {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Path)
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.TrimEnd('\') -ne $base.TrimEnd('\') -and
        -not $full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw 'Path outside permitted root.' }
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point refused: $cursor" }
        }
        if ($cursor.TrimEnd('\') -eq $base.TrimEnd('\')) { break }
        $parent = Split-Path -Path $cursor -Parent
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    $full
}

function New-CocSession {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][ValidateSet('Diagnostics','Network','Hardware','Repair','Migration')][string]$Category)
    $volume = Assert-CocUsb $Root
    if($volume.SizeRemaining -lt (15GB+100MB)){throw 'USB reserve/headroom below requirement. Keep 15 GB free plus 100 MB collection headroom.'}
    $parent = Join-Path $Root 'Reports\COC-Managed'
    $null = Assert-CocPath -Root $Root -Path $parent
    $path = Join-Path $parent ('COC-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $path -ErrorAction Stop
    @{Schema=1;Generator='COC-Functional-Update';State='Active';Computer=$env:COMPUTERNAME;Category=$Category;Started=(Get-Date).ToString('o');Files=@()} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $path '.coc-session.json') -Encoding UTF8
    [pscustomobject]@{Path=$path;Category=$Category;Started=(Get-Date).ToString('o')}
}

function Complete-CocSession {
    param([Parameter(Mandatory)]$Session)
    $files = @(Get-ChildItem -LiteralPath $Session.Path -File | Where-Object Name -ne '.coc-session.json' | ForEach-Object {
        [pscustomobject]@{Name=$_.Name;Length=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    [ordered]@{Schema=1;Generator='COC-Functional-Update';State='Completed';Computer=$env:COMPUTERNAME;Category=$Session.Category;Started=$Session.Started;Completed=(Get-Date).ToString('o');Files=$files} |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $Session.Path '.coc-session.json') -Encoding UTF8
}

function Get-CocCleanupCandidates {
    param([Parameter(Mandatory)][string]$Root,[switch]$IncludeMetadata)
    $registry=Join-Path $Root 'Documentation\legacy-report-ownership.csv'
    $legacyHold=Join-Path $Root 'Reports\COC-Retention-Holds\legacy.hold'
    $null=Assert-CocPath -Root $Root -Path $registry
    $null=Assert-CocPath -Root $Root -Path $legacyHold
    if((Test-Path -LiteralPath $registry -PathType Leaf) -and -not(Test-Path -LiteralPath $legacyHold)){
        foreach($entry in Import-Csv -LiteralPath $registry){
            if($entry.Path -notmatch '^Reports\\(?:Network\\(?:Connectivity|DHCP|DNS|Firewall|Network|WiFi)-[A-Za-z0-9_-]+-\d{8}-\d{6}\.txt|Health-[A-Za-z0-9_-]+-\d{8}-\d{6}\.txt|COC-Auto-\d{8}-\d{6}-[a-f0-9]{8}\\(?:Details\.json|Summary\.txt)|Drivers-[A-Za-z0-9_-]+-\d{8}-\d{6}\\(?:Device-Problems\.csv|Installed-Drivers\.csv|Summary\.txt))$'){continue}
            try{
                $path=Join-Path $Root $entry.Path;$null=Assert-CocPath -Root (Join-Path $Root 'Reports') -Path $path
                if(-not(Test-Path -LiteralPath $path -PathType Leaf)){continue}
                $item=Get-Item -LiteralPath $path
                if($item.Length -ne [long]$entry.Bytes -or (Get-FileHash -LiteralPath $path -ErrorAction Stop).Hash -ne $entry.SHA256){continue}
                [pscustomobject]@{Path=$path;Session=$entry.Session;Computer=$entry.Computer;Category=$entry.Category;Created=$entry.Created;Bytes=$item.Length;SHA256=$entry.SHA256}
            }catch{Write-Warning ('Skipped legacy report: '+$_.Exception.Message)}
        }
    }
    $parent = Join-Path $Root 'Reports\COC-Managed'
    $null = Assert-CocPath -Root $Root -Path $parent
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { return }
    $allowed = @('system.txt','storage.txt','network.txt','security.txt','enterprise.txt','events.txt','result.txt','migration-preview.txt','migration-copy.txt','baseline.json','case-index.csv','comparison.csv','handover.md','tool-inventory.csv','integrity.csv','storage-health.txt','temporary.txt','activation.txt','drivers.txt','printers.txt','certificates.txt','permissions.txt','tasks.txt','services.txt','crash-dumps.txt','firewall.csv','tls.txt','bitlocker.txt','check-status.csv','collector-error.txt','Session.txt','Summary.txt','Details.json','Battery-Report.html','Battery-Summary.txt','Installed-Drivers.csv','Device-Problems.csv','PerfView.etl','Procmon.pml','CrashDump.dmp')
    foreach ($dir in Get-ChildItem -LiteralPath $parent -Directory -Force) {
        if ($dir.Name -notmatch '^COC-\d{8}-\d{6}-[a-f0-9]{32}$') { continue }
        try {
            $null = Assert-CocPath -Root $parent -Path $dir.FullName
            $marker = Join-Path $dir.FullName '.coc-session.json'
            $null = Assert-CocPath -Root $parent -Path $marker
            if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { continue }
            $data = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($data.Schema -ne 1 -or $data.Generator -ne 'COC-Functional-Update' -or $data.Category -notin @('Diagnostics','Network','Hardware','Repair','Migration')) { continue }
            if($data.PSObject.Properties.Name -notcontains 'State' -or $data.State -ne 'Completed' -or (Test-Path -LiteralPath (Join-Path $dir.FullName '.coc-hold'))){continue}
            $verified=0
            foreach ($entry in $data.Files) {
                if (($entry.Name -notin $allowed -and $entry.Name -notmatch '^(?:0[1-6]-(?:System|Memory|Storage|Battery|Device-Problems|Recent-Errors)(?:-ERROR)?|(?:Network|WiFi|DHCP|DNS|Connectivity|Firewall)-[A-Za-z0-9_-]+-\d{8}-\d{6})\.txt$') -or $entry.SHA256 -notmatch '^[0-9A-Fa-f]{64}$') { continue }
                $path = Join-Path $dir.FullName $entry.Name
                $null = Assert-CocPath -Root $parent -Path $path
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
                $file = Get-Item -LiteralPath $path -Force
                if ($file.Length -ne $entry.Length -or (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -ne $entry.SHA256) { continue }
                $verified++
                [pscustomobject]@{Path=$path;Session=$dir.Name;Computer=$data.Computer;Category=if($entry.Name -in @('temporary.txt','PerfView.etl','Procmon.pml','CrashDump.dmp')){'Temporary'}else{$data.Category};Created=$data.Started;Bytes=$file.Length;SHA256=$entry.SHA256}
            }
            if($IncludeMetadata){
                $actual=@(Get-ChildItem -LiteralPath $dir.FullName -File -Force|Where-Object Name -ne '.coc-session.json')
                $subfolders=@(Get-ChildItem -LiteralPath $dir.FullName -Directory -Force)
                if($verified -eq $actual.Count -and -not $subfolders.Count){
                    $meta=Get-Item -LiteralPath $marker -Force
                    [pscustomobject]@{Path=$marker;Session=$dir.Name;Computer=$data.Computer;Category=$data.Category;Created=$data.Started;Bytes=$meta.Length;SHA256=(Get-FileHash -LiteralPath $marker -ErrorAction Stop).Hash}
                }
            }
        } catch { Write-Warning "Skipped unsafe or invalid session $($dir.Name): $($_.Exception.Message)" }
    }
}

function Remove-CocReport {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)]$Candidate)
    $current = @(Get-CocCleanupCandidates $Root -IncludeMetadata | Where-Object { $_.Path -eq $Candidate.Path -and $_.SHA256 -eq $Candidate.SHA256 })
    if ($current.Count -ne 1) { throw 'Report no longer matches the approved preview.' }
    $null = Assert-CocPath -Root (Join-Path $Root 'Reports') -Path $Candidate.Path
    if((Split-Path $Candidate.Path -Leaf) -eq '.coc-session.json'){
        $remaining=@(Get-ChildItem -LiteralPath (Split-Path $Candidate.Path -Parent) -Force|Where-Object Name -ne '.coc-session.json')
        if($remaining.Count){throw 'Session metadata is protected until all approved payload files have been deleted.'}
    }
    if ($PSCmdlet.ShouldProcess($Candidate.Path,'Delete verified toolkit report file')) {
        Remove-Item -LiteralPath $Candidate.Path -Force -ErrorAction Stop
    }
}

function Select-CocCleanupCandidate {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Candidates,[string]$Selection)
    if([string]::IsNullOrWhiteSpace($Selection)){return}
    if($Selection -ceq 'ALL'){return $Candidates}
    if($Selection -match '^SESSION=([A-Za-z0-9_-]+)$'){return @($Candidates|Where-Object Session -eq $Matches[1])}
    if($Selection -match '^CATEGORY=(Network|Hardware|Diagnostics|Repair|Migration|Temporary)$'){return @($Candidates|Where-Object Category -eq $Matches[1])}
    if($Selection -notmatch '^\s*\d+(\s*,\s*\d+)*\s*$'){throw 'Invalid selection. No deletion performed.'}
    $indices=@($Selection.Split(',')|ForEach-Object{[int]$_.Trim()}|Sort-Object -Unique)
    foreach($index in $indices){if($index -lt 1 -or $index -gt $Candidates.Count){throw 'Selection outside preview.'}}
    @($indices|ForEach-Object{$Candidates[$_-1]})
}

function Protect-CocReportText {
    param([AllowEmptyString()][string]$Text)
    $Text=[regex]::Replace($Text,'(?<!\d)(?:\d{6}-){7}\d{6}(?!\d)','[REDACTED RECOVERY SECRET]')
    [regex]::Replace($Text,'(?im)\b(password|passwd|pwd|token|api[-_]?key|recoverypassword)\s*[:=]\s*[^\r\n;]+','$1=[REDACTED]')
}

function Get-CocReportDestination {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Path)
    $null=Assert-CocUsb $Root
    $managed=Join-Path $Root 'Reports\COC-Managed'
    $full=Assert-CocPath -Root $managed -Path $Path
    if((Split-Path $full -Leaf) -notmatch '^COC-\d{8}-\d{6}-[a-f0-9]{32}$'){throw 'Managed session directory required.'}
    $marker=Join-Path $full '.coc-session.json';$null=Assert-CocPath -Root $managed -Path $marker
    $data=Get-Content -LiteralPath $marker -Raw|ConvertFrom-Json
    if($data.Generator -ne 'COC-Functional-Update' -or $data.State -ne 'Active' -or $data.Computer -ne $env:COMPUTERNAME){throw 'Active session for this computer required.'}
    $full
}

function Invoke-CocCleanupBatch {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][object[]]$Candidates,[Parameter(Mandatory)][AllowEmptyString()][string]$Confirmation)
    $phrase='DELETE '+$Candidates.Count+' COC REPORT FILES'
    if($Confirmation -cne $phrase){return [pscustomobject]@{Cancelled=$true;DeletedBytes=0L;Failures=0;Results=@()}}
    $recovered=0L;$failures=0;$results=New-Object 'System.Collections.Generic.List[object]'
    foreach($file in $Candidates){
        try{$null=Assert-CocUsb $Root;Remove-CocReport -Root $Root -Candidate $file -Confirm:$false;$recovered+=$file.Bytes;$results.Add([pscustomobject]@{Path=$file.Path;Result='PASS';Detail='Deleted verified report'})}
        catch{$failures++;$results.Add([pscustomobject]@{Path=$file.Path;Result='FAIL';Detail=$_.Exception.Message})}
    }
    [pscustomobject]@{Cancelled=$false;DeletedBytes=$recovered;Failures=$failures;Results=$results.ToArray()}
}

Export-ModuleMember -Function Assert-CocUsb,Assert-CocPath,New-CocSession,Complete-CocSession,Get-CocCleanupCandidates,Remove-CocReport,Select-CocCleanupCandidate,Invoke-CocCleanupBatch,Protect-CocReportText,Get-CocReportDestination




