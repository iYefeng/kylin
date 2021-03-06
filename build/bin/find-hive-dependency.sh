#!/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

client_mode=`sh ${KYLIN_HOME}/bin/get-properties.sh kylin.hive.client`
hive_env=

if [ "${client_mode}" == "beeline" ]
then
    beeline_params=`sh ${KYLIN_HOME}/bin/get-properties.sh kylin.hive.beeline.params`
    hive_env=`beeline ${beeline_params} --outputformat=dsv -e set | grep 'env:CLASSPATH'`
else
    hive_env=`hive -e set | grep 'env:CLASSPATH'`
fi

hive_classpath=`echo $hive_env | grep 'env:CLASSPATH' | awk -F '=' '{print $2}'`
arr=(`echo $hive_classpath | cut -d ":"  --output-delimiter=" " -f 1-`)
hive_conf_path=
hive_exec_path=

if [ -n "$HIVE_CONF" ]
then
    echo "HIVE_CONF is set to: $HIVE_CONF, use it to locate hive configurations."
    hive_conf_path=$HIVE_CONF
fi

for data in ${arr[@]}
do
    result=`echo $data | grep -e 'hive-exec[a-z0-9A-Z\.-]*.jar'`
    if [ $result ]
    then
        hive_exec_path=$data
    fi

    # in some versions of hive config is not in hive's classpath, find it separately
    if [ -z "$hive_conf_path" ]
    then
        result=`echo $data | grep -e 'hive[^/]*/conf'`
        if [ $result ]
        then
            hive_conf_path=$data
        fi
    fi
done

if [ -z "$hive_conf_path" ]
then
    echo "Couldn't find hive configuration directory. Please set HIVE_CONF to the path which contains hive-site.xml."
    exit 1
fi

# in some versions of hive hcatalog is not in hive's classpath, find it separately
if [ -z "$HCAT_HOME" ]
then
    echo "HCAT_HOME not found, try to find hcatalog path from hadoop home"
    hadoop_home=`echo $hive_exec_path | awk -F '/hive.*/lib/' '{print $1}'`
    hive_home=`echo $hive_exec_path | awk -F '/lib/' '{print $1}'`
    is_aws=`uname -r | grep amzn`
    if [ -d "${hadoop_home}/hive-hcatalog" ]; then
      hcatalog_home=${hadoop_home}/hive-hcatalog
    elif [ -d "${hadoop_home}/hive/hcatalog" ]; then
      hcatalog_home=${hadoop_home}/hive/hcatalog
    elif [ -d "${hive_home}/hcatalog" ]; then
      hcatalog_home=${hive_home}/hcatalog
    elif [ -n is_aws ] && [ -d "/usr/lib/oozie/lib" ]; then
      # special handling for Amazon EMR, where hcat libs are under oozie!?
      hcatalog_home=/usr/lib/oozie/lib
    else 
      echo "Couldn't locate hcatalog installation, please make sure it is installed and set HCAT_HOME to the path."
      exit 1
    fi
else
    echo "HCAT_HOME is set to: $HCAT_HOME, use it to find hcatalog path:"
    hcatalog_home=${HCAT_HOME}
fi

hcatalog=`find -L ${hcatalog_home} -name "hive-hcatalog-core[0-9\.-]*.jar" 2>&1 | grep -m 1 -v 'Permission denied'`

if [ -z "$hcatalog" ]
then
    echo "hcatalog lib not found"
    exit 1
fi


hive_lib=`find -L "$(dirname $hive_exec_path)" -name '*.jar' ! -name '*calcite*' -printf '%p:' | sed 's/:$//'`
hive_dependency=${hive_conf_path}:${hive_lib}:${hcatalog}
echo "hive dependency: $hive_dependency"
export hive_dependency
