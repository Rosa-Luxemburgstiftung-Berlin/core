#!/bin/sh

export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

if [ "${2}" = "inet" ]; then
	OLD_ROUTER=`cat /tmp/${1}_router`
	if [ -n "${OLD_ROUTER}" ]; then
		echo "Removing states to old router ${OLD_ROUTER}" | logger -t ppp-linkup
		pfctl -i ${1} -k 0.0.0.0/0 -k ${OLD_ROUTER}/32
		pfctl -i ${1} -k ${OLD_ROUTER}/32 -k 0.0.0.0/0
	fi

	echo ${4} > /tmp/${1}_router
	echo ${3} > /tmp/${1}_ip

	if grep -q dnsallowoverride /conf/config.xml; then
		# write nameservers to file
		echo -n "" > /var/etc/nameserver_${1}
		if echo "${6}" | grep -q dns1; then
			DNS1=`echo "${6}" | awk '{print $2}'`
			echo "${DNS1}" >> /var/etc/nameserver_${1}
			route delete "${DNS1}" ${4}
			route add "${DNS1}" ${4}
		fi
		if echo "${7}" | grep -q dns2; then
			DNS2=`echo "${7}" | awk '{print $2}'`
			echo "${DNS2}" >> /var/etc/nameserver_${1}
			route delete "${DNS2}" ${4}
			route add "${DNS2}" ${4}
		fi
	fi

	daemon -f /usr/local/opnsense/service/configd_ctl.py interface newip ${1}
elif [ "${2}" = "inet6" ]; then
	echo ${4} |cut -d% -f1 > /tmp/${1}_routerv6
	echo ${3} |cut -d% -f1 > /tmp/${1}_ipv6

	if grep -q dnsallowoverride /conf/config.xml; then
		# write nameservers to file
		echo -n "" > /var/etc/nameserver_v6${1}
		if echo "${6}" | grep -q dns1; then
			DNS1=`echo "${6}" | awk '{print $2}'`
			echo "${DNS1}" >> /var/etc/nameserver_v6${1}
			route delete -inet6 "${DNS1}" ${4}
			route add -inet6 "${DNS1}" ${4}
		fi
		if echo "${7}" | grep -q dns2; then
			DNS2=`echo "${7}" | awk '{print $2}'`
			echo "${DNS2}" >> /var/etc/nameserver_v6${1}
			route delete -inet6 "${DNS2}" ${4}
			route add -inet6 "${DNS2}" ${4}
		fi
	fi

	daemon -f /usr/local/opnsense/service/configd_ctl.py interface newipv6 ${1}
fi

touch /tmp/${1}_uptime

exit 0
