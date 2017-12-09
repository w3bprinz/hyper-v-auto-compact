#Compact Hyper-V VHD(x)'s Script.

This Script was made with much love, patience and nerves by:

		Patrick Köhler

Powershell Script zum automatischen compacten von Hyper-V VHD(x)s ohne Checkpoint.
Dieses Script prüft automatisch welche virtuellen Maschinen Checkpoints haben, welche maschinen heruntergefahren sind und welche VM's derzeit laufen.


Virtuelle Maschinen die den Status "Running" haben werden automatisch heruntergefahren und nach dem Compacten wieder hochgefahren.
Virtuelle Maschinen die den Status "Offline" haben und keinen Checkpoint besitzen werden ohne weiteres compacted.
Für virtuelle Maschinen die einen Checkpoint haben und aus diesem Grund die VHD nicht compacted werden können, erfolgt eine Meldung per E-Mail an das Konto welches unter der variable $EMailAddress eingetragen ist.

Changelog:
10.11.2017 - Es wurde eine anpassung am Script vorgenommen, sodass gewisse VM's ausgenommen werden können. VM's mit einer Ausnahme werden nicht herunterfahren und compacted. 
15.11.2017 - Function VHDCompact erstellt.
