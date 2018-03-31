#!/bin/bash
set -e

source common.sh


#javaMemorySizeXms="-Xms100m"
javaMemorySizeXms=""

#javaMemorySizeXmx="-Xmx4096m"
javaMemorySizeXmx=""


#javaProxySettings="-Dhttps.proxyHost=webcache.example.com -Dhttps.proxyPort=8800"
javaProxySettings="-Djava.net.useSystemProxies=true"

# More information on Java Proxy configuration can be found at
# http://docs.oracle.com/javase/7/docs/technotes/guides/net/proxies.html 

# create and run command
cmd="java ${javaProxySettings} ${javaMemorySizeXms} ${javaMemorySizeXmx} -cp .:${core}:${libs}:${ambassadors}:${ambassador_libs}:./etc -Djava.library.path=./lib com.dcaiti.vsimrti.start.XMLConfigRunner $*"
$cmd

