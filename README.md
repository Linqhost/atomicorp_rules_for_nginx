# Atomicorp rules for NGINX

Downloads new ModSecurity Atomicorp (experimental) rules for nginx. 

## Disclaimer
ModSecurity for NGINX is in a very experimental state. Don't use it in a production environment! If you really want to use ModSecurity we
advise you to use the [refactoring branch of ModSecurity](https://github.com/SpiderLabs/ModSecurity/tree/nginx_refactoring) which works
pretty well.

## Installation
Put the script (and +x file)  somewhere and add a crontab entry. For example:

```
# Run script every day at 3:00 am
0 3 * * * /root/scripts/atomic_rules_for_nginx.sh > /dev/null 2>&1
```

## Requirements
* Nginx 1.9 with ModSecurity
* Subscription for the Atomic rules
* systemd or sysVinit