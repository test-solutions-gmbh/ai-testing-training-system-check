# AI testing training: system check for Windows.
# Read-only. Installs nothing, changes no settings, sends no personal data.
# Run:   powershell -NoProfile -ExecutionPolicy Bypass -File .\check.ps1
# If script execution is blocked by policy:
#        Get-Content .\check.ps1 -Raw | Invoke-Expression

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$sysProxy = [System.Net.WebRequest]::GetSystemWebProxy()
$sysProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$publicCa = "Let's Encrypt|DigiCert|Google Trust|Sectigo|GlobalSign|Amazon|Cloudflare|Baltimore|Microsoft|Entrust|GoDaddy|USERTrust|Comodo|ISRG|Fastly|Certainly"
$out = New-Object System.Collections.Generic.List[string]
function Say([string]$line) { $out.Add($line); Write-Host $line }

function Test-Url([string]$name, [string]$url, [bool]$wantJson) {
    $uri = [Uri]$url
    $via = $sysProxy.GetProxy($uri)
    $route = if ($via.AbsoluteUri -eq $uri.AbsoluteUri) { 'direct' } else { "proxy $($via.Authority)" }
    $status = $null; $body = ''; $err = $null; $issuer = ''
    $req = [System.Net.HttpWebRequest]::Create($uri)
    $req.Proxy = $sysProxy
    $req.Timeout = 15000
    $req.UserAgent = 'training-system-check/1.0'
    try {
        $resp = $req.GetResponse()
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if (-not $resp) { $err = $_.Exception.Message }
    }
    if ($req.ServicePoint.Certificate) { $issuer = $req.ServicePoint.Certificate.Issuer }
    if ($resp) {
        $status = [int]$resp.StatusCode
        try { $body = (New-Object IO.StreamReader($resp.GetResponseStream())).ReadToEnd() } catch {}
        $resp.Close()
    }
    $isJson = $body.TrimStart().StartsWith('{') -or $body.TrimStart().StartsWith('[')
    if ($err) { $verdict = 'FAIL' ; $detail = $err }
    elseif ($status -eq 407) { $verdict = 'BLOCKED'; $detail = 'HTTP 407 (proxy wants authentication)' }
    elseif ($status -eq 403 -and -not ($wantJson -and $isJson)) { $verdict = 'BLOCKED'; $detail = 'HTTP 403 (proxy or firewall)' }
    elseif ($wantJson -and -not $isJson) { $verdict = 'BLOCKED?'; $detail = "HTTP $status, not the expected API answer (block page?)" }
    elseif ($status -ge 500) { $verdict = 'FAIL'; $detail = "HTTP $status" }
    else { $verdict = 'OK'; $detail = "HTTP $status" }
    $tls = ''
    if ($issuer) {
        $cn = ($issuer -split ',')[0..1] -join ','
        if ($issuer -notmatch $publicCa) { $tls = " | TLS INSPECTED? issuer: $cn" } else { $tls = " | issuer: $cn" }
    }
    Say ("{0,-9} {1,-28} {2} | {3}{4}" -f $verdict, $name, $detail, $route, $tls)
}

function Tool([string]$name, [string]$cmd, [string]$arg) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $c) { Say ("{0,-9} {1,-28} not installed" -f '-', $name); return }
    if ($c.Source -like '*WindowsApps*') { Say ("{0,-9} {1,-28} only the Microsoft Store alias, not a real install" -f '-', $name); return }
    $v = (& $cmd $arg 2>&1 | Select-Object -First 1) -as [string]
    Say ("{0,-9} {1,-28} {2} ({3})" -f 'FOUND', $name, $v.Trim(), $c.Source)
}

Say "=== AI testing training: system check (Windows) ==="
Say ("Date: {0}  |  Windows: {1}  |  PowerShell: {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), [Environment]::OSVersion.Version, $PSVersionTable.PSVersion)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Say ("Admin session: {0}" -f $isAdmin)
Say ""
Say "--- 1. Model providers (any HTTP answer from the API means reachable; 401 is fine) ---"
Test-Url 'OpenAI API'            'https://api.openai.com/v1/models' $true
Test-Url 'Anthropic API'         'https://api.anthropic.com/v1/models' $true
Test-Url 'Google Gemini API'     'https://generativelanguage.googleapis.com/v1beta/models' $true
Say ""
Say "--- 2. Package sources (needed to install promptfoo and the harness) ---"
Test-Url 'npm registry'          'https://registry.npmjs.org/promptfoo' $true
Test-Url 'PyPI index'            'https://pypi.org/simple/streamlit/' $false
Test-Url 'PyPI files'            'https://files.pythonhosted.org/' $false
Test-Url 'nodejs.org'            'https://nodejs.org/dist/index.json' $true
Test-Url 'python.org'            'https://www.python.org/ftp/python/' $false
Test-Url 'astral.sh (uv)'        'https://astral.sh/uv/install.ps1' $false
Test-Url 'GitHub'                'https://github.com/' $false
Say ""
Say "--- 3. Installed tools ---"
Tool 'Node'    'node'   '--version'
Tool 'npm'     'npm'    '--version'
Tool 'Python'  'python' '--version'
Tool 'py launcher' 'py' '--version'
Tool 'uv'      'uv'     '--version'
Tool 'git'     'git'    '--version'
Say ""
Say "--- 4. Proxy configuration ---"
$orUri = [Uri]'https://api.openai.com/'
$orVia = $sysProxy.GetProxy($orUri)
if ($orVia.AbsoluteUri -eq $orUri.AbsoluteUri) { Say 'System proxy for api.openai.com: none (direct)' } else { Say ("System proxy for api.openai.com: {0}" -f $orVia.Authority) }
foreach ($v in 'HTTPS_PROXY','HTTP_PROXY','NO_PROXY','NODE_EXTRA_CA_CERTS','SSL_CERT_FILE','REQUESTS_CA_BUNDLE') {
    $val = [Environment]::GetEnvironmentVariable($v)
    if ($val) { Say ("env {0} = {1}" -f $v, $val) }
}
$winhttp = (netsh winhttp show proxy 2>&1 | Where-Object { $_ -match '\S' } | Select-Object -Last 2) -join ' '
Say ("WinHTTP: {0}" -f $winhttp.Trim())
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Say ("npm https-proxy: {0} | npm cafile: {1}" -f (npm config get https-proxy 2>$null), (npm config get cafile 2>$null))
}
Say ""
Say "--- 5. Same check from inside the tools (they do not always use the system proxy) ---"
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $r = (npm view promptfoo@0.124.1 version 2>&1 | Select-Object -Last 1) -as [string]
    if ($r -match '^\s*0\.124\.1\s*$') { Say "OK        npm can reach its registry" } else { Say ("FAIL      npm cannot reach its registry: {0}" -f $r.Trim()) }
}
$py = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike '*WindowsApps*' } | Select-Object -First 1
if ($py) {
    $r = (& python -c "import urllib.request as u;print(u.urlopen('https://pypi.org/simple/streamlit/',timeout=15).status)" 2>&1 | Select-Object -Last 1) -as [string]
    if ($r -match '^\s*200\s*$') { Say "OK        Python can reach PyPI" } else { Say ("FAIL      Python cannot reach PyPI: {0}" -f $r.Trim()) }
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue) -and -not $py) { Say "skipped   (neither Node nor Python installed)" }
Say ""
Say "=== end ==="
$file = Join-Path (Get-Location) 'system-check-result.txt'
try { $out | Set-Content -Path $file -Encoding UTF8; Write-Host "Saved to $file" } catch {}
try { ($out -join "`r`n") | Set-Clipboard; Write-Host "Copied to clipboard: paste it into the Teams chat." } catch {}
