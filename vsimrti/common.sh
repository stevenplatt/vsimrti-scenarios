#!/bin/bash
# after VSimRTI is deployed to <dir> set the parameter dir=<dir>
dir=./bin

# core
dir_core=${dir}/core
tmp=`ls ${dir_core} | grep jar`
core=${dir_core}/${tmp//[^A-Za-z0-9\-\.]/:${dir_core}/}

# libs
dir_libs=${dir}/lib
tmp=`ls ${dir_libs} | grep jar`
libs=${dir_libs}/${tmp//[^A-Za-z0-9\-\.]/:${dir_libs}/}

# ambassadors and their libs
dir_ambassadors=${dir}/ambassadors
tmp=`ls ${dir_ambassadors} | grep jar`
ambassadors=${dir_ambassadors}/${tmp//[^A-Za-z0-9\-\.]/:${dir_ambassadors}/}
tmp=`ls ${dir_ambassadors}/lib | grep jar`
ambassador_libs=${dir_ambassadors}/lib/${tmp//[^A-Za-z0-9\-\.]/:${dir_ambassadors}/lib/}

# tools

# The tools/ folder needs special handling since it contains tools
# which are intended for stand-alone usage, e.g. bundle their own
# logger dependencies and other stuff that doesn't belong into the VSimRTI classpath

# The exlude variable holds projects that are excluded from VSimRTI classpath.
# To add another one, use regexp syntax and combine them with |, for example:
#   exclude=".*scenario-convert.*|.*foo.*" 
# to exclude scenario-convert and a project called foo
exclude=".*scenario-convert.*";

while IFS=  read -r -d $'\0'; do
    if [[ $REPLY =~ ^($exclude)$ ]]; then
        continue
    fi 
    tools+=$REPLY
    tools+=':'
done < <(find bin/tools -name "*.jar" -print0)
