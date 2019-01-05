#!/bin/bash
eos_proc_block ()
{
CLSTAT=$(ls $DATADIR | grep cleos.sh$ | wc -l)
if [ "$CLSTAT" -eq "1" ]; then
        BLOCKS=`$DATADIR/cleos.sh get table eosio eosio producers -l 10000 |grep -A 7 atticlabeosb | grep '"unpaid_blocks":' | awk -F "," '{print $1}' | awk '{print $2}'`
else
	NODEOSBINDIR=$(cat notifier.conf | grep nodeosbindir | awk -F "=" '{print $2}')
	NODEHOST=$(cat notifier.conf | grep nodehost | awk -F "=" '{print $2}')
	WALLETHOST=$(cat notifier.conf | grep wallethost | awk -F "=" '{print $2}')
	BLOCK=$($NODEOSBINDIR/cleos -u http://$NODEHOST --wallet-url http://$WALLETHOST get table eosio eosio producers -l 10000 |grep -A 7 atticlabeosb | grep '"unpaid_blocks":' | awk -F "," '{print $1}' | awk '{print $2}')
fi
if [ -z $BLOCKS ]; then
        echo "node is down"
else
        echo Produced blocks:$BLOCKS
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="🔨Produced blocks: $BLOCKS"
fi
}

eoscheck ()
{
NAME=`echo $IP |awk -F ";" '{print $1}'`
IPN=`echo $IP | awk -F ";" '{print $2}'`
BLEOS=`curl --insecure --connect-timeout 4 -s http://$IPN/v1/chain/get_info |jq -r ".head_block_num"`
if [ -z $BLEOS ]; then
        echo "node is down"
else
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="🗿HeadBlock: $BLEOS node: $NAME  http://$IPN/v1/chain/get_info"
fi
}

check_blacklist()
{
GETHASH=$($CHECKBLACKLIST);
if [ -n "$GETHASH" ]; then
if [ "$GETHASH" = "serverdown" ]; then
   echo "server down"
else
SUCCESS=`$CHECKBLACKLIST | grep success | awk '{print $1}'`
if [ "$SUCCESS" == "success:" ]; then
        HASH=`$CHECKBLACKLIST | grep success | awk '{print $2}'`
        echo Blacklist hash:$HASH
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="🛡 Blacklist hash: $HASH"
else
        ERR=`$CHECKBLACKLIST`
        echo $ERR
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="📮 $($CHECKBLACKLIST)"
fi
fi
fi
}

check_change_blacklist()
{
EOSHASH="$BOTDIR/eos-hash"
HASHFILE=$(cat $BOTDIR/eos-hash)
if [ -z "$HASHFILE" ]; then
        echo "22" > ${EOSHASH};
fi
GETHASH=$($CHECKBLACKLIST);
if [ -n "$GETHASH" ]; then
if [ "$GETHASH" = "serverdown" ]; then
   echo "server down"
else
SUCCESS=`$CHECKBLACKLIST | grep success | awk '{print $1}'`
if [ "$SUCCESS" == "success:" ]; then
        HASH=`$CHECKBLACKLIST | grep success | awk '{print $2}'`
        echo Blacklist hash:$HASH
if [ "$HASH" != "$HASHFILE" ]; then
        echo "Hash is changed. The old hash is $HASHFILE. The new hash is $HASH."
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="📮 Hash is changed. The old hash is $HASHFILE. The new hash is $HASH."
        echo $HASH > ${EOSHASH};
fi
else
        ERR=`$CHECKBLACKLIST`
        echo $ERR
        curl -s -X POST https://api.telegram.org/bot$BOTKEY/sendMessage -d chat_id=$CHATID -d text="📮 $($CHECKBLACKLIST)"
fi
fi
fi
}
BOTDIR=$(cat notifier.conf | grep botdir | awk -F "=" '{print $2}')
DATADIR=$(cat notifier.conf | grep eosdatadir | awk -F "=" '{print $2}')
CHECKBLACKLIST=$BOTDIR/check_blacklist_bot.sh
CHATID=$(cat notifier.conf | grep chatid | awk -F "=" '{print $2}')
BOTKEY=$(cat notifier.conf | grep botkey | awk -F "=" '{print $2}')
NODEIP=$(cat $BOTDIR/eos-ips)
while true; do
        eos_proc_block
        check_blacklist
        check_change_blacklist
        for IP in $NODEIP
        do
                eoscheck $IP
        done
        sleep 300;
done

