#!/bin/bash
source common.sh

# check if simrunner-jar exists
simrunner_file=$(find ./bin/tools/ -name "simulation-runner-*.jar")
if [ "$simrunner_file" == "" ]; then
        echo "The Simulation Runner is only available with a commercial license of VSimRTI. Please contact vsimrti@fokus.fraunhofer.de to get a commercial license."
else
        # create and run command
        cmd="java -cp .:${core}:${libs}:${ambassadors}:${ambassador_libs}:${tools} -Djava.library.path=./lib com.dcaiti.vsimrti.start.Starter $*"
        $cmd
fi