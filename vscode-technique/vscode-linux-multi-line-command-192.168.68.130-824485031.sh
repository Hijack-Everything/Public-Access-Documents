
$uuid="af32b3852342"
"${uuid}: running"
"af32b3852342: pauseLog"
$ProgressPreference='SilentlyContinue'
$r_='e3550cfac4b63ca4eafca7b601f0d2885817fd1f'
$p=$env:PROCESSOR_ARCHITECTURE
$arch=''
if ($p -eq 'AMD64' -or $p -eq 'IA64') {
$arch='x64'
} elseif ($p -eq 'ARM64') {
$arch='arm64'
}

if ($arch -eq '') {
"Unsupported architecture '$p'."
q 196
}

if ('' -ne '') {
$env:http_proxy = ''
}

if ('' -ne '') {
$env:https_proxy = ''
}

$s_=(Join-Path (Resolve-Path ~) '.vscode-server')
$cliDataDir=(Join-Path "$s_" 'cli')
$env:VSCODE_AGENT_FOLDER=$s_
$log=New-TemporaryFile
$c_="code"
$d_="$c_.exe"
$e_="$c_-$r_.exe"
$f_="$s_\$e_"
$t_='stable'
$k_=$True
$l_=$False
$global:v_ = $False
$global:w_ = ''
$global:n_ = ''
$global:o_ = ''
$global:p_ = ''
$global:q_ = ''
function ak_ {
"listeningOn==$port=="
"osReleaseId==windows=="
"osVersion==$ai_=="
"arch==$arch=="
"platform==windows=="
"unpackResult==$w_=="
"didLocalDownload==$v_=="
"downloadTime==$n_=="
"installTime==$o_=="
"extInstallTime==$p_=="
"serverStartTime==$q_=="
"execServerToken==405980a4-7ae4-40f6-b1be-d191a4544c30=="
}

function m_ {
return [system.diagnostics.stopwatch]::StartNew();
}

function q($code) {
"${uuid}: start"
"exitCode==$code=="
ak_
"${uuid}: end"
}

function a_ {
$x_=$PID
while ($True) {
$y_=(gcim win32_process | ? processid -eq $x_).parentprocessid
if (!$y_) {
"no sshd parent proc"
exit 0
}

if ((gps -Id $y_).Name -eq 'sshd') {
return $y_
}

$x_=$y_
}

}

function b_ {
if ($launchedCli1Pid) {
if (!(gps -Id $z_)) {
"server died, exit"
exit 0
}

} else {
if (!(gps -Id $sshdPID)) {
"sshd parent died, exit"
exit 0
}

}

}

function GetArtifactName {
"cli-win32-$arch"
}

function g_ {
$s=m_
"Downloading cli $arch"
"${uuid}%%1%%"
$an=GetArtifactName
$splat=@{
Uri="https://update.code.visualstudio.com/commit:$r_/$an/$t_"
TimeoutSec=20
OutFile="vscode-cli-$r_.zip"
UseBasicParsing=$True
}

[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
irm @splat
$s.Stop()
$global:n_ = $s.ElapsedMilliseconds
}

function h_ {
$global:w_='success'
$s=m_
try {
$ac_=[System.IO.Path]::GetRandomFileName()
$ad_="$env:TEMP\$ac_"
"Expanding cli into $ad_"
"${uuid}%%2%%"
Expand-Archive "vscode-cli-$r_.zip" -DestinationPath "$ad_"
cp "$ad_\$d_" -Destination $f_
del -Recurse $ad_
del "vscode-cli-$r_.zip"
$s.Stop()
$global:o_ = $s.ElapsedMilliseconds
} catch {
$global:w_='error'
"Failed to unzip cli. - $($_.ToString())"
j_ 205
h_
}

if(!(Test-Path "$f_")) {
$global:w_='missingFiles'
"Downloaded server is incomplete."
j_ 205
h_
}

}

function aj_ {
$s=m_
if(Test-Path $log) {
del $log
}

$escapedCliFile=$f_ -replace ' ', '` '
$args="command-shell --cli-data-dir '$cliDataDir' --parent-process-id $sshdPID --on-host 127.0.0.1 --on-port --require-token 405980a4-7ae4-40f6-b1be-d191a4544c30 *> '$log'"
$splat=@{
FilePath = "powershell.exe"
WindowStyle = "hidden"
ArgumentList = @(
"-ExecutionPolicy", "Unrestricted", "-NoLogo", "-NoProfile", "-NonInteractive", "-c", "$escapedCliFile $args"
)
PassThru = $True
}

"Starting cli: & '$f_' $args"
$global:z_ = (start @splat).ID
$s.Stop()
$global:q_ = $s.ElapsedMilliseconds
}

function i_ {
$global:v_=$True
"Trigger local server download"
$an=GetArtifactName
"${uuid}:trigger_server_download"
"artifact==$an=="
"destFolder==$s_=="
"destFolder2==/vscode-cli-$r_.zip=="
"${uuid}:trigger_server_download_end"
"Waiting for client to transfer server archive..."
"Waiting for $s_\vscode-cli-$r_.zip.done and vscode-cli-$r_.zip to exist"
while($True) {
if(Test-Path "$s_\vscode-cli-$r_.zip.done") {
if(!(Test-Path "$s_\vscode-cli-$r_.zip")) {
"Transfer failed"
q 199
}

"Transfer complete"
del $s_\vscode-cli-$r_.zip.done
break
} else {
Start-Sleep -Seconds 3
b_
}

}

}

function j_($code) {
if ($v_) {
"Already attempted local download, failing"
q $code
} elseif($k_) {
i_
} else {
q $code
}

}

function printResult() {
"${uuid}: start"
"SSH_AUTH_SOCK==$env:SSH_AUTH_SOCK=="
ak_
"${uuid}: end"
}

function main() {
$global:sshdPID = a_
if(!(Test-Path $s_)) {
$m="Could not create CLI directory"
try {
$null=ni -it d $s_ -f -ea si
} catch {
"$m. - $($_.ToString())"
return
}

if(!(Test-Path $s_)) {
"$m"
return
}

}

cd $s_
try {
"Looking for existing CLI in $s_"
if(Test-Path "$f_") {
"Found installed CLI"
} else {
if ($l_) {
i_
} else {
try { g_ } catch {
"Download failed. - $($_.ToString())"
j_ 193
}

}

h_
}

aj_
$ag_=@{
Path = $log
Pattern = "Listening on .*?:([0-9]+)$"
}

$af_=(Get-Date).AddSeconds(4)
$al_="Server did not start successfully. Full server log at $log >>>"
while ((Get-Date) -lt $af_) {
if(Test-Path $log) {
$ah_=(sls @ag_).Matches.Groups
if($ah_) {
$global:port = $ah_[1].Value
break
}

}

sleep -Milliseconds 30
}

if (!$port) {
$al_
cat $log
"<<< End of server log"
q 200
}

} catch {
"Server failed to start. - $($_.ToString())"
"$($_.ScriptStackTrace)"
}

try {
$global:ai_ = (gcim Win32_OperatingSystem).Version
} catch {
"Failed to find Windows version - $($_.ToString())"
$global:ai_ = "unknown"
}

printResult
"$pid, watching $sshdPID"
while ($True) {
b_
sleep 30
}

}

"af32b3852342: resumeLog"
main
