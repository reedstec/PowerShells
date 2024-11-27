#PlaceHolder for the localised installer
# Check if the service "Cagservice" exists
$service = Get-Service -Name "Cagservice" -ErrorAction SilentlyContinue

# If the service does not exist, run the executable
if (-not $service) {
    & "C:\DattoAgent\downloadAgent.exe"
}
