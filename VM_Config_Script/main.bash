#!/bin/bash

# Colors for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"



# Function to display help
show_help() {
    echo -e "_________________________________________________________________________________"
    echo
    echo "Possible Options For Execution: 🔧"
    echo
    echo "  --report    Show VM details / Check installed packages / Check for OS Updates."
    echo
    echo "  --fix       Check if required  packages are installed - if not, install them."
    echo
    echo "  --update    Check If System Packages are updated - if not, update the system."
    echo
    echo "  --help      Display this help message."
    echo
    echo -e "_________________________________________________________________________________"

}



# Function to print VM details
print_vm_details() {
    echo -e "_________________________________________________________________________________"
    echo
    echo "Static Hostname: $(hostnamectl --static)"
    echo
    echo "OS: $(uname -o)"
    echo
    echo
    echo
    echo "$(grep -E '^(NAME|VERSION|PRETTY_NAME|BUG_REPORT_URL|SUPPORT_END)=' /etc/os-release | awk '{print $0 "\n"}' )"
    echo
    echo "Kernel Version: $(uname -r)"
    echo
    echo
    echo
    echo "Architecture: $(uname -m)"
    echo
    echo "CPU Info: $(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f 2 | xargs)"
    echo
    echo
    echo
    echo "Hardware Vendor: $(dmidecode -s system-manufacturer)"
    echo
    echo "Firmware Version: $(dmidecode -s bios-version)"
    echo
    echo -e "_________________________________________________________________________________"
    echo
}



# Function to check for system updates
check_system_updates() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking for System Updates:"

    if command -v dnf &>/dev/null; then
        echo
        echo -e "✅  ${GREEN}dnf package manager is available.${RESET}"
        echo

        # Run check-update and store the exit code immediately
        sudo dnf check-update &>/dev/null
        CHECK_UPDATE_EXIT_CODE=$?

        if [ $CHECK_UPDATE_EXIT_CODE -eq 100 ]; then
            echo
            echo -e "╰┈➤   ${YELLOW}Updates are available.${RESET}"
            echo
            echo

        elif [ $CHECK_UPDATE_EXIT_CODE -eq 0 ]; then
            echo -e "✅  ${GREEN}No updates available. Your system is up to date.${RESET}"
            echo

        else
            echo -e "❌  ${RED}Failed to check for updates. Please check your connection or configuration.${RESET}"
            echo
            return 1
        fi

        return 0
    else
        echo
        printf '\u274c  ' && echo -e "${RED}dnf package manager is not installed or not available.${RESET}"
        echo
        return 1
    fi
}



# Function to update system packages
update_system() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking for System Updates:"

    if command -v dnf &>/dev/null; then
        echo
        echo -e "✅  ${GREEN}dnf package manager is available.${RESET}"
        echo

        # Run check-update and store the exit code immediately
        sudo dnf check-update &>/dev/null
        CHECK_UPDATE_EXIT_CODE=$?

        if [ $CHECK_UPDATE_EXIT_CODE -eq 100 ]; then
            echo
            echo -e "╰┈➤   ${YELLOW}Updates are available. Installing Updates.... ${RESET}"
            echo
            echo
            sudo dnf upgrade -y
            echo
            echo
            echo -e "╰┈➤   ${GREEN}System updated successfully.${RESET}"
            echo
            echo -e "╰┈➤   ${YELLOW}Reboot is good practice after OS Upgrade${RESET}"
                        echo
                        read -p "╰┈➤   ${YELLOW}Would you like to reboot now? (Y/N): ${RESET}" REBOOT_ANSWER
                                if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
                                        echo
                                        echo -e "🔄  ${YELLOW}Rebooting now...${RESET}"
                                        echo
                                        sudo reboot
                                else
                                        echo
                                        echo -e "╰┈➤  ${YELLOW}Reboot skipped. Please remember to reboot later if required.${RESET}"
                                        echo
                                fi
                elif [ $CHECK_UPDATE_EXIT_CODE -eq 0 ]; then
            echo -e "✅  ${GREEN}No updates available. Your system is up to date.${RESET}"
            echo
        else
            echo -e "❌  ${RED}Failed to check for updates. Please check your connection or configuration.${RESET}"
            echo
            return 1
        fi

        return 0
    else
        echo
        printf '\u274c  ' && echo -e "${RED}dnf package manager is not installed or not available.${RESET}"
        echo
        return 1
    fi
}



#  Function to check if EPEL Repo is installed
check_epel_repo() {
    echo
    echo -e "Checking Installed Repositories:"
    echo
    if rpm -q epel-release &>/dev/null; then
        echo
        echo -e "✅  ${GREEN}EPEL repository is installed.${RESET}"
        echo
        return 0
    else
        printf '\u274c  ' && echo -e "${RED}EPEL repository is not installed.${RESET}"
        echo
        return 1
    fi
}



#  Function to install EPEL Repo
install_epel_repo() {
    if rpm -q epel-release &>/dev/null; then
        echo -e "${GREEN}EPEL repository is already installed.${RESET}"
        return 0
    else
        echo
        echo -e "${YELLOW}Installing EPEL repository...${RESET}"
        sudo dnf install -y epel-release &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}EPEL repository successfully installed.${RESET}"
            echo
            return 0
        else
            echo -e "${RED}Failed to install EPEL repository.${RESET}"
            echo
            return 1
        fi
    fi
}



# Function to check if htop is installed
check_htop() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking Installed Packages:"
    if command -v htop &>/dev/null; then
        echo
        echo -e "✅  ${GREEN}htop is installed.${RESET}"
        echo
        return 0
    else
        echo
        printf '\u274c  ' && echo -e "${RED}htop is not installed.${RESET}"
        echo
        return 1
    fi
}



# Function to install htop
install_htop() {
    echo "Installing htop..."
    if sudo dnf install -y htop &>/dev/null; then
        echo -e "${GREEN}htop has been successfully installed.${RESET}"
        echo
    else
        echo -e "${RED}Failed to install htop.${RESET}"
        echo
    fi
}



# Function to check curl
check_curl() {
    if command -v curl &>/dev/null; then
        echo -e "✅  ${GREEN}curl is installed.${RESET}"
        echo
        return 0
    else
        printf '\u274c  ' && echo -e "${RED}curl is not installed.${RESET}"
        echo
        return 1
    fi
}



# Function to install curl:
install_curl() {
    echo "Installing curl..."
    if sudo dnf install -y htop &>/dev/null; then
        echo -e "${GREEN}curl has been successfully installed.${RESET}"
        echo
    else
        echo -e "${RED}Failed to install curl.${RESET}"
        echo
    fi
}


# Function to check git
check_git() {
    if command -v git &>/dev/null; then
        echo -e "✅  ${GREEN}git is installed.${RESET}"
        echo
        return 0
    else
        printf '\u274c  ' && echo -e "${RED}git is not installed.${RESET}"
        echo
        return 1
    fi
}



# Function to install git:
install_git() {
    echo "Installing git..."
    if sudo dnf install -y git &>/dev/null; then
        echo -e "${GREEN}git has been successfully installed.${RESET}"
        echo
    else
        echo -e "${RED}Failed to install git.${RESET}"
        echo
    fi
}





###################################################
############## Main script logic ##################
###################################################


# Main script logic
if [ "$#" -ne 1 ]; then
   echo -e "\n"
   echo -e "${RED}Error: Exactly one argument is required.${RESET}"
   echo -e "\n"
   exit 1
fi


# Main script logic
case "$1" in
    --report)
        print_vm_details
        check_epel_repo
        check_htop
        check_curl
        check_git
        check_system_updates
        ;;
    --fix)
        print_vm_details
        if ! check_epel_repo; then
             install_epel_repo
        fi
        if ! check_htop; then
             install_htop
        fi
        if ! check_curl; then
             install_curl
        fi
        if ! check_git; then
             install_git
        fi
        check_system_updates
        ;;
    --update)
        update_system
        ;;
    --help)
        show_help
        ;;
    *)
        echo -e "\n"
        echo -e "${RED}Error: Invalid argument '$1'.${RESET}"
        echo -e "${RED}Please use one of the following valid arguments: --fix, --report, or --help.${RESET}"
        echo -e "${RED}Use '--help' for more information.${RESET}"
        echo -e "\n"
        exit 1
        ;;
esac
