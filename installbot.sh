#!/bin/bash
echo "Install block producing notifier";
sudo chown -R eosuser:eosuser /opt/block-producing-notifier;
sudo chmod +x /opt/block-producing-notifier/bl_prod_notifier.sh;
sudo chmod +x /opt/theBlacklist/check_blacklist_bot.sh;
echo "Install supervisor";
sudo touch /etc/supervisor/conf.d/eosnotif.conf;
sudo apt-get install -y supervisor \
&& sudo echo '[program:EOS-block-producing-notifier]
command=/bin/bash -c '/opt/block-producing-notifier/bl_prod_notifier.sh'
stdout_logfile=/var/log/supervisor/EOS-block-producing-notifier_stdout.log
stderr_logfile=/var/log/supervisor/EOS-block-producing-notifier_stderr.log
logfile_maxbytes=50MB
logfile_backups=2
directory=/opt/block-producing-notifier
autostart=true
autorestart=true
user=eosuser
numprocs=1' > /etc/supervisor/conf.d/eosnotif.conf;
echo "DONE";
