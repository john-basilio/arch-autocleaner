#!/bin/bash

# Function to perform the cleaning tasks
perform_cleaning() {
    # Update sudo timestamp to avoid password prompts for a while
    sudo -v

    # Remove orphaned dependencies
    sudo pacman -Rns $(pacman -Qdtq)

    # Clear user cache
    sudo rm -rf ~/.cache/*
}

# Function to check and install cronie
install_cronie() {
    if ! pacman -Qs cronie > /dev/null 2>&1; then
        read -p "The 'cronie' package is not installed. Do you want to install it now? (yes/no): " install_cronie

        if [[ "$install_cronie" =~ ^[Yy]$ ]]; then
            sudo pacman -Sy cronie
            echo "cronie has been installed."
        else
            echo "Error: The 'cronie' package is required for automated cleaning. Please install it and run the script again."
            exit 1
        fi
    fi
}

# Function to automate the cleaning tasks
automate_cleaning() {
    # Ask the user for the interval in minutes
    read -p "Enter the interval in minutes for automated cleaning: " interval

    # Install cronie if not installed
    install_cronie

    # Create a cron job to run the cleaning script
    cron_job="*/$interval * * * * $(pwd)/cleaner.sh start"

    # Add the cron job
    if command -v crontab > /dev/null 2>&1; then
        (crontab -l ; echo "$cron_job") | crontab -
        echo "Automated cleaning scheduled every $interval minutes."
    else
        echo "Error: The 'crontab' command is not found. Please ensure that the 'cronie' package is installed on Arch Linux."
        exit 1
    fi
}

# Function to stop automated cleaning
stop_automation() {
    read -p "Choose an option:
    1. Stop the automation task but still run on background (waiting for a command) (type '1')
    2. Stop entirely (type '2'): " stop_option

    case $stop_option in
        "1")
            # Stop the automation task but leave it running in the background
            crontab -l | grep -v -F "$(pwd)/cleaner.sh start" | crontab -
            echo "Automation task stopped. It will run in the background, waiting for a command."
            ;;
        "2")
            # Stop the automation task entirely
            crontab -l | grep -v -F "$(pwd)/cleaner.sh start" | crontab -
            echo "Automation task stopped entirely."
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
}

# Function to display the current path
where_am_i() {
    script_location=$(pwd)
    echo "This script is located at $script_location"
}

# Function to show help information
show_help() {
    echo "Usage: ./cleaner.sh [start|stop|whereami|shutdown|pause|start_once|start_cycle|help]"
    echo "Arguments:"
    echo "  start           Initiate a series of progressive confirmations."
    echo "  stop            Stop automated cleaning."
    echo "  whereami        Display the location of the script."
    echo "  shutdown        Completely stop automation."
    echo "  pause           Stop but run in the background, waiting for a command."
    echo "  start_once      Clean only once and exit."
    echo "  start_cycle     Start the automation."
    echo "  help            Show this help information."
}

# Function for confirmation message
confirmation_message() {
    read -r -p "This script will perform cleaning tasks that may affect some packages.
Continue? (Type 'yes' or press [Enter] to proceed, 'no' to cancel): " response

    if [[ "$response" =~ ^[Yy]$ || -z "$response" ]]; then
        return 0  # Continue
    elif [[ "$response" =~ ^[Nn][Oo]$ ]]; then
        echo "Cleaning canceled."
        exit 0
    else
        echo "Invalid response. Please enter 'yes' or 'no'."
        confirmation_message  # Repeat confirmation
    fi
}

# Check for command-line arguments
if [ $# -eq 1 ]; then
    case $1 in
        "start")
            # Confirm whether to proceed with cleaning
            confirmation_message

            # Ask whether to perform the cleaning once or set up automation
            read -r -p "Do you want to perform the cleaning:
            1. Only once (type '1')
            2. Set up automation (type '2'): " cleaning_option

            case "$cleaning_option" in
                "1")
                    perform_cleaning
                    ;;
                "2")
                    automate_cleaning
                    ;;
                *)
                    echo "Invalid option. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        "stop")
            stop_automation
            ;;
        "whereami")
            where_am_i
            ;;
        "shutdown")
            # Stop the automation task entirely
            crontab -l | grep -v -F "$(pwd)/cleaner.sh start" | crontab -
            echo "Automation task stopped entirely."
            exit 0
            ;;
        "pause")
            stop_automation
            ;;
        "start_once")
            perform_cleaning
            exit 0
            ;;
        "start_cycle")
            automate_cleaning
            ;;
        "help")
            show_help
            ;;
        *)
            echo "Error: Bad argument \"$1\""
            show_help
            exit 1
            ;;
    esac
else
    # Confirm whether to proceed with cleaning
    confirmation_message

    # Prompt user for options
    echo "Choose an option (Enter a number):
    1. Perform cleaning now 
    2. Automate cleaning
    3. Stop automated cleaning
    4. Where am I?
    5. Show help"

    read -rp "Enter the number corresponding to your choice: " option

    case $option in
        "1")
            # Ask whether to perform the cleaning once or set up automation
            read -r -p "Do you want to perform the cleaning:
            1. Only once (type '1')
            2. Set up automation (type '2'): " cleaning_option

            case "$cleaning_option" in
                "1")
                    perform_cleaning
                    ;;
                "2")
                    automate_cleaning
                    ;;
                *)
                    echo "Invalid option. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        "2")
            automate_cleaning
            ;;
        "3")
            stop_automation
            ;;
        "4")
            where_am_i
            ;;
        "5")
            show_help
            ;;
        *)
            echo "Error: Bad argument \"$option\""
            show_help
            exit 1
            ;;
    esac
fi
