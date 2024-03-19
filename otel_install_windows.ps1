param(
    [switch]$Force
)

$Agentversion = "v0.95.0"
$TarFile = "otelcol-contrib_0.95.0_windows_386.tar.gz"
$OTelURL = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/$Agentversion/$TarFile"
$ConfigURL = "https://github.com/kevn-gonz/otel_agent/raw/master/config_windows.yaml"
$WorkingPath = "C:\OTel"
$ServiceName = "OTelAgent"

function Agent_Install {
    #going to the working directory
    cd $WorkingPath
    #Downloading the OTel agent
    Invoke-WebRequest -Uri $OTelURL -OutFile .\$TarFile
    #Extracting the OTel agent
    tar.exe -xzf .\$TarFile
    #Downloading standard config file 
    Invoke-WebRequest -Uri $ConfigURL -OutFile .\config.yaml
    #Create OTel service
    sc.exe create $ServiceName binPath= "$WorkingPath\otelcol-contrib.exe --config $WorkingPath\config.yaml" DisplayName= "$ServiceName" start= auto
    #Starting new service
    sc.exe start $ServiceName
    #Remove unnecessary files
    Get-ChildItem -Exclude config.yaml,otelcol-contrib.exe | Remove-Item -Recurse -Force
}

# Check if the folder exists
If (!(Test-Path -PathType container $WorkingPath)) {
    Write-Host "Folder '$WorkingPath' does not exist. Creating it and installing the agent ..."
    
    #Creating working directory / installation folder
    New-Item -ItemType Directory -Path $WorkingPath
    
    #Call method to install agent
    Agent_Install 

    exit 0
} else { #else = the OTel agent folder already exist
# If --Force parameter is provided, replace everything and re-install
    if ($Force) {
        sc.exe stop $ServiceName
        sc.exe delete $ServiceName
        Remove-Item -Path "$WorkingPath\*" -Force
        #Call method to install agent
        Agent_Install 
    } else {
        Write-Error "Agent already installed, use the -Force flag to replace it"
    }
}
