$SubjectName = "{{ansible_host }}"
{% if mail_server is defined and mail_server %}
$mail_sender="{{ mail_sender }}"
$mail_recipient="{{ mail_recipient }}"
$mail_server="{{ mail_server }}"
{% endif %}


# Reset variables if script ran previously in the same session
$oldThumbprint = ""
$cert = ""

$cert = Import-PfxCertificate -FilePath {{remote_certs_dir}}\server.pfx -CertStoreLocation Cert:\LocalMachine\My -Exportable

$thumbprint = $cert.Thumbprint

echo "New SubjectName: $SubjectName"
echo "New ThumbPrint: $thumbprint"

$valueset = @{
     CertificateThumbprint = $thumbprint
     Hostname = $SubjectName
}

# Delete the listener for SSL
$selectorset = @{
     Address = "*"
     Transport = "HTTPS"
}

Start-Sleep -s 30 

$httpsListener = Get-ChildItem WSMan:\localhost\Listener | Where {$_.Keys -like "TRANSPORT=HTTPS"}
If ($httpsListener)
{
   $oldThumbprint = Get-ChildItem -Path $httpsListener.PSPath | Where  Name -EQ "CertificateThumbprint"
   $oldThumbprint = $oldThumbprint.Value
   echo "Removing Old ThumbPrint: $oldThumbprint"
   Remove-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset
}

# Add new Listener with new SSL cert
New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset -ValueSet $valueset
if($?) {
    echo "Successfully installed new ThumbPrint: $thumbprint"
{% if mail_server is defined and mail_server %}
    $mail_subject="Ansible: Change_Server_Cert: Success on adding server certificate to WinRM on $env:computername, ThumbPrint: $thumbprint"
    $mail_body=$mail_subject
{% endif %}
} else {
    echo "Failed to install new ThumbPrint: $thumbprint"
    if($oldThumbprint) {
        echo "Restoring old ThumbPrint: $oldThumbprint"
        $valueset = @{
             CertificateThumbprint = $oldThumbprint
             Hostname = $SubjectName
        }
        New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset -ValueSet $valueset    
{% if mail_server is defined and mail_server %}
        $mail_subject="Ansible: Change_Server_Cert: Error on adding server certificate to WinRM on $env:computername, ThumbPrint: $thumbprint, Restoring old Thumbprint: $oldThumbprint"
{% endif %}
    } else {
        echo "Can not restore previous ThumbPrint, since no HTTPS Listener was configured"
{% if mail_server is defined and mail_server %}
        $mail_subject="Ansible: Change_Server_Cert: Error on adding server certificate to WinRM on $env:computername, ThumbPrint: $thumbprint, no old thumbprint to restore"
{% endif %}
    }
{% if mail_server is defined and mail_server %}
    $mail_body=$error[0]
{% endif %}
}

{% if mail_server is defined and mail_server %}
Send-MailMessage -To $mail_recipient -From $mail_sender -Subject $mail_subject -SmtpServer $mail_server -Body $mail_body
{% endif %}

