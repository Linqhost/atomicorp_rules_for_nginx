#!/bin/bash
# Load up the user config settings
. $(dirname $0)/atomic_rules_for_nginx.config

# Define version
VER=v0.5

# Define hostname
HOSTNAME=`hostname`

# Define modsecurity version and file location
CURL_OUTPUT=$(curl --silent -u $CURL_USERNAME:$CURL_PASSWORD $CURL_URL)
MODSEC_VERSION=`grep 'MODSEC_VERSION' <<< "$CURL_OUTPUT" | cut -d '=' -f 2`
MODSEC_VERSION_FILE="$MODSEC_DIRECTORY/VERSION"

# Define filenames and URL's
TAR_FILE="modsec-$MODSEC_VERSION.tar.bz2"
ASC_FILE="modsec-$MODSEC_VERSION.tar.bz2.asc"
TAR_DOWNLOAD="https://updates.atomicorp.com/channels/rules/experimental/$TAR_FILE"
ASC_DOWNLOAD="https://updates.atomicorp.com/channels/rules/experimental/$ASC_FILE"

echo "+--------------------------------------------+"
echo "          Atomic rules for NGINX $VER"
echo "              by www.linqhost.nl"
echo "+--------------------------------------------+"

# Download GPG key from atomicorp
if [ ! -f $RPM_GPG/RPM-GPG-KEY.atomicorp.txt ]; then
  echo "- No Atomicorp GPG key found:"
  if [ ! -d $RPM_GPG ]; then
    mkdir -p $RPM_GPG
  fi
  echo "=> Installing the Atomicorp GPG key"
  (cd $RPM_GPG; curl --silent --remote-name https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt; $GPG -q --import RPM-GPG-KEY.atomicorp.txt)
fi

# Check if modsecurity directory exists
if [ ! -d $MODSEC_DIRECTORY ]; then
  mkdir -p $MODSEC_DIRECTORY
  restorecon -R $MODSEC_DIRECTORY > /dev/null 2>&1
fi

# The rules are pointing to /etc/asl/whitelist. So we create this directory
if [ ! -d /etc/asl ]; then
  mkdir -p /etc/asl
fi

# Check if custom whitelist exists
if [ ! -f /etc/asl/whitelist ]; then
  echo "- No whitelist file detected:"
  echo "  + Creating whitelist file"
  echo '# Completely disable mod_security for an IP-address or CIDR (one IP/CIDR per line)' > /etc/asl/whitelist
fi

UPDATE=false

# Check if Atomicorp version file exists
if [ ! -f $MODSEC_VERSION_FILE ]; then
  echo "- No version file detected:"
  # Check if version is valid integer
  if [[ $MODSEC_VERSION =~ ^-?[0-9]+$ ]]; then
    # Create the Atomicorp version file
    echo "=> Creating version file"
    echo "$CURL_OUTPUT" > $MODSEC_VERSION_FILE
    # Update Atomicorp ruleset
    UPDATE=true
  fi
else
  if [ -f $MODSEC_VERSION_FILE ]; then
    echo "+ Version file detected"
    # Check if version is valid integer
    if [[ $MODSEC_VERSION =~ ^-?[0-9]+$ ]]; then
      MODSEC_VERSION_INSTALLED=`grep 'MODSEC_VERSION' $MODSEC_VERSION_FILE | cut -d '=' -f 2`
      # Check version differences
      if [ $MODSEC_VERSION != $MODSEC_VERSION_INSTALLED ]; then
        # Update Atomicorp version file
        echo "$CURL_OUTPUT" > $MODSEC_VERSION_FILE
        # Update Atomicorp ruleset
        UPDATE=true
      else
        echo "- No update available"
      fi
    fi
  fi
fi

if [ $UPDATE = true ]; then
  echo "=> Begin updating Atomicorp ruleset"
  echo "=> Downloading Atomicorp ruleset:"

  echo "=> Download $TAR_DOWNLOAD"
  (cd /tmp/; curl --silent -u $CURL_USERNAME:$CURL_PASSWORD --remote-name $TAR_DOWNLOAD)

  echo "=> Download $ASC_DOWNLOAD"
  (cd /tmp/; curl --silent -u $CURL_USERNAME:$CURL_PASSWORD --remote-name $ASC_DOWNLOAD)

  # Check GPG signature
  echo "=> Checking GPG signature $ASC_FILE:"
  $GPG -q --verify /tmp/$ASC_FILE > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "  + Valid signature"

    echo "=> Extracting $TAR_FILE"
    tar xjf /tmp/$TAR_FILE -C /tmp/

    # Cleanup old ruleset but leave the Atomicorp version file
    find $MODSEC_DIRECTORY -type f -iname '*_asl_*' -delete

    # Move new ruleset to modsecurity directory
    mv -f /tmp/modsec/* $MODSEC_DIRECTORY
    restorecon -R $MODSEC_DIRECTORY > /dev/null 2>&1

    # Check Nginx config
    NGINX=`which nginx`

    echo "=> Reload NGINX"
    $NGINX -t

    if [ $? -eq 0 ]; then
      echo "+ Restarting Nginx"

      shopt -s nocasematch

      case "$SERVICE_MANGER" in
        "init")
          /etc/init.d/nginx reload
        ;;
        "systemd")
          systemctl reload nginx
        ;;
      esac
    else
      echo "  - Could not restart Nginx"
      echo "Unable to restart nginx" | mail -s "[Failed] Updating Atomicorp ruleset on $HOSTNAME" $EMAIL_ADDRESS
    fi

  else
    echo "  - Problem with signature"
    echo "Invalid signature" | mail -s "[Failed] Updating Atomicorp ruleset on $HOSTNAME" $EMAIL_ADDRESS
  fi

fi