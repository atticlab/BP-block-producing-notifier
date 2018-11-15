#!/bin/bash

default_api="https://api.eoslaomao.com"
#default_api="https://api1.eosasia.one"
#default_api="http://62.149.9.180:8888"
default_config="/opt/EOSmainNet/config.ini"
api=${default_api}
config=${default_config}

UNAME=`uname`

if [[ $UNAME == 'Darwin' ]]; then
  checker='shasum -a 256'
else
  checker='sha256sum'
fi

init() {
    [ "$1" != "" ] && api=$1
    [ "$2" != "" ] && config=$2
    [ ! -f ${config} ] && echo "please check config path(${config})" && exit 1
}

get_chain_actor_list() {
    url="${api}/v1/chain/get_table_rows"
    chain_actor_list_all=`curl -s ${url} -X POST -d '{"scope":"theblacklist", "code":"theblacklist", "table":"theblacklist", "json": true, "limit": 100 \
 }' | jq '.rows[] | select(.action=="add") | .accounts[]' | sed -e 's|"||g' | sort | uniq`
    chain_actor_list_rem=`curl -s ${url} -X POST -d '{"scope":"theblacklist", "code":"theblacklist", "table":"theblacklist", "json": true, "limit": 100 \
 }' | jq '.rows[] | select(.action=="remove") | .accounts[]' | sed -e 's|"||g' | sort | uniq`
    for i in $chain_actor_list_all
     do
      chain_actor_list="$chain_actor_list""actor-blacklist=$i""\n";
     done
    for j in $chain_actor_list_rem
     do
      chain_actor_list=`echo $chain_actor_list | sed "s/actor-blacklist=$j..//g" | sort`
     done
}

get_local_actor_list() {
    local_actor_list=`cat ${config} | grep actor-black | grep -v "#" |egrep -o '\w+$'| sort | uniq | sed 's/^/actor-blacklist=/g'`
}

check_diff() {
    diff <(printf "${chain_actor_list}") <(echo "${local_actor_list}")|sed 's/</chain -/g' | sed 's/>/local -/g' | egrep 'chain -|local -'
}

# check local and theblacklist actor-blacklist hash
check_hash() {
    local_hash=`cat ${config} | grep actor-black | grep -v "#" | sort | uniq | tr -d " " | ${checker}`
    # get hash from table theblacklist
    chain_hash=`printf "${chain_actor_list}" | ${checker}`
    if [ "${local_hash}" == "${chain_hash}" ];then
        echo "success: ${chain_hash}"
    else
        echo "local: ${local_hash}"
        echo "chain: ${chain_hash}"
    fi
}

main() {
    init $@
    get_chain_actor_list
    get_local_actor_list
    check_diff
    check_hash
}

main $@


