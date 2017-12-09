# Compact Hyper-V VHD(x)'s Script.
#
#	This Script was made with much love, patience and nerves by:
# 
#			Patrick Köhler
#
# Powershell Script zum automatischen compacten von Hyper-V VHD(x)s ohne Checkpoint.
# Dieses Script prüft automatisch welche virtuellen Maschinen Checkpoints haben, welche maschinen heruntergefahren sind und welche VM's derzeit laufen.
#
#
# Virtuelle Maschinen die den Status "Running" haben werden automatisch heruntergefahren und nach dem Compacten wieder hochgefahren.
# Virtuelle Maschinen die den Status "Offline" haben und keinen Checkpoint besitzen werden ohne weiteres compacted.
# Für virtuelle Maschinen die einen Checkpoint haben und aus diesem Grund die VHD nicht compacted werden können, erfolgt eine Meldung per E-Mail an das Konto welches unter der variable $EMailAddress eingetragen ist.
#
# Changelog:
# 10.11.2017 - Es wurde eine anpassung am Script vorgenommen, sodass gewisse VM's ausgenommen werden können. VM's mit einer Ausnahme werden nicht herunterfahren und compacted. 
# 15.11.2017 - Function VHDCompact erstellt.

# Ordner für Logfiles festlegen.
$TempPath = "C:\Temp\"
$LogFilePath = "C:\Temp\AutoCompact\"

# Ordner für Logfiles erstellen.
if(Test-Path $TempPath){
Write-Verbose "$TempPath existiert bereits."
}
else{
New-Item -Path "C:\" -Name "Temp" -ItemType directory
}
if(Test-Path $LogFilePath){
Write-Verbose "$LogFilePath existiert bereits."
}
else{
New-Item -Path "C:\Temp\" -Name "AutoCompact" -ItemType directory
}


# LOG File erstellen mit Datum im Temp Verzeichnis unter dem Unterordner AutoCompact.
$path = $LogFilePath
$date = get-date -format "yyyy-MM-dd-HH-mm"
$file = ("AutoCompact_" + $date + ".log")
$logfile = $path + "\" + $file

function Write-Log([string]$logtext, [int]$level=0)
{
	$logdate = get-date -format "yyyy-MM-dd HH:mm:ss"
	if($level -eq 0)
	{
		$logtext = "[INFO] " + $logtext
		$text = "["+$logdate+"] - " + $logtext
		Write-Host $text
	}
	if($level -eq 1)
	{
		$logtext = "[WARNING] " + $logtext
		$text = "["+$logdate+"] - " + $logtext
		Write-Host $text -ForegroundColor Yellow
	}
	if($level -eq 2)
	{
		$logtext = "[ERROR] " + $logtext
		$text = "["+$logdate+"] - " + $logtext
		Write-Host $text -ForegroundColor Red
	}
	$text >> $logfile
}

# Funktion zum Compacten der VHD(X)
function VHDCompact (){
	foreach($VHD in ((Get-VMHardDiskDrive -VMName $VM.Name).Path)){
		Write-Log "Arbeite an $VHD, bitte warten."
		Write-Log "Derzeitige VHD Größe beträgt: $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB."
		$VHDCurrentSize = $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB))
		Mount-VHD -Path $VHD -NoDriveLetter -ReadOnly
		Optimize-VHD -Path $VHD -Mode Full
		Write-Log "Optimierte VHD Größe beträgt: $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB."
		$VHDOptimizedSize = $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB))
		Dismount-VHD -Path $VHD
		$VHDSizeDelta = $VHDCurrentSize - $VHDOptimizedSize
		Write-Log "Auf der virtuellen Maschine $VMRealName wurden $VHDSizeDelta GB durch compacting freigeräumt."
		Write-Log ""
	}
}

# Hyper-V Modul für Powershell installieren.
Add-WindowsFeature Hyper-V-PowerShell

# SMTP-Mailserver für Email Versand setzen.
$PSEmailServer = "smtp.mailserver.com"

# Mail Adresse an die das Log sowie die Meldungen geschickt werden sollen
$EMailAddress = "reciever@mail.com"

# Variablen für Abfragen setzen.
#
# Alle VMs die Online sind und keinen Checkpoint haben.
$VMRestart = Get-VM | where {$_.state -eq "Running" -and $_.ParentCheckpointID -eq $null} 
# Alle VMs die Offline sind und keinen Checkpoint haben.
$VMOffline = Get-VM | where {$_.state -eq "off" -and $_.ParentCheckpointID -eq $null}
# Alle VMs die einen Checkpoint haben.
$VMCheckpoint = Get-VM | where ParentCheckPointID -NE $null
# Hostname des Hyper-V Hosts
$Hostname = Get-VMHost

# Emailversand für VM's mit Checkpoints.
if ($VMCheckpoint -eq $null){
	Write-Log "Keine virtuellen Maschinen mit Checkpoints gefunden, Email wurde deshalb nicht gesendet."
	Write-Log ""
}
else{
	Send-MailMessage -to "$EMailAddress" -from "AutoCompactScript <autocompact@mail.com>" -Subject "AutoCompact: Die virtuellen Maschinen auf dem Host: $env:computername haben Checkpoints." -body "$VMCheckpoint" -encoding ([System.Text.Encoding]::UTF8)
}

# Hyper-V Maschinen herunterfahren und VHD's Compacten die Status "Running" haben und keinen Checkpoint besitzen.
foreach( $VM in $VMRestart ){
	try{
		$VMRealName = $VM.Name
		# Ausnahmen für Server - Server die hier eingetragen werden, werden nicht Compacted.
		if($VM.Name -eq "DONT-COMPACT-SERVER-1" -or $VM.Name -eq "DONT-COMPACT-SERVER-2" -or $VM.Name -eq "DONT-COMPACT-SERVER-3" -or $VM.Name -eq "DONT-COMPACT-SERVER-4" -or $VM.Name -eq "DONT-COMPACT-SERVER-5"){
			Write-Log "$VMRealName wurde aufgrund einer Ausnahmeregel im Script nicht compacted."
		}
		else{
			$VMRealName = $VM.Name
			Stop-VM -Name $VM.Name
			Write-Log "Fahre virtuelle Maschine $VMRealName herunter."
			Write-Log ""
			if((Get-VM -Name $VM.Name).State -eq "off"){
				VHDCompact
				Start-VM -Name $VM.Name
				Write-Log "Fahre virtuelle Maschine $VMRealName wieder hoch."
				Write-Log ""
			}
			else{
				Write-Log "$VMRealName ist nicht ausgeschaltet oder hat einen Checkpoint. VHD wird nicht compacted." 2
				Write-Log ""        
			}
		}
	}
	catch{
	Write-Log "Ein Fehler bei virtueller Maschine $VMRealName ist augetreten." 2
	Write-Log "$_" 2
	Write-Log ""
	}
}


# Die VHDs der virtuellen Maschinen Compacten die bereits heruntergefahren sind und keinen Checkpoint besitzen.
foreach( $VM in $VMOffline ){
	try{
		$VMRealName = $VM.Name
		Write-Log "Virtuelle Maschine $VMRealName ist bereits heruntergefahren."
		Write-Log ""
		if((Get-VM -Name $VM.Name).State -eq "off"){
			VHDCompact
		}
		else{
			Write-Log "$VMRealName ist nicht ausgeschaltet oder hat einen Checkpoint. VHD wird nicht compacted." 2
			Write-Log ""        
		}
	}
	catch{
	Write-Log "Ein Fehler bei virtueller Maschine $VMRealName ist augetreten." 2
	Write-Log "$_" 2
	Write-Log ""
	}
}

# Logfile an Email senden.
Send-MailMessage -to "$EMailAddress" -from "AutoCompactScript <autocompact@mail.com>" -Subject "AutoCompact: Logfile für den Host: $env:computername" -body "Das Logfile für den Host: $env:computername befindet sich im Anhang." -Attachments $logfile -encoding ([System.Text.Encoding]::UTF8)

# Log Ordner bereinigen.
Remove-Item C:\Temp\AutoCompact\* -recurse
