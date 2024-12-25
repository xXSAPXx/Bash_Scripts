#!/bin/bash
set -uo pipefail


# Colors for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# List of DNF Packages to check for and then install:
package_list=("htop" "btop" "atop" "iotop" "sysstat" "lsof" "curl" "wget" "bind-utils" "iproute" "telnet" "tcpdump" "traceroute" "vim-enhanced" "bash-completion" "git" "tmux" "python3-dnf-plugin-versionlock")

# List of functions for system checks and system configurations to be performed
func_list_sys_checks=("prompt_check" "bash_history_check")
func_list_sys_config=("prompt_config" "bash_history_config")



# Function to display help
show_help() {
    echo -e "____________________________________________________________________________________________________________________"
    echo
    echo "Possible Options For Execution: 🔧"
    echo
    echo "  --report         Show VM details / Check installed packages / Check for OS Updates."
    echo
    echo "  --fix            Check if required packages and repositories are installed - if not, install them."
    echo
    echo "  --sys_report     Show VM System Configuration -- Prompt / History / Time / etc..."
    echo
    echo "  --sys_conf       Configure Prompt / History / Time / etc..."
    echo
    echo "  --update         Check If System Packages are updated - if not, update the system."
    echo
    echo "  --help           Display this help message."
    echo
    echo -e "____________________________________________________________________________________________________________________"

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



# Function to initiate all check functions in (func_list_sys_checks):
check_system_config() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking System Configuration:"
    echo
    for func in "${func_list_sys_checks[@]}"; do
        if declare -f "$func" > /dev/null; then

            "$func"   # Call the function

            else
            echo -e "${RED}Function $func NOT FOUND!${RESET}"
        fi
    done
}

# Function to initiate all system configure functions in (func_list_sys_config):
fix_system_config() {
    echo -e "_________________________________________________________________________________"
    echo
    echo -e "Checking System Configuration:"
    echo
    for func in "${func_list_sys_config[@]}"; do
        if declare -f "$func" > /dev/null; then

            "$func"   # Call the function

            else
            echo -e "${RED}Function $func NOT FOUND!${RESET}"
        fi
    done
}


########################################################## SYSTEM CHECK / CONFIG FUNCTIONS ##########################################################
########################################################## SYSTEM CHECK / CONFIG FUNCTIONS ##########################################################
# Function for checking prompt_configuration:
prompt_check() {

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
prompt_config() {

    BASHRC=~/.bashrc

    # Check if prompt is already configured:
    if grep -qE '^\s*PS1=' "$BASHRC"; then
        echo
        echo -e "✅  ${GREEN}Bash prompt is already configured.${RESET}"
    else
        echo -e "${YELLOW}Bash prompt is not configured. Setting it now...${RESET}"

        # Append the prompt configuration to .bashrc:
	echo "" >> "$BASHRC"
        echo "# If user ID = 0 then set red color for the prompt:" >> "$BASHRC"
        echo "if [ "$(id -u)" -eq 0 ]; then" >> "$BASHRC"     
        echo "    PS1='\[\e[1;31m\]\u\e[0m@\h:\w\$ '" >> "$BASHRC"
        echo "fi" >> "$BASHRC"
        echo
        echo -e "╰┈➤   ✅  ${GREEN}Bash prompt successfully configured!${RESET}"
    fi
}





# Function to check if bash history is configured:
bash_history_check() {

	BASHRC=~/.bashrc
	 
	if grep -qE '^\s*HISTSIZE=|^\s*HISTFILESIZE=|^\s*HISTIGNORE=|^\s*HISTCONTROL=|^\s*PROMPT_COMMAND=|^\s*HISTTIMEFORMAT=' "$BASHRC"; then
		echo
		echo -e "✅  ${GREEN}Bash history settings are already configured.${RESET}"
	else
		echo
		echo -e "❌  ${RED}Bash history settings are not configured.${RESET}"
	fi
}



# Function to configure bash history:
bash_history_config() {
	
	BASHRC=~/.bashrc

	if [ "$(id -u)" -ne 0 ]; then
 		echo
		echo -e "❌  ${RED}Must Be ROOT to configure bash history!${RESET}"
		
	else	
		if grep -qE '^\s*HISTSIZE=|^\s*HISTFILESIZE=|^\s*HISTIGNORE=|^\s*HISTCONTROL=|^\s*PROMPT_COMMAND=|^\s*HISTTIMEFORMAT=' "$BASHRC"; then
			echo
			echo -e "✅  ${GREEN}Bash history settings are already configured.${RESET}"
		else
  			echo 
			echo -e "${YELLOW}Configuring Bash history settings...${RESET}"
		
			# Add history config settings: 
   			echo "" >> "$BASHRC"
			echo "# ROOT User Bash History Configuration:" >> "$BASHRC"

			echo "HISTSIZE=1000" >> "$BASHRC"
			echo "HISTFILESIZE=2000" >> "$BASHRC"
			echo "HISTIGNORE=''" >> "$BASHRC"
			echo "HISTCONTROL='ignoredups'" >> "$BASHRC"
			echo "PROMPT_COMMAND='history -a'" >> "$BASHRC"
			echo 'HISTTIMEFORMAT=$(echo -e "\e[32m[\e[0m%F %T \e[33mUTC\e[0m\e[32m] \e[0m")' >> "$BASHRC"
		
			echo -e "╰┈➤   ✅  ${GREEN}Bash history settings added successfully!${RESET}"
		fi
	fi	
}	



time_format_check() {
	
	CONFIG_FILE=/etc/locale.conf
	
	if grep -qE '^\s*LC_TIME=' "$CONFIG_FILE"; then
		echo
		echo -e "✅  ${GREEN}Time Format is already configured.${RESET}"
	else
		echo
		echo -e "❌  ${RED}Time Format is not configured.${RESET}"
	fi
}



time_format_config() {
	
	CONFIG_FILE=/etc/locale.conf

	if [ "$(id -u)" -ne 0 ]; then
 		echo
		echo -e "❌  ${RED}Must Be ROOT to configure Time Format!${RESET}"
		
	else	
		if grep -qE '^\s*LC_TIME=' "$CONFIG_FILE"; then
			echo
			echo -e "✅  ${GREEN}Time Format is already configured.${RESET}"
		else
			echo
			echo -e "${YELLOW}Time Format is not configured. Setting it now...${RESET}"
			
			# Apply the changes using localectl
			echo "LC_TIME=C.UTF-8" | sudo tee -a "$CONFIG_FILE" > /dev/null
			
			echo "╰┈➤   ✅  ${GREEN}Time Format applied successfully!${RESET}"
		fi	
    fi
}



##########################################################################################################################################################
#                     Main script logic                           Main script logic                               Main script logic                      #
##########################################################################################################################################################


# Main script logic
if [ "$#" -ne 1 ]; then
   echo
   echo -e "${RED}Error: Exactly one argument is required.${RESET}"
   echo
   echo -e "${YELLOW}Please use one of the following valid arguments: --fix, --report, --update, --sysconf or --help.${RESET}"
   echo
   exit 1
fi


# Main script logic
case "$1" in
    --report)
        print_vm_details
        check_epel_repo
        check_installed_packages
        check_system_updates
        ;;
    --fix)
        install_epel_repo
        install_missing_packages
        check_system_updates
        ;;
    --sys_report)
        check_system_config
        ;;
    --sys_conf)
        fix_system_config
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
        echo -e "${RED}Please use one of the following valid arguments: --fix, --report, --update, --sys_report, --sys_conf or --help.${RESET}"
        echo
        echo -e "╰┈➤   ${YELLOW}Use '--help' for more information.${RESET}"
        echo -e "\n"
        exit 1
        ;;
esac
