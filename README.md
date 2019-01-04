### Block-producing-notifier is a bot that checks the number of produced blocks, the nodes status, the change in the content of the blacklist and  informed about these events in the telegram mesenger. 
### Install block-producing-notifier:  
$ cd /opt && sudo git clone https://github.com/atticlab/block-producing-notifier.git 

$ sudo chmod +x /opt/block-producing-notifier/installbot.sh 

$ /opt/block-producing-notifier/installbot.sh 
### Configure Bot:
Replace the parameters in the file notifier.conf with your parameters   
### Start Bot: 
$ sudo supervisorctl reread 

$ sudo supervisorctl update 
### Check status 
$ sudo supervisorctl 




