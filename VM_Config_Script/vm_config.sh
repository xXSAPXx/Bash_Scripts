#!/bin/bash
set -uo pipefail


# Colors for output:
GREEN="\e[32m"
LGREEN="\e[92m"
BLUE="\e[34m"
LBLUE="\e[94"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# List of DNF Packages to check for and then install:
package_list=("htop" "btop" "atop" "iotop" "sysstat" "lsof" "curl" "wget" "bind-utils" "iproute" "telnet" "tcpdump" "traceroute" "vim-enhanced" "bash-completion" "git" "tmux" "python3-dnf-plugin-versionlock")

# List of functions for system checks and system configurations to be performed:
func_list_sys_checks=("prompt_check" "bash_history_check" "time_format_check")
func_list_sys_config=("prompt_config" "bash_history_config" "time_format_config")



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
    echo -e "System Information:"
    echo -e "---------------------"
    echo -e "Static Hostname:        $(hostnamectl --static)"
    echo -e "Operating System:       $(uname -o)"
    echo -e "Distribution:           $(grep PRETTY_NAME /etc/os-release | cut -d '=' -f 2 | tr -d '\"')"
    echo -e "Kernel Version:         $(uname -r)"
    echo -e "Architecture:           $(uname -m)"
    echo
    echo
    echo -e "Hardware Information:"
    echo -e "---------------------"
    echo -e "CPU:                   $(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f 2 | xargs)"
    echo -e "Hardware Vendor:       $(dmidecode -s system-manufacturer)"
    echo -e "Firmware Version:      $(dmidecode -s bios-version)"
    echo
    echo
    echo -e "Additional Details:"
    echo -e "---------------------"
    echo -e "Support End Date:      $(grep SUPPORT_END /etc/os-release | cut -d '=' -f 2 | tr -d '\"')"
    echo -e "Bug Report URL:        $(grep BUG_REPORT_URL /etc/os-release | cut -d '=' -f 2 | tr -d '\"')"
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

    BASH_PROMPT_SH=/etc/profile.d/bash_profile.sh

    # Check if prompt is already configured:
    if [[ -f "$BASH_PROMPT_SH" ]]; then
        if grep -qE '^\s*PS1=' "$BASH_PROMPT_SH"; then
            echo
            echo -e "✅  ${GREEN}Bash prompt is already configured.${RESET}"
        else
            echo
            echo -e "❌  ${RED}Bash prompt is not configured.${RESET}"
        fi
    else
        echo
        echo -e "❌  ${RED}Bash prompt is not configured (file does not exist).${RESET}"
    fi
}


# Function for installing prompt_configuration:
prompt_config() {

    BASH_PROMPT_SH=/etc/profile.d/bash_profile.sh

    # Check if prompt is already configured:
    if [[ -f "$BASH_PROMPT_SH" ]]; then
        if grep -qE '^\s*PS1=' "$BASH_PROMPT_SH"; then
			echo
			echo -e "✅  ${GREEN}Bash prompt is already configured.${RESET}"
        else
			echo -e "${YELLOW}Bash prompt is not configured. Setting it now...${RESET}"

			# Append the prompt configuration to file:
			echo "# If user ID = 0 then set red color for the prompt:" >> "$BASH_PROMPT_SH"
			echo "if [ "$(id -u)" -eq 0 ]; then" >> "$BASH_PROMPT_SH"     
			echo "    PS1='[\[\e[1;31m\]\u\e[0m@\h \w ]# '" >> "$BASH_PROMPT_SH"
			echo "fi" >> "$BASH_PROMPT_SH"
			echo
			echo -e "╰┈➤   ✅  ${GREEN}Bash prompt successfully configured!${RESET}"
        fi
    
    else
        echo -e "${YELLOW}Bash prompt is not configured. Setting it now...${RESET}"
		
		# Create the file and configure the prompt:
        echo "# If user ID = 0 then set red color for the prompt:" >> "$BASH_PROMPT_SH"
        echo "if [ \$(id -u) -eq 0 ]; then" >> "$BASH_PROMPT_SH"
        echo "    PS1='[\[\e[1;31m\]\u\e[0m@\h \w ]# '" >> "$BASH_PROMPT_SH"
        echo "fi" >> "$BASH_PROMPT_SH"

        echo
        echo -e "╰┈➤   ✅  ${GREEN}File created and bash prompt successfully configured!${RESET}"
    fi
}




# Function to check if bash history is configured:
bash_history_check() {

    BASH_HISTORY_SH=/etc/profile.d/bash_history.sh
	
    if [[ -f "$BASH_PROMPT_SH" ]]; then 
	if grep -qE '^\s*HISTSIZE=|^\s*HISTFILESIZE=|^\s*HISTIGNORE=|^\s*HISTCONTROL=|^\s*PROMPT_COMMAND=|^\s*HISTTIMEFORMAT=' "$BASH_HISTORY_SH"; then
		echo
		echo -e "✅  ${GREEN}Bash history settings are already configured.${RESET}"
	else
		echo
		echo -e "❌  ${RED}Bash history settings are not configured.${RESET}"
	fi
    else
	echo
        echo -e "❌  ${RED}Bash history is not configured (file does not exist).${RESET}"
    fi
}



# Function to configure bash history:
bash_history_config() {
	
    BASH_HISTORY_SH=/etc/profile.d/bash_history.sh

    if [ "$(id -u)" -ne 0 ]; then
 	echo
	echo -e "❌  ${RED}Must Be ROOT to configure Bash History!${RESET}"
		
    else	
	   if grep -qE '^\s*HISTSIZE=|^\s*HISTFILESIZE=|^\s*HISTIGNORE=|^\s*HISTCONTROL=|^\s*PROMPT_COMMAND=|^\s*HISTTIMEFORMAT=' "$BASH_HISTORY_SH"; then
		echo
		echo -e "✅  ${GREEN}Bash history settings are already configured.${RESET}"
	   else
  		echo 
		echo -e "${YELLOW}Configuring Bash history settings...${RESET}"
		
		# Add history config settings: 
		echo "# ROOT User Bash History Configuration:" >> "$BASH_HISTORY_SH"
		echo >> "$BASH_HISTORY_SH"
		echo "BLUE=\"\e[34m\"" >> "$BASH_HISTORY_SH"
		echo "YELLOW=\"\e[33m\"" >> "$BASH_HISTORY_SH"
		echo "GREEN=\"\e[32m\"" >> "$BASH_HISTORY_SH"
		echo "RESET=\"\e[0m\"" >> "$BASH_HISTORY_SH"
		echo >> "$BASH_HISTORY_SH"
		echo "# RAM History Buffer and Disk file size:" >> "$BASH_HISTORY_SH"
		echo "HISTSIZE=1000" >> "$BASH_HISTORY_SH"
		echo "HISTFILESIZE=2000" >> "$BASH_HISTORY_SH"
		echo >> "$BASH_HISTORY_SH"
		echo "# No bash commands are gonna be ignored (Only duplicate commands executed consecutively)" >> "$BASH_HISTORY_SH"
		echo "HISTIGNORE=''" >> "$BASH_HISTORY_SH"
		echo "HISTCONTROL='ignoredups'" >> "$BASH_HISTORY_SH"
		echo >> "$BASH_HISTORY_SH"
		echo "# Persist command history immediately:" >> "$BASH_HISTORY_SH"
		echo "PROMPT_COMMAND='history -a'" >> "$BASH_HISTORY_SH"
		echo >> "$BASH_HISTORY_SH"
		echo "# Command Timestamps:" >> "$BASH_HISTORY_SH"
		echo 'HISTTIMEFORMAT=`echo -e ${GREEN}[${RESET}%F %T ${YELLOW}UTC${RESET}${GREEN}] $RESET`' >> "$BASH_HISTORY_SH"
  
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
			
			echo -e "╰┈➤   ✅  ${GREEN}Time Format set successfully!${RESET}"
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
