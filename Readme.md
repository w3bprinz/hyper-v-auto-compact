# Compact Hyper-V VHD(x)'s Script.

This Script was made with much love, patience and nerves by:

Patrick Köhler

# Beschreibung / Funktionsweise:
Powershell Script zum automatischen compacten von Hyper-V VHD(x)s ohne Checkpoint.
Dieses Script prüft automatisch welche virtuellen Maschinen Checkpoints haben, welche maschinen heruntergefahren sind und welche VM's derzeit laufen.


Virtuelle Maschinen die den Status "Running" haben werden automatisch heruntergefahren und nach dem Compacten wieder hochgefahren.
Virtuelle Maschinen die den Status "Offline" haben und keinen Checkpoint besitzen werden ohne weiteres compacted.
Für virtuelle Maschinen die einen Checkpoint haben und aus diesem Grund die VHD nicht compacted werden können, erfolgt eine Meldung per E-Mail an das Konto welches unter der variable $EMailAddress eingetragen ist.

Für den Mailversand bitte diese beiden Zeilen im Script anpassen:

      # SMTP-Mailserver für Email Versand setzen.
      $PSEmailServer = "smtp.mailserver.com"

      # Mail Adresse an die das Log sowie die Meldungen geschickt werden sollen
      $EMailAddress = "reciever@mail.com"

Weiterhin kann man im Skript selbst ausnahmen für einige Server hinzufügen welche nicht compactet werden sollen oder dürfen, diese müssen ebenfalls im Script angegeben werden. Im folgenden Skript Auszug ist zu sehen das dort "DONT-COMPACT-SERVER1" bis "DONT-COMPACT-SERVER5" vorhanden sind, dies sind die "Servernamen" der jeweiligen Server die durch dieses Script nicht angefasst werden sollen. Diese Ausnahmen wirken sich jedoch lediglich auf virtuelle Hyper-V Maschinen aus die den Status "running" haben.

      # Hyper-V Maschinen herunterfahren und VHD's Compacten die Status "Running" haben und keinen Checkpoint besitzen.
      foreach( $VM in $VMRestart ){
            try{
                  $VMRealName = $VM.Name
                  # Ausnahmen für Server - Server die hier eingetragen werden, werden nicht Compacted.
                  if($VM.Name -eq "DONT-COMPACT-SERVER-1" -or $VM.Name -eq "DONT-COMPACT-SERVER-2" -or $VM.Name -eq "DONT-COMPACT-SERVER-3" -or $VM.Name -eq "DONT-COMPACT-SERVER-4" -or $VM.Name -eq "DONT-COMPACT-SERVER-4"){
                        Write-Log "$VMRealName wurde aufgrund einer Ausnahmeregel im Script nicht compacted."
                  }

# Changelog:
10.11.2017 - Es wurde eine anpassung am Script vorgenommen, sodass gewisse VM's ausgenommen werden können. VM's mit einer Ausnahme werden nicht herunterfahren und compacted.

15.11.2017 - Function VHDCompact erstellt.
