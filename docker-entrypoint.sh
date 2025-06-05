#!/bin/bash
#
# Copyright (c) 2025 - Felipe Desiderati
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Exit immediately if a command exits with a non-zero status.
set -e

if ! id -u kotlin >/dev/null 2>&1; then
  USER_ID=${LOCAL_USER_ID:-1000}
  echo "Adding 'kotlin' user..."
  useradd -m -d /home/kotlin -u "${USER_ID}" -s /bin/bash kotlin
  chown -R "${USER_ID}":"${USER_ID}" /home/kotlin
  chown -R "${USER_ID}":"${USER_ID}" /opt
  echo "User 'kotlin' added with success!"

  if [[ -z ${TZ} ]]; then
    TZ="America/Sao_Paulo"
  fi
  echo ""
  echo "Configuring Timezone: ${TZ}"

  ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone
  apt-get update && apt-get install -y tzdata
  echo "Updating daylight savings configuration!"

  echo ""
  echo "Locales configured:"
  locale -a
fi

# Ensures there are no line breaks in the JAVA_OPTS variable.
JAVA_OPTS=$(echo "$JAVA_OPTS" | sed ':a;N;$!ba;s/\n/ /g')

# - The `:a;N;$!ba;` part is a loop that reads the entire input, including line breaks.
# - The `s/\n/ /g` part replaces all line breaks (\n) with spaces.

# The `:a;N;$!ba;` loop in the `sed` command is used to handle multi-line input.
# Here's what each part does:
#
# - `:a` creates a label named 'a'.
# - `N` appends the next input line to the pattern space.
# - `$!ba` if not the last line, go back to label 'a'.
#
# This loop is necessary because, by default, `sed` processes input line by line.
# If your input contains multiple lines and you want to apply a substitution across
# all of them (e.g., replacing line breaks with spaces), you must first instruct
# `sed` to load the entire input at once. That’s what the loop does.
#
# If you're sure your input will always be a single line, you can skip the loop
# and use just `s/\n/ /g`. However, if multiple lines are possible, it’s safer
# to use the loop to ensure proper replacement of all line breaks.

if [[ ${ENABLE_DD_APM} = true ]]; then
  echo "Enabling Datadog Application Performance Monitoring..."
  JAVA_OPTS="-javaagent:/opt/kotlin-app/dd-java-agent-1.49.0.jar $DD_JAVA_OPTS $JAVA_OPTS"
fi

if [[ ${ENABLE_DEBUG} = true ]]; then
  echo "Enabling Debug Mode on Port: 8090"
  JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8090"
fi

if [[ ${ENABLE_JMX} = true ]]; then
  echo "Enabling JMX Agent on Port: 9010"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.port=9010"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.rmi.port=9010"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false" # Only accessible from the internal network.
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.local.only=true"
  # Since ECS only has a single network interface, we don't need to define this value!
  #JAVA_OPTS="${JAVA_OPTS} -Djava.rmi.server.hostname=xxx.xxx.xxx.xxx"
  JAVA_OPTS="${JAVA_OPTS} -Djava.net.preferIPv4Stack=true"
fi

if [[ -n ${PROFILE} ]]; then
  echo "Configuring application to run with profile: ${PROFILE}"
  JAVA_OPTS="${JAVA_OPTS} -Dspring.profiles.active=${PROFILE} -Dprofile=${PROFILE}"
fi

if [[ -n ${JAVA_XMS} ]]; then
  JAVA_OPTS="${JAVA_OPTS} -Xms${JAVA_XMS}"
fi

if [[ -n ${JAVA_XMX} ]]; then
  JAVA_OPTS="${JAVA_OPTS} -Xmx${JAVA_XMX}"
fi

if [[ -n ${JAVA_CPUS} ]]; then
  JAVA_OPTS="${JAVA_OPTS} -XX:ParallelGCThreads=${JAVA_CPUS} -XX:ConcGCThreads=${JAVA_CPUS}"
  JAVA_OPTS="${JAVA_OPTS} -Djava.util.concurrent.ForkJoinPool.common.parallelism=${JAVA_CPUS}"
fi

JAVA_OPTS="${JAVA_OPTS} -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m"
JAVA_OPTS="${JAVA_OPTS} --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.lang=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.nio=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/sun.nio.ch=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.management/sun.management=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED"
export JAVA_OPTS

echo "Running Kotlin App with following Options: ${JAVA_OPTS}"

# shellcheck disable=SC2002
cat /proc/meminfo
java -XX:+PrintFlagsFinal -version | grep ThreadStackSize

exec gosu kotlin "$@"
