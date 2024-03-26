#!/bin/bash

force_flag=false

Agentversion="0.96.0"
OldAgent="otelcol-contrib-0.96.0-1.x86_64"
os="linux"
FileName="otelcol-contrib_${Agentversion}_${os}_amd64.rpm"
OTelURL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${Agentversion}/${FileName}"
ConfigURL="https://github.com/kevn-gonz/otel_agent/raw/master/config_${os}.yaml"
WorkingPath="/etc/otelcol-contrib"
ServiceName="OTelAgent"

#Installation method
Agent_Install() {
    # Going to the working directory
    cd "$WorkingPath"
    # Downloading the OTel agent
    curl -LO "$OTelURL"
    # Create OTel service
    sudo rpm -ivh $FileName
    # Remove unnecessary files
    find . ! -name 'otelcol-contrib.conf' -type f -exec rm -f {} +
    # Downloading standard config file
    curl -LO "$ConfigURL"
    # Renaming config file
    mv config_linux.yaml config.yaml
}

# Check if the folder exists
if [ ! -d "$WorkingPath" ]; then
    echo "Folder '$WorkingPath' does not exist. Creating it and installing the agent ..."

    # Creating working directory / installation folder
    mkdir -p "$WorkingPath"

    # Call method to install agent
    Agent_Install

    exit 0
else # else = the OTel agent folder already exists
    # If --Force parameter is provided, replace everything and re-install

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force_flag=true
                shift
                ;;
            *)
                echo "Usage: $0 [--force]"
                exit 1
                ;;
        esac
    done

    # Perform action only if --force flag is provided
    if [ "$force_flag" = true ]; then
        sudo systemctl stop otelcol-contrib.service
        sudo rm -f /usr/lib/systemd/system/otelcol-contrib.service
        rm -rf "$WorkingPath/*"
        rm -rf "/usr/bin/otelcol-contrib"
        sudo rpm -e $OldAgent
        # Call method to install agent
        sudo systemctl daemon-reload
        Agent_Install
    else
        echo "Action not performed. The agent is already installed. Use the --force flag to execute."
    fi
fi
