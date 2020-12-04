set -euv

# cat adblock.sources | jq -c 'keys' | tr -d '"' | tr ',' ' ' | sed 's,^\[,#declare -a adl=(,; s,\]$,),' >>adblock.list.sh

[ -s 'dnsmasq-adblock.conf' ] && exit 1

. adblock.list.sh

i=0
wget -qc https://github.com/openwrt/packages/raw/master/net/adblock/files/adblock.sources
for ad in "${adl[@]}"; do
    #cat adblock.sources | jq ".$ad | (.url,.rule)" | sed '1d; $d; s/",$// ; s/^  "//' | while IFS=$'\n' read url; read rule;
    cat adblock.sources | jq ".$ad | (.url,.rule)" | sed 's/^"//; s/"$//' | while IFS=$'\n' read url; read rule;
    do
        echo "$url"
        echo "$rule"
        # https://github.com/openwrt/packages/blob/master/net/adblock/files/adblock.sh#L1296
        # hosts one by line starts at the end of this line
        wget -q -O - "$url" | awk "$rule" | sed "s/\r//g" | awk 'BEGIN{FS="."}{for(f=NF;f>1;f--)printf "%s.",$f;print $1}' | \
            sed -e "s,^,address=/,; s,$,/," | pv -rab >> dnsmasq-adblock.conf
        echo
        i=$(( $i + 1 ))
    done
done

sort -u dnsmasq-adblock.conf >dnsmasq-adblock.conf.sort && mv -v dnsmasq-adblock.conf.sort dnsmasq-adblock.conf
wc -l dnsmasq-adblock.conf

