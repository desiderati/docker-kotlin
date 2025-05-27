#!/bin/bash

if [[ -z ${TZ} ]]; then
  TZ="America/Sao_Paulo"
fi
echo "Configuring Timezone: ${TZ}"

ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
apt-get install -y tzdata
echo "Updating daylight savings configuration!"

# shellcheck disable=SC2002
cat /proc/meminfo
java -XX:+PrintFlagsFinal -version | grep ThreadStackSize

supervisord -c /etc/supervisor/supervisord.conf
