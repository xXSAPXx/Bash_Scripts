#!/bin/bash
set -uo pipefail


# Colors for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# List of DNF Packages to check for and then install:
package_list=("htop" "btop" "atop" "iotop" "sysstat" "lsof" "curl" "wget" "bind-utils" "iproute" "telnet" "tcpdump" "traceroute" "vim-enhanced" "bash-completion" "git" "tmux" "python3-dnf-plugin-versionlock")



# Function to display help
show_help() {
    echo -e "_________________________________________________________________________________"
    echo
    echo "Possible Options For Execution: 🔧"
    echo
    echo "  --report    Show VM details / Check installed packages / Check for OS Updates."
    echo
    echo "  --fix       Check if required packages and repositories are installed - if not, install them."
    echo
    echo "  --sysconf   Configure Prompt / History / Time / etc..."   
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
            echo -e "╰┈➤   ${YELLOW}Reboot is a  good practice after OS Update${RESET}"
                        echo
                        read -p "╰┈➤   Would you like to reboot now? (Y/N): " REBOOT_ANSWER
                                if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
                                        echo
                                        echo -e "🔄  ${YELLOW}Rebooting now...${RESET}"
                                        echo
                                        sudo reboot
                                else
                                        echo
                                        echo -e "╰┈➤   ${YELLOW}Reboot skipped. Please remember to reboot later if required.${RESET}"
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
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking Installed Repositories:"
    echo
    if rpm -q epel-release &>/dev/null; then
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
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking Installed Repositories:"
    echo
    if rpm -q epel-release &>/dev/null; then
        echo -e "${GREEN}EPEL repository is already installed.${RESET}"
        echo
        return 0
    else
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



# Function to check installed packages:
check_installed_packages() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking Installed Packages:"
    echo
    for package in "${package_list[@]}"; do
        if rpm -qa | grep "^${package}-" &>/dev/null; then
            echo
            echo -e "✅  ${GREEN}$package is installed.${RESET}"
        else
            echo
            printf '\u274c  ' && echo -e "${RED}$package is not installed.${RESET}"
            echo
        fi
    done
}



# Function to install missing packages:
install_missing_packages() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Installing Missing Packages:"
    for package in "${package_list[@]}"; do
        if rpm -qa | grep "^${package}-" &>/dev/null; then
            echo
            echo -e "✅  ${GREEN}$package is installed.${RESET}"
        else
            echo
            echo "Installing $package..."
            if sudo dnf install -y "$package" &>/dev/null; then
                echo
                echo -e "${GREEN}$package has been successfully installed.${RESET}"
                echo
            else
                echo
                echo -e "${RED}Failed to install $package.${RESET}"
                echo
            fi
        fi
    done
}



# Function for checking prompt_configuration:
prompt_configuration_check() {
	
	BASHRC=~/.bashrc

    # Check if prompt is already configured:
    if grep -qE '^\s*PS1=' "$BASHRC"; then
        echo
        echo -e "✅  ${GREEN}Bash prompt is already configured.${RESET}"
    else
		echo
        echo -e "❌  ${RED}Bash prompt is not configured.${RESET}"
	fi
}	



# Function for installing prompt_configuration:
prompt_configuration_install() {

    BASHRC=~/.bashrc

    # Check if prompt is already configured:
    if grep -qE '^\s*PS1=' "$BASHRC"; then
        echo
        echo -e "✅  ${GREEN}Bash prompt is already configured.${RESET}"
    else
        echo "Bash prompt is not configured. Setting it now..."

        # Append the prompt configuration to .bashrc:
        echo -e "\n# If user ID = 0 then set red color for the prompt:\nif [ \"\$(id -u)\" -eq 0 ]; then\n    PS1='\\[\\e[1;31m\\]\\u\\e[0m@\\h:\\w\\$ '\nfi" >> "$BASHRC"
        echo
        echo -e "✅  ${GREEN}PS1 configuration added successfully!${RESET}"

        # Reload .bashrc to apply the changes
        source "$BASHRC"
    fi
}


################################################################
#                      Main script logic                       #
################################################################


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
        check_installed_packages
        prompt_configuration_check
        check_system_updates
        ;;
    --fix)
        install_epel_repo
        install_missing_packages
        check_system_updates
        ;;
    --sysconf)
        prompt_configuration_install
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
        echo -e "${RED}Please use one of the following valid arguments: --fix, --report, --update, --sysconf or --help.${RESET}"
        echo
        echo -e "╰┈➤   ${YELLOW}Use '--help' for more information.${RESET}"
        echo -e "\n"
        exit 1
        ;;
esac
