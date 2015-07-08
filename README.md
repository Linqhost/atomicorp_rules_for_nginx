# Atomicorp rules for NGINX

Downloads new ModSecurity Atomicorp (experimental) rules for nginx. The script downloads and validates the package. If all is fine then NGINX will be reloaded
Please read the disclaimer and requirements before using this tool.

## Disclaimer
We presume that your already using ModSecurity with NGINX and have the rules configured already. If your starting from scratch and you really
want to shave this yak: ModSecurity for NGINX is in a very experimental state. Don't use it in a production environment! If you really want to use ModSecurity we
advise you to use the [refactoring branch of ModSecurity](https://github.com/SpiderLabs/ModSecurity/tree/nginx_refactoring) which works pretty well.

## Support
Using this script is on your risk. Linqhost cannot be held liable for any damage and such ... Also Linqhost cannot give any support on the use or configuration of this script. Ofcourse you are free to report bugs or fork it :-)

## Installation
First change the settings in the .config file for your personal needs and make the script executable. After this you can for example add it to the crontab so it's executed periodicly:
```
# Run script every day at 3:00 am
0 3 * * * /root/scripts/atomic_rules_for_nginx.sh > /dev/null 2>&1
```

## Requirements
* Nginx 1.9 with ModSecurity
* Subscription for the Atomic rules
* systemd or sysVinit