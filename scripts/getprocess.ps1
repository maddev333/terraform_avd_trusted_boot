Get-Process | Out-File -FilePath c:\\Process.txt
New-Item -Path 'HKLM:\Software\FSLogix' -Force | New-ItemProperty -Name 'Profiles' -Type DWord -Value 1 -Force 
Get-ItemProperty HKLM:\Software\FSLogix -Name Profiles


