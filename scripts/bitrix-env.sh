#!/bin/bash

# variables
LOGS_FILE=$(mktemp /tmp/bitrix-env-XXXXX.log)
RELEASE_FILE=/etc/redhat-release
OS=$(awk '{print $1}' $RELEASE_FILE)
MYSQL_CNF=$HOME/.my.cnf
DEFAULT_SITE=/home/bitrix/www
POOL=0
CONFIGURE_IPTABLES=1
CONFIGURE_FIREWALLD=0
MYVERSION="5.7"     # default mysql version
[[ -z $SILENT ]] && SILENT=0
[[ -z $TEST_REPOSITORY ]] && TEST_REPOSITORY=0

BX_NAME=$(basename $0 | sed -e "s/\.sh$//")
if [[ $BX_NAME == "bitrix-env-crm" || $BX_NAME == "bitrix-env-crm-beta" ]]; then
    BX_PACKAGE="bitrix-env-crm"
    BX_TYPE=crm
else
    BX_PACKAGE="bitrix-env"
    BX_TYPE=general
fi

if [[ $(echo "$BX_NAME" | grep -c beta) -gt 0 ]]; then
    TEST_REPOSITORY=1
fi

# Environmrnt Vars
bitrix_env_vars(){
MBE0001="Log file path: "
# Description of the script options: 
 # Running automatic pool creation after installing the package
MBE0002="Create management pool after installing $BX_PACKAGE package."
#Using a quiet mode when installing.
MBE0003="Use silent mode (don't query for information)."
# Server name that will be used when creating a pool
MBE0004="Set server name for management pool creation procedure."
# Password for user root mysql service
MBE0005="Set root password for MySQL service."
# Use the test version of the package for the surroundings
MBE0006="Use alpha/test version of Bitrix Environment."
Using IPTables as a firewall (Default: CentOS 6)
MBE0007="Use iptables as firewall service daemon (default for Centos 6)"
Using Firewalld as a firewall (Default: CentOS 7)
MBE0008="Use firewalld as firewall service daemon (default for Centos 7 system)"
# Examples of using:
MBE0009="Examples:"
Installing BX_Package Package and Pool-Control Setup:
MBE0010="install $BX_PACKAGE-package and configure management pool:"
# Installation BX_Package packet and installing MySQL password;
MBE0011="install $BX_PACKAGE-package and set mysql root password:"

# Disable Selinux before installing the package 
 # You must disable Selinux before installing Bitrix Surroundings
MBE0012="You have to disable SElinux before installing Bitrix Environment."
# To disable Selinux you will need to restart the system
MBE0013="You have to reboot the server to disable SELinux"
# Whether you want to disable Selinux
MBE0014="Do you want to disable SELinux?(Y|n)"
# Changed Selinux status in a configuration file
MBE0015="SELinux status changed to disabled in the config file"
# Please reboot the system
MBE0016="Please reboot the system! (cmd: reboot)"

# Function connect ePEL Repository 
 # Repository already connected on the server
MBE0017="EPEL repository is already configured on the server."
#Preview configuration for EPEL repository. Please wait for completion.
MBE0018="Getting EPEL repository configuration. Please wait."
# An error occurred when importing a gpg key
MBE0019="Error importing the GPG key:"
# An error occurred when installing rpm package
MBE0020="Error installing the rpm-package:"
# Repository successfully configured
MBE0021="EPEL repository has been configured successfully."

# Setup Repositories for php version 
 # Enabling the main REMI repository
MBE0022="Enable main REMI repository"
# Disable PHP 5.6 repository
MBE0023="Disable php 5.6 repository"
# Turning off PHP 7.0 repository
MBE0024="Disable php 7.0 repository"
# Turning on PHP 7.1 repository
MBE0025="Disable php 7.1 repository"
MBE00251="Disable php 7.2 repository"
MBE00252="Enable php 7.3 repository"

# Remi Remi Repository Function 
 # Repository already connected on the server
MBE0026="REMI repository is already configured on the server."
# Prepare a configuration for Remi repository. Please wait for completion.
MBE0027="Getting REMI repository configuration. Please wait."
# An error occurred when importing a gpg key
MBE0028="Error importing the GPG key:"
# An error occurred when installing rpm package
MBE0029="Error installing the rpm-package:"
# Repository successfully configured
MBE0030="REMI repository has been configured successfully."

# PERCONA Connection Function Repository 
 # Repository already connected on the server
MBE0031="Percona repository is already configured on the server."
# An error occurred when installing rpm package
MBE0032="Error installing the rpm-package:"
# Repository successfully configured
MBE0033="Percona repository configuration has been completed."
# Found Marded MariaDB Server. We skip the MARIADB-LIBS removal step.
MBE0034="MariaDB server has been detected. Skipping mariadb-libs uninstallation."
# Removed MARIADB-LIBS package
MBE0035="mariadb-libs package has been uninstalled."
# Found mysql server installed. Skip the removal step MYSQL-LIBS
MBE0036="MySQL server has been detected. Skipping mysql-libs uninstallation."
# Remove MySQL-LIBS package
MBE0037="mysql-libs package has been uninstalled."

# Connection feature Bitrix Repository
MBE0038="Bitrix repository is already configured on the server."
MBE0039="Getting Bitrix repository configuration. Please wait."
MBE0040="Error importing the GPG key:"
MBE0041="Bitrix repository has been configured."

# Update system. Please wait for completion.
MBE0042="System update in progress. Please wait."
# Error during the system update
MBE0043="Error updating the system."

# Password update 
 # Number of attempts to install a password
MBE0044="Maximum attempts to set the password has been reached. Exiting."
# Enter Ruta Password
MBE0045="Enter root password:"
# Re-enter the root password
MBE0046="Re-enter root password:"
# Entered passwords do not match. Try again.
MBE0047="Sorry, passwords do not match! Please try again."
# Sorry, but the password cannot be empty.
MBE0048="Sorry, password can't be empty."
# MySQL password updated successfully
MBE0049="MySQL password updated successfully."
# Update MySQL password ended with a mistake
MBE0050="MySQL password update failed."
# Updated client configuration file
MBE0051="mysql client config file updated:"
# Running Root Password Update Process for MySQL Service
MBE0052="Updating MySQL service root password:"
# Customer config default not found
MBE0053="Default mysql client config file not found:"
# Found a blank password for the root user, but it does not work. 
 # Found a temporary password for the root user, but it does not work.
MBE0054="Empty mysql root password was found, but it does not work."
MBE0055="Temporary mysql root password was found, but it does not work."
# Found Customer Config for MySQL
MBE0056="Default mysql client config file was found: "
# Do you want to update the default mysql config?
MBE0057="Do you want to update $MYSQL_CNF default config file?(Y|n): "
# The user chose a quiet mode. We cannot request a password for MySQL service.
MBE0058="User has chosen silent mode. Cannot request correct MySQL password."
# Client config MYSQL service updated
MBE0059="mysql client config file $MYSQL_CNF updated."
# Found an empty password for the root user, you need to change it. 
 # Found a temporary password for the root user, you need to change it. 
 # Saved password for the root user, you need to change it.
MBE0060="Empty mysql root password was found, you have to change it!"
MBE0061="Temporary mysql root password was found, you have to change it!"
MBE0062="Saved mysql root password was found, you have to change it!"
MBE0063="Saved mysql root password was found, but it does not work."

# Do you want to change the root password for MySQL service?
MBE0064="Do you want to change the root user password for MySQL service?(Y|n) "
# Checking a password for MySQL service - Completed
MBE0065="Root mysql password test completed"
# Root User Settings have been updated during MySQL service installation. 
 # You can find a user password in the configuration file
MBE0066="Root user account has been updated while installing the MySQL service."
MBE0067="You can find password settings in config file: $MYSQL_CNF."
# Safety settings configuration for MySQL service is completed.
MBE0068="MySQL security configuration has been completed."

# This script must be running with ROOT user rights, otherwise errors are possible.
MBE0069="This script needs to be run as root to avoid errors."
# The use of this CRCPT is tested only on the CentOS Linux OS. Current OS - $ OS
MBE0070="This script has been tested on CentOS Linux only. Current OS: $OS"

# Warning before the start of the Srkipt
MBE0071="Bitrix Environment for Linux installation script."
MBE0072="Yes will be assumed as a default answer."
MBE0073="Enter 'n' or 'no' for a 'No'. Anything else will be considered a 'Yes'."
MBE0074="This script MUST be run as root, or it will fail."
# Script does not support the specified version of CentOS
MBE0075="The script does not support CentOS"
# Installing PHP packets. Please wait for completion. 
# Installation Bitrix Environment. Please wait for the end
MBE0076="Installing php packages. Please wait."
MBE0077="Installing $BX_PACKAGE package. Please wait."
MBE0078="Installing bx-push-server package. Please wait."
# An error occurred during the installation of the package: xxxxx
MBE0079="Error installing package:"
# IPTables modules are turned off in the system. Nothing to do.
MBE0080="iptables modules are disabled in the system. Nothing to do."
# It did not work out to configure the firewall on the server. Log file:
MBE0081="Cannot configure firewall on the server. Log file:"
# Setting up a firewall completed
MBE0082="Firewall has been configured."
# It did not work out to configure the control pool. Log file:
MBE0083="Cannot create management pool. Log file: "
# Setup Control Pool Completed
MBE0084="Management pool has been configured."
# Setting Bitrix Environment Completed
MBE0085="Bitrix Environment $BX_PACKAGE has been installed successfully."
# Selection of the version of MySQL server when installing
MBE0086="Select MySQL version: 5.7 or 8.0 (Version 5.7 is default).
              The option is not working on CentOS 6."

MBE0087="There is no support Percona Server 8.0 for Centos 6. Exit."
}

# common subs
print(){
    msg=$1
    notice=${2:-0}
    [[ ( $SILENT -eq 0 ) && ( $notice -eq 1 ) ]] && echo -e "${msg}"
    [[ ( $SILENT -eq 0 ) && ( $notice -eq 2 ) ]] && echo -e "\e[1;31m${msg}\e[0m"
    echo "$(date +"%FT%H:%M:%S"): $$ : $msg" >> $LOGS_FILE
}

print_e(){
    msg_e=$1
    print "$msg_e" 2
    print "$MBE0001 $LOGS_FILE" 1
    exit 1
}


help_message(){

    echo "
    Usage: $0 [-h] [-s] [-t] [-p [-H hostname]] [-M mysql_root_password] [-m 5.7|8.0]
         -p - $MBE0002
         -s - $MBE0003
         -H - $MBE0004
         -M - $MBE0005
         -m - $MBE0086
         -t - $MBE0006
         -I - $MBE0007
         -F - $MBE0008
         -h - ptint help messager
    $MBE0009:
         * $MBE0010
         $0 -s -p -H master1
         * $MBE0011
         $0 -s -p -H master1 -M 'password' -m 8.0"
    exit
}

disable_selinux(){
    sestatus_cmd=$(which sestatus 2>/dev/null)
    [[ -z $sestatus_cmd ]] && return 0

    sestatus=$($sestatus_cmd | awk -F':' '/SELinux status:/{print $2}' | sed -e "s/\s\+//g")
    seconfigs="/etc/selinux/config /etc/sysconfig/selinux"
    if [[ $sestatus != "disabled" ]]; then
        print "$MBE0012" 1
        print "$MBE0013"
        read -r -p "$MBE0014 " DISABLE
        [[ -z $DISABLE ]] && DISABLE=y
        [[ $(echo $DISABLE | grep -wci "y") -eq 0 ]] && print_e "Exit."
        for seconfig in $seconfigs; do
            [[ -f $seconfig ]] && \
                sed -i "s/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/" $seconfig && \
                print "$MBE0015 $seconfig." 1
        done
        print "$MBE0016" 1
        exit
    fi
}

# EPEL
configure_epel(){

    # testing rpm package
    EPEL=$(rpm -qa | grep -c 'epel-release')
    if [[ $EPEL -gt 0 ]]; then
        print "$MBE0017" 1
        return 0
    fi
 
    # links
    print "$MBE0018" 1
    if [[ $VER -eq 6 ]]; then
        LINK="https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm"
        GPGK="https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6"
    else
        LINK="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
        GPGK="https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7"
    fi

    # configure repository
    rpm --import "$GPGK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0019 $GPGK"
    rpm -Uvh "$LINK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0020 $LINK"

    # install packages
    yum clean all >/dev/null 2>&1 
    yum install -y yum-fastestmirror >/dev/null 2>&1

    print "$MBE0021" 1
}

pre_php(){

    print "$MBE0022"
    sed -i -e '/\[remi\]/,/^\[/s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo

    print "$MBE0023"
    sed -i -e '/\[remi-php56\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/remi.repo

    print "$MBE0024"
    sed -i -e '/\[remi-php70\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/remi-php70.repo

    print "$MBE0025"
    sed -i -e '/\[remi-php71\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/remi-php71.repo

    print "$MBE00251"
    sed -i -e '/\[remi-php72\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/remi-php72.repo

    print "$MBE00252"
    sed -i -e '/\[remi-php73\]/,/^\[/s/enabled=0/enabled=1/' /etc/yum.repos.d/remi-php73.repo


    is_xhprof=$(rpm -qa | grep -c php-pecl-xhprof)
    if [[ $is_xhprof -gt 0 ]]; then
        yum -y remove php-pecl-xhprof
    fi
}

# REMI; php and mysql packages
configure_remi(){
    # testing rpm package
    EPEL=$(rpm -qa | grep -c 'remi-release')
    if [[ $EPEL -gt 0 ]]; then
        print "$MBE0026" 1
        return 0
    fi
 
    # links
    print "$MBE0027" 1
    GPGK="http://rpms.famillecollet.com/RPM-GPG-KEY-remi"
    if [[ $VER -eq 6 ]]; then
        LINK="http://rpms.famillecollet.com/enterprise/remi-release-6.rpm"
    else
        LINK="http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
    fi

    # configure repository
    rpm --import "$GPGK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0028 $GPGK"
    rpm -Uvh "$LINK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0029 $LINK"
    
    print "$MBE0030" 1
}

configure_percona(){
    # testing rpm package
    REPOTEST=$(rpm -qa | grep -c 'percona-release')
    if [[ $REPOTEST -gt 0 ]]; then
        print "$MBE0031" 1
        return 0
    fi

    # links
    LINK="http://repo.percona.com/release/percona-release-latest.noarch.rpm"

    # configure repository
    rpm -Uvh "$LINK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0032 $LINK"

    yum -y --nogpg update percona-release >> $LOGS_FILE 2>&1
    print "$MBE0033" 1

    if [[ $MYVERSION == "8.0" || $MYVERSION == "80" ]]; then
        percona-release enable ps-80 release
    else
        percona-release setup -y ps57
    fi
}

configure_nodejs(){
    curl --silent --location https://rpm.nodesource.com/setup_10.x | bash - >>$LOGS_FILE 2>&1

    if [[ $IS_CENTOS73 -gt 0 ]]; then
        rpm -ivh \
            https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm \
            >>$LOGS_FILE 2>&1
    fi
}

prepare_percona_install(){
    # test installed package
    INSTALLED_PACKAGES=$(rpm -qa)
    if [[ $(echo "$INSTALLED_PACKAGES" | grep -c "mariadb") -gt 0 ]]; then
        MARIADB_PACKAGES=$(echo "$INSTALLED_PACKAGES" | grep "mariadb")
        if [[ $(echo "$MARIADB_PACKAGES" | grep -vc "mariadb-libs") -gt 0 ]]; then
            print \
                "$MBE0034"
        else
            yum -y remove mariadb-libs >/dev/null 2>&1
            print "$MBE0035"
        fi
    fi
    
    if [[ $(echo "$INSTALLED_PACKAGES" | grep -c "mysql") -gt 0 ]]; then
        MYSQL_PACKAGES=$(echo "$INSTALLED_PACKAGES" | grep "mysql-libs")
        if [[ $(echo "$MYSQL_PACKAGES" | grep -vc "mysql-libs") -gt 0 ]]; then
            print \
                "$MBE0036"
        else
            yum -y remove mysql-libs >/dev/null 2>&1
            print "$MBE0037"
        fi
    fi

}

configure_exclude(){
	if [[ $(grep -c "exclude" /etc/yum.conf) -gt 0 ]]; then
		sed -i \
			's/^exclude=.\+/exclude=ansible1.9,mysql,mariadb,mariadb-*,Percona-XtraDB-*,Percona-*-55,Percona-*-56,Percona-*-51,Percona-*-50/' \
			/etc/yum.conf
	else
		echo 'exclude=ansible1.9,mysql,mariadb,mariadb-*,Percona-XtraDB-*,Percona-*-55,Percona-*-56,Percona-*-51,Percona-*-50' >> /etc/yum.conf
	fi

    if [[ $(grep -v '^$\|^#' /etc/yum.conf | \
        grep -c "installonly_limit" ) -eq 0 ]]; then
        echo "installonly_limit=3" >> /etc/yum.conf
    else
        if [[ $(grep -v '^$\|^#' /etc/yum.conf | \
            grep -c "installonly_limit=5") -gt 0 ]]; then
            sed -i "s/installonly_limit=5/installonly_limit=3/" /etc/yum.conf 
        fi
    fi
}

test_bitrix(){
    if [[ $TEST_REPOSITORY -eq 1  ]]; then
        REPO=yum-beta 
        REPONAME=bitrix-beta
    elif [[ $TEST_REPOSITORY -eq 2 ]]; then
        REPO=yum-testing
        REPONAME=bitrix-testing
    else
        REPO=yum
        REPONAME=bitrix
    fi
 
 
    IS_BITRIX_REPO=$(yum repolist enabled | grep ^bitrix -c)
    if [[ $BITRIX -gt 0 ]]; then
        print "$MBE0038" 1

        REPO_INSTALLED=$(grep -v '^$\|^#' /etc/yum.repos.d/bitrix.repo  | \
            awk -F'=' '/baseurl=/{print $2}' | awk -F'/' '{print $4}')

        if [[ $REPO_INSTALLED != "$REPO" ]]; then
            print "$MBE0038" 1
            return 1
        fi
    fi

    return 0

}

# Bitrix; bitrix-env, bx-nginx
configure_bitrix(){
    # Checks whether Bitrix repository is configured and its version: main, beta or test
    test_bitrix || return 1

    # get GPG key
    print "$MBE0039" 1
    GPGK="https://repos.1c-bitrix.ru/yum/RPM-GPG-KEY-BitrixEnv"
    rpm --import "$GPGK" >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0040 $GPGK"

    # create yum config file
    REPOF=/etc/yum.repos.d/bitrix.repo
    echo "[$REPONAME]" > $REPOF
    echo "name=\$OS \$releasever - \$basearch" >> $REPOF
    echo "failovermethod=priority" >> $REPOF
    echo "baseurl=https://repos.1c-bitrix.ru/$REPO/el/$VER/\$basearch" >> $REPOF
    echo "enabled=1" >> $REPOF
    echo "gpgcheck=1" >> $REPOF
    echo "gpgkey=$GPGK" >> $REPOF

    print "$MBE0041" 1
}

yum_update(){
	print "$MBE0042" 1
	yum -y update >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0043"
}
ask_for_password(){
    MYSQL_ROOTPW=
    limit=5
    until [[ -n "$MYSQL_ROOTPW" ]]; do
        password_check=

        if [[ $limit -eq 0 ]]; then
            print "$MBE0044"
            return 1
        fi
        limit=$(( $limit - 1 ))

        read -s -r -p "$MBE0045" MYSQL_ROOTPW
        echo
        read -s -r -p "$MBE0046" password_check

        if [[ ( -n $MYSQL_ROOTPW ) && ( "$MYSQL_ROOTPW" = "$password_check" ) ]]; then
            :
        else
            [[ "$MYSQL_ROOTPW" != "$password_check" ]] && \
                print "$MBE0047"
            
            [[ -z "$MYSQL_ROOTPW" ]] && \
                print "$MBE0048"
            MYSQL_ROOTPW=
        fi
    done
}

update_mysql_rootpw(){
    # update root password
    esc_pass=$(basic_single_escape "$MYSQL_ROOTPW")
    if [[ $MYSQL_UNI_VERSION -ge 57 ]]; then
        my_query "ALTER USER 'root'@'localhost' IDENTIFIED BY '$esc_pass';" \
            "$mysql_update_config"
        my_query_rtn=$?
    else
        my_query \
            "UPDATE mysql.user SET Password=PASSWORD('$esc_pass') WHERE User='root'; FLUSH PRIVILEGES;" \
            "$mysql_update_config"
        my_query_rtn=$?
    fi

    if [[ $my_query_rtn -eq 0 ]]; then
        log_to_file "$MBE0048"
        print "$MBE0049" 1
        rm -f $mysql_update_config
    else
        log_to_file "$MBE0050"
        rm -f $mysql_update_config
        return 1
    fi

    # update client config
    my_config
    log_to_file "$MBE0051 $MYSQL_CNF"
    print "$MBE0051 $MYSQL_CNF" 1
}

configure_mysql_passwords(){
    # MYSQL_UNI_VERSION
    # MYSQL_MID_VERSION
    [[ -z $MYSQL_VERSION  ]] && \
        get_mysql_package

    # start mysql
    my_start

    log_to_file \
        "$MBE0052 $MYSQL_VERSION($MYSQL_UNI_VERSION)"

    ASK_USER_FOR_PASSWORD=0
    # not found default my.cnf file
    if [[ ! -f $MYSQL_CNF  ]]; then
        log_to_file "$MBE0053 $MYSQL_CNF"
        if [[ $MYSQL_UNI_VERSION -ge 57  ]]; then
            MYSQL_LOG_FILE=/var/log/mysqld.log
            MYSQL_ROOTPW=$(grep 'temporary password' $MYSQL_LOG_FILE | awk '{print $NF}')
            MYSQL_ROOTPW_TYPE=temporary
        else
            MYSQL_ROOTPW=
            MYSQL_ROOTPW_TYPE=empty
        fi

        # test root has empty password
        local my_temp=$MYSQL_CNF.temp
        my_config "$my_temp"
        my_query "status;" "$my_temp"
        my_query_rtn=$?
        if [[ $my_query_rtn -gt 0 ]] ; then
            if [[ $MYSQL_ROOTPW_TYPE == "temporary" ]]; then
                log_to_file "$MBE0055"
            else
                log_to_file "$MBE0054"
            fi
            ASK_USER_FOR_PASSWORD=1
            mysql_update_config=
        else
            ASK_USER_FOR_PASSWORD=2
            mysql_update_config=$my_temp
        fi

    # found my.cnf file
    else
        MYSQL_ROOTPW_TYPE=saved
        log_to_file "$MBE0056 $MYSQL_CNF"
        my_query "status;"
        my_query_rtn=$?
        if [[ $my_query_rtn -gt 0  ]] ; then
            log_to_file "$MBE0063"
            ASK_USER_FOR_PASSWORD=1
            mysql_update_config=
        else
            test_empty_password=$(cat $MYSQL_CNF | grep password | \
                awk -F'=' '{print $2}' | sed -e "s/^\s\+//;s/\s\+$//" )
            if [[ ( -z $test_empty_password ) || \
                 ( $test_empty_password == '""' ) || \
                 ( $test_empty_password == "''" ) ]]; then
                ASK_USER_FOR_PASSWORD=2
                cp -f $MYSQL_CNF $MYSQL_CNF.temp
                mysql_update_config=$MYSQL_CNF.temp
            fi
        fi
    fi

    # temporary or empty root password
    if [[ $ASK_USER_FOR_PASSWORD -eq 1 ]]; then
        if [[ $MYSQL_ROOTPW_TYPE == "temporary" ]]; then
            log_to_file "$MBE0055"
            [[ $SILENT -eq 0 ]] && \
                print "$MBE0055" 2
        else
            log_to_file "$MBE0054"
            [[ $SILENT -eq 0 ]] && \
                print "$MBE0054" 2
        fi
 
        if [[ $SILENT -eq 0 ]]; then
 
            read -r -p "$MBE0057" \
                user_answer
            [[ $( echo "$user_answer" | grep -wci "\(No\|n\)"  ) -gt 0  ]] && return 1

            # update client config
            ask_for_password
            [[ $? -gt 0 ]] && return 2
        else
            if [[ -n "$MYPASSWORD" ]]; then
                MYSQL_ROOTPW="${MYPASSWORD}"
            else
                log_to_file "$MBE0058"
                return 1
            fi
        fi
        my_config
        print "$MBE0059" 1

    # saved root password, but we need to change it
    elif [[ $ASK_USER_FOR_PASSWORD -eq 2 ]]; then
        log_to_file "$MBE0063"
        if [[ $SILENT -eq 0 ]]; then

            read -r -p "$MBE0064" \
                user_answer
            [[ $( echo "$user_answer" | grep -wci "\(No\|n\)" ) -gt 0 ]] && return 1

            # update root password and create client config
            ask_for_password 
            [[ $? -gt 0 ]] && return 2
        else
            if [[ -n "$MYPASSWORD" ]]; then
                MYSQL_ROOTPW="${MYPASSWORD}"
            else
                MYSQL_ROOTPW="$(randpw)"
            fi
        fi
        update_mysql_rootpw
    else
        log_to_file "$MBE0065"
        if [[ -n "${MYPASSWORD}" ]]; then
            MYSQL_ROOTPW="${MYPASSWORD}"
            update_mysql_rootpw
        else
            if [[  ( $SILENT -eq 0 ) && ( $MYSQL_UNI_VERSION -ge 57 ) ]]; then
                print "$MBE0066" 1
                print "$MBE0067" 2
            fi
        fi
    fi
    # configure additinal options
    my_additional_security
    log_to_file "$MBE0068"
    print "$MBE0068" 1

}

os_version(){
    # testing Centos vesrion
    IS_CENTOS7=$(grep -c 'CentOS Linux release' $RELEASE_FILE)
    IS_CENTOS73=$(grep -c "CentOS Linux release 7.3" $RELEASE_FILE)
    IS_X86_64=$(uname -p | grep -wc 'x86_64')
    if [[ $IS_CENTOS7 -gt 0 ]]; then
        VER=$(awk '{print $4}' $RELEASE_FILE | awk -F'.' '{print $1}')
    else
        VER=$(awk '{print $3}' $RELEASE_FILE | awk -F'.' '{print $1}')
    fi
    if [[ $BX_PACKAGE == "bitrix-env-crm" ]]; then
        [[ ( $VER -eq 7 ) ]] || \
            print_e "$MBE0075 $VER."
    else
        [[ ( $VER -eq 7 ) || ( $VER -eq 6 ) ]] || \
            print_e "$MBE0075 $VER."
    fi
}

bitrix_env_vars

# testing effective UID
[[ $EUID -ne 0 ]] && \
    print_e "$MBE0069" 

# testing OS name
[[ $OS != "CentOS" ]] && \
    print_e "$MBE0070"

# get OS version
os_version

# get cmd options
while getopts ":H:M:m:sptIFh" opt; do
    case $opt in
        "H") HOSTIDENT="${OPTARG}" ;;
        "M") MYPASSWORD="${OPTARG}" ;;
        "m") 
            MYVERSION="${OPTARG}"
            if [[ $VER == "6" && (  $MYVERSION == '8.0' || $MYVERSION == '80' ) ]]; then
                print_e "$MBE0087"
            fi
            ;;
        "s") SILENT=1 ;;
        "p") POOL=1 ;;
        "t") TEST_REPOSITORY=2 ;;
        "I") CONFIGURE_IPTABLES=1 ; CONFIGURE_FIREWALLD=0 ;;
        "F") CONFIGURE_IPTABLES=0 ; CONFIGURE_FIREWALLD=1 ;;
        "h") help_message;;
        *)  help_message;;
    esac
done

# Notification
if [[ $SILENT -eq 0 ]]; then
    print "====================================================================" 2
    print "$MBE0071" 2
    print "$MBE0072" 2
    print "$MBE0073" 2
    print "$MBE0074" 2
    print "====================================================================" 2

    ASK_USER=1
else
    ASK_USER=0
fi

disable_selinux

# yum settings
configure_exclude

# update all packages
yum_update

# configure repositories
configure_epel
configure_remi
pre_php
configure_percona
configure_nodejs
configure_bitrix

# prepare for percona
prepare_percona_install

# update all packages (EPEL and REMI packages)
yum_update

print "$MBE0076" 1
yum -y install php php-mysql \
    php-pecl-apcu php-pecl-zendopcache >>$LOGS_FILE 2>&1 || \
    print_e "$MBE0079 php-packages"

if [[ $BX_PACKAGE == "bitrix-env-crm" ]]; then
    print "$MBE0078" 1
    yum -y install redis >>$LOGS_FILE 2>&1
    yum -y install bx-push-server  >>$LOGS_FILE 2>&1 || \
        print_e "$MBE0079 bx-push-server"
fi

print "$MBE0077" 1
yum -y install $BX_PACKAGE >>$LOGS_FILE 2>&1 || \
    print_e "$MBE0079 $BX_PACKAGE"

# upload bitrix proc
. /opt/webdir/bin/bitrix_utils.sh || exit 1

configure_mysql_passwords

update_crypto_key

configure_firewall_daemon "$CONFIGURE_IPTABLES" "$CONFIGURE_FIREWALLD"
configure_firewall_daemon_rtn=$?
if [[ $configure_firewall_daemon_rtn -eq 255 ]]; then
    if [[ ( $BX_PACKAGE == "bitrix-env-crm" ) || ( $POOL -gt 0 ) ]]; then
        print "$MBE0080" 2
    else
        print_e "$MBE0080"
    fi
elif [[ $configure_firewall_daemon_rtn -gt 0 ]]; then
    if [[ ( $BX_PACKAGE == "bitrix-env-crm" ) || ( $POOL -gt 0 ) ]]; then
        print "$MBE0081 $LOGS_FILE" 2
    else
        print_e "$MBE0081 $LOGS_FILE"
    fi
fi
print "$MBE0082" 1
 
# default configuration for host
if [[ ( $BX_PACKAGE == "bitrix-env-crm" ) || ( $POOL -gt 0 ) ]]; then
    # configure pool
    generate_ansible_inventory $ASK_USER "$BX_TYPE" "$HOSTIDENT"  || \
        print_e "$MBE0083 $LOGS_FILE"
    print "$MBE0084" 1

    # update push
    [[ $BX_PACKAGE == "bitrix-env-crm" ]] && generate_push
fi

print "$MBE0085" 1
[[ $TEST_REPOSITORY -eq 0 ]] && rm -f $LOGS_FILE
