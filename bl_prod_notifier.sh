#!/bin/bash
eos_proc_block ()
{
BLOCKS=`$DATADIR/cleos.sh get table eosio eosio producers -l 10000 |grep -A 7 atticlabeosb | grep '"unpaid_blocks":' | awk -F "," '{print $1}' | awk '{print $2}'`
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
}

check_change_blacklist()
{
EOSHASH="/opt/BP-block-producing-notifier/eos-hash"
HASHFILE=`cat /opt/BP-block-producing-notifier/eos-hash`
if [ -z $HASHFILE ]; then
        echo "22" > ${EOSHASH};
fi
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
}

DATADIR=/opt/EOSmainNet
CHECKBLACKLIST=/opt/BP-block-producing-notifier/check_blacklist_bot.sh
CHATID=111111111
BOTKEY=222222222:AAFGzXt5kTy111111-51s1111111j_11111
NODEIP=`cat /opt/BP-block-producing-notifier/eos-ips`
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

