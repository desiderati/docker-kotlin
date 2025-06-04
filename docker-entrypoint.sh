#!/bin/bash
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

# Garante que não terão quebras de linha na variável JAVA_OPTS.
JAVA_OPTS=$(echo "$JAVA_OPTS" | sed ':a;N;$!ba;s/\n/ /g')

# - A parte `:a;N;$!ba;` é um loop que irá ler todo o texto, incluindo as quebras de linha.
# - A parte `s/\n/ /g` substitui todas as quebras de linha (\n) por espaços.

# O loop `:a;N;$!ba;` no comando `sed` é usado para lidar com múltiplas linhas de entrada.
# Aqui está o que cada parte faz:
#
# - `:a` cria um rótulo chamado 'a'.
# - `N` adiciona a próxima linha de entrada ao padrão de espaço do comando `sed`.
# - `$!ba` se não for a última linha de entrada, vá para o rótulo 'a'.
#
# Este loop é necessário porque, por padrão, o `sed` lê e processa a entrada linha por linha.
# Se você tem várias linhas de entrada e quer fazer uma substituição que abrange várias linhas
# (como substituir quebras de linha por espaços), você precisa primeiro dizer ao `sed` para ler
# todas as linhas de entrada de uma vez. Isso é o que o loop `:a;N;$!ba;` faz.
#
# Se você sabe que sua entrada sempre será uma única linha, você pode omitir o loop e usar apenas `s/\n/ /g`
# para substituir as quebras de linha por espaços. No entanto, se sua entrada pode ter várias linhas,
# é melhor usar o loop para garantir que todas as quebras de linha sejam substituídas corretamente.

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
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false" # Somente é acessado pela rede interna.
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote.local.only=true"
  # Como o ECS somente tem uma única interface de rede, não precisamos definir este valor!
  # JAVA_OPTS="${JAVA_OPTS} -Djava.rmi.server.hostname=xxx.xxx.xxx.xxx"
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
