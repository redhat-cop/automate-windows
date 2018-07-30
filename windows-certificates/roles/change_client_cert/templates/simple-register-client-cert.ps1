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
$password = "{{ win_cert_user_password }}"

$secure_password = ConvertTo-SecureString -String $password -AsPlainText -Force
Set-LocalUser -name $username -password $secure_password
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $secure_password

$thumbprint = $cert.Thumbprint

Get-ChildItem -Path WSMan:\localhost\ClientCertificate | Remove-Item -Recurse

New-Item -Path WSMan:\localhost\ClientCertificate `
    -Subject "$username@localhost" `
    -Credential $credential `
    -URI * `
    -Issuer $thumbprint `
    -Force

Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
