Function New-RandomComplexPassword ($length=16)
{
    $Assembly = Add-Type -AssemblyName System.Web
    $random_password = [System.Web.Security.Membership]::GeneratePassword($length,6)
    return $random_password
}

{% if mail_server is defined and mail_server %}
$mail_sender="{{ mail_sender }}"
$mail_recipient="{{ mail_recipient }}"
$mail_server="{{ mail_server }}"
{% endif %}

$cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import("{{remote_certs_dir}}\openssl_cert.pem")

$store_name = [System.Security.Cryptography.X509Certificates.StoreName]::Root
$store_location = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
$store = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList $store_name, $store_location
$store.Open("MaxAllowed")
$store.Add($cert)
$store.Close()

$store_name = [System.Security.Cryptography.X509Certificates.StoreName]::TrustedPeople
$store_location = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
$store = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList $store_name, $store_location
$store.Open("MaxAllowed")
$store.Add($cert)
$store.Close()

Start-Sleep -s 30

$username = "{{ win_cert_user_name }}"
{% if win_scramble_password %}
$password = New-RandomComplexPassword(16)
{% else %}
$password = "{{ win_cert_user_password }}"
{% endif %}

$secure_password = ConvertTo-SecureString -String $password -AsPlainText -Force
Set-LocalUser -name $username -password $secure_password
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $secure_password

$thumbprint = $cert.Thumbprint

New-Item -Path WSMan:\localhost\ClientCertificate `
    -Subject "$username@localhost" `
    -Credential $credential `
    -URI * `
    -Issuer $thumbprint `
    -Force

if($?){
  $items=Get-ChildItem -Path WSMan:\localhost\ClientCertificate
  foreach($item in $items) {
    if($item.Keys -match $thumbprint) {
      echo "did not delete $item"
    } else {
      $item | Remove-Item -Recurse 
      echo "deleted item $item"
    } 
{% if mail_server is defined and mail_server %}
    $mail_subject="Ansible: Change_Client_Cert: Success on adding client certificate to WinRM on $env:computername"
    $mail_body=$mail_subject
{% endif %}
  }
{% if mail_server is defined and mail_server %}
} else {
    if($error[0] -match "The WS-Management service cannot create the resource because it already exists") {
      $mail_subject="Ansible: Change_Client_Cert: Warning on adding client certificate to WinRM on $env:computername"
    } else { 
      $mail_subject="Ansible: Change_Client_Cert: Error on adding client certificate to WinRM on $env:computername"
    } 
    $mail_body=$error[0]
{% endif %}
}

{% if mail_server is defined and mail_server %}
Send-MailMessage -To $mail_recipient -From $mail_sender -Subject $mail_subject -SmtpServer $mail_server -Body $mail_body
{% endif %}


Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true

