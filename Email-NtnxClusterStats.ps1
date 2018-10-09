#Title:  Email-NtnxClusterStats.ps1
# Version 0.1 
#Author: Michael Nichols
#Caveat:  For illustrative purposes only, use at own risk
#Purpose:  Connects to an array of Nutanix Clusters, retrieves the current CPU and Memory % Usage
#             and appends values to a CSV file and mails



Function Send-ToEmail ([string]$email, [string]$attachmentpath){
  $message = New-Object Net.Mail.MailMessage
  $message.From "sender@email.com"
  $message.To.Add($email)
  $message.Subject = 'NTNX Clusters Cpu and Mem stats'
  $message.Body = 'Please find attached the latest Nutanix Cpu and Memory stats.  Open in Excel to view.'
  $attachment = New-Object Net.Mail.Attachment($attachmentpath)
  $message.Attachments.Add($attachment)

  $smtp = New-Object Net.Mail.SmtpClient("smtp.server.com","25")
  $smtp.send($message)

  $attachment.Dispose()
}

$ArrayNtxClusters = "cluster1", "cluster2", "cluster3"
$AdminName = 'adminuser'

# Create a secure string password - 
# note that I do not endorse storing passwords in scripts - 
# having the plaintext password below is for simplicity
$Password = 'P@ssW0rD!'
$Secure_String_Pwd = ConvertTo-SecureString $Password -AsPlainText -Force

Add-PSSnapIn NutanixCmdletsPSSnapin

$Results=@()
$OutputFile = '.\NtnxClustersCpuMemStats.csv'
$TimeStamp = Get-Date -UFormat %Y%m%d-%H%p
$ArrayNtxClusters | ForEach-Object {
  $ClusterStats=@{}
  Connect-NTNXCluster -Server $_ -UserName $AdminName -Password $Secure_String_Pwd -AcceptInvalidSSLCerts -ForcedConnection | Out-Null
  $Stats=Get-NTNXCluster -Server $_).stats
  $ClusterStats = New-Object PSObject -Property @{
    Time = $TimeStamp
    Cluster = $_
    CpuUsage = ([math]::round(($stats.hypervisor_esx_cpu_usage_ppm/10000),2))
    MemUsage = ([math]::round(($stats.hypervisor_esx_memory_usage_ppm/10000),2))
  }
 $Results+=$ClusterStats
}
$Results | ft
Start-Sleep 2
Read-Host -Prompt "Press any key to continue to append and email stats, or Ctrl+C to quit."
$Results | Export-Csv -append $OutputFile -notypeinformation
Send-ToEmail -email "recipient1@email.com,recipient2@email.com" -attachmentpath $OutputFile
Disconnect-NTNXCluster *

