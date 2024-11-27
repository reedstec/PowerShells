# Define the URLs for the files to download
$scriptUrl = "https://github.com/reedstec/PowerShells/blob/main/DattoInstall.ps1"
$fileUrl = "https://pinotage.centrastage.net/csm/profile/downloadAgent/e38033cc-4009-4932-87db-537be1394c78"

# Define the SYSVOL paths
$sysvolPath = "\\$env:USERDNSDOMAIN\sysvol\$env:USERDNSDOMAIN\scripts"
$scriptPath = "$sysvolPath\DattoInstall.ps1"
$filePath = "$sysvolPath\downloadAgent.exe"

# Create the SYSVOL directory if it doesn't exist
if (-Not (Test-Path -Path $sysvolPath)) {
    New-Item -ItemType Directory -Path $sysvolPath
}

# Download the files
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
Invoke-WebRequest -Uri $fileUrl -OutFile $filePath

# Create a new Group Policy Object
$gpoName = "CP_DattoDeploy"
New-GPO -Name $gpoName

# Set the GPO to copy the files from the SYSVOL share to the destination
$gpo = Get-GPO -Name $gpoName
$gpoId = $gpo.Id
$gpoPath = "\\$env:USERDNSDOMAIN\sysvol\$env:USERDNSDOMAIN\Policies\{$gpoId}\Machine\Preferences"

# Create the necessary directories for the GPO
$filesPath = "$gpoPath\Files"
$tasksPath = "$gpoPath\ScheduledTasks"
if (-Not (Test-Path -Path $filesPath)) {
    New-Item -ItemType Directory -Path $filesPath -Force
}
if (-Not (Test-Path -Path $tasksPath)) {
    New-Item -ItemType Directory -Path $tasksPath -Force
}

# Define the XML content for the file copy settings
$filesXmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Files clsid="{215B2E53-57CE-475c-80FE-9EEC14635851}">
    <File clsid="{50BE44C8-567A-4ed1-B1D0-9234FE1F38AF}" name="DattoInstall.ps1" status="DattoInstall.ps1" image="2" changed="2024-11-27 11:49:16" uid="{D6429B6A-4DC0-4D66-A3C7-58B03636C021}">
        <Properties action="U" fromPath="\\$env:USERDNSDOMAIN\sysvol\$env:USERDNSDOMAIN\scripts\DattoInstall.ps1" targetPath="C:\DattoAgent\DattoInstall.ps1" readOnly="0" archive="1" hidden="0" suppress="0"/>
    </File>
    <File clsid="{50BE44C8-567A-4ed1-B1D0-9234FE1F38AF}" name="downloadAgent.exe" status="downloadAgent.exe" image="2" changed="2024-11-27 11:49:56" uid="{109ECA09-6D90-4DAD-A33C-B737E2252A41}">
        <Properties action="U" fromPath="\\$env:USERDNSDOMAIN\sysvol\$env:USERDNSDOMAIN\scripts\downloadAgent.exe" targetPath="C:\DattoAgent\downloadAgent.exe" readOnly="0" archive="1" hidden="0" suppress="0"/>
    </File>
</Files>
"@

# Save the XML content to the Files path
$filesXmlPath = "$filesPath\Files.xml"
[System.IO.File]::WriteAllText($filesXmlPath, $filesXmlContent)

# Define the XML content for the scheduled task
$taskXmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<ScheduledTasks clsid="{CC63F200-7309-4ba0-B154-A71CD118DBCC}">
    <TaskV2 clsid="{D8896631-B747-47a7-84A6-C155337F3BC8}" name="C:\DattoAgent\downloadAgent.exe" image="2" changed="2024-11-27 12:30:01" uid="{EFFAC250-D4D2-4169-BCE9-B706D7FB23CD}">
        <Properties action="U" name="C:\DattoAgent\downloadAgent.exe" runAs="NT AUTHORITY\SYSTEM" logonType="S4U">
            <Task version="1.2">
                <RegistrationInfo>
                    <Author>NT AUTHORITY\SYSTEM</Author>
                    <Description></Description>
                </RegistrationInfo>
                <Principals>
                    <Principal id="Author">
                        <UserId>NT AUTHORITY\SYSTEM</UserId>
                        <LogonType>S4U</LogonType>
                        <RunLevel>HighestAvailable</RunLevel>
                    </Principal>
                </Principals>
                <Settings>
                    <IdleSettings>
                        <Duration>PT10M</Duration>
                        <WaitTimeout>PT1H</WaitTimeout>
                        <StopOnIdleEnd>true</StopOnIdleEnd>
                        <RestartOnIdle>false</RestartOnIdle>
                    </IdleSettings>
                    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
                    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
                    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
                    <AllowHardTerminate>true</AllowHardTerminate>
                    <AllowStartOnDemand>true</AllowStartOnDemand>
                    <Enabled>true</Enabled>
                    <Hidden>false</Hidden>
                    <ExecutionTimeLimit>P3D</ExecutionTimeLimit>
                    <Priority>7</Priority>
                </Settings>
                <Triggers>
                    <BootTrigger>
                        <Enabled>true</Enabled>
                        <Delay>PT1M</Delay>
                    </BootTrigger>
                </Triggers>
                <Actions Context="Author">
                    <Exec>
                        <Command>powershell.exe</Command>
                        <Arguments>-ExecutionPolicy Bypass -File "C:\DattoAgent\DattoDeploy.ps1"</Arguments>
                    </Exec>
                </Actions>
            </Task>
        </Properties>
    </TaskV2>
</ScheduledTasks>
"@

# Save the XML content for the scheduled task to the ScheduledTasks path
$taskXmlPath = "$tasksPath\ScheduledTasks.xml"
[System.IO.File]::WriteAllText($taskXmlPath, $taskXmlContent)

# Link the GPO to the domain
$domain = (Get-ADDomain).DNSRoot
New-GPLink -Name $gpoName -Target "DC=$domain"
