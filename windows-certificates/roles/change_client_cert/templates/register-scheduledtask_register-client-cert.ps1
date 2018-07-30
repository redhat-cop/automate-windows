$Time = New-ScheduledTaskTrigger -At 12:00 -Once 
$User = "SYSTEM"
$STPrin = New-ScheduledTaskPrincipal -UserId $User -LogonType ServiceAccount
$PS = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument "-NonInteractive -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\admin\register-client-cert.ps1"
$TaskName = "register-client-cert"
Register-ScheduledTask -TaskName $TaskName -Trigger $Time -Action $PS -Principal $STPrin
Start-ScheduledTask -TaskName $TaskName
