#!/bin/bash

# make sure to clean up old license information
if [ -f systemInfo.txt ]; then
	rm systemInfo.txt
fi

if [ -f vsimrti.dat ]; then
	rm vsimrti.dat
fi

if [ -f vsimrti-license.lcs ]; then
	rm vsimrti-license.lcs
fi

# now generate new ones
./vsimrti.sh -u initial -c ./scenarios/Tiergarten/vsimrti/vsimrti_config.xml >/dev/null 2>&1

# print notice to user
echo
echo Created license request prerequisites
echo Please send the systemInfo.txt to vsimrti@fokus.fraunhofer.de for activation.
echo  
