FROM openjdk:21-jdk-slim-bullseye

# Set the locale (en_US.UTF-8)
RUN apt-get update && apt-get install -y locales
RUN echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
RUN rm "/etc/locale.gen"
RUN dpkg-reconfigure --frontend noninteractive locales

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US:en
RUN locale -a

# Timezone configuration (Updating daylight savings)
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y tzdata
RUN date

# Configure the netstat and curl comnands which will be used by health check.
RUN apt-get update \
 && apt-get install -y --no-install-recommends apt-utils apt-transport-https curl net-tools wget \
 && apt-get install -y vim \
 && apt-get clean \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# Setup gosu for easier command execution.
ENV GOSU_VERSION 1.17
RUN set -eux; \
    # Save list of currently installed packages for later, so we can clean up.
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates gnupg wget; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
    # Verify the signature.
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
    # Clean up fetch dependencies.
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	chmod +x /usr/local/bin/gosu; \
    # Verify that the binary works.
	gosu --version; \
	gosu nobody true

# Configures the wk<html>toPDF.
COPY wkhtmltox_0.12.6.1-2.bullseye_amd64.deb /opt/
RUN apt-get update -y \
 && apt-get install -y libjpeg62-turbo libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base fontconfig \
 && dpkg -i /opt/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb

# Configures the Docker image with Prometheus metrics.
COPY jmx_prometheus_javaagent-0.16.1.jar /opt/kotlin-app/
COPY prometheus.yml /opt/kotlin-app/

# Datadog Trace Agent.
COPY dd-java-agent.jar /opt/kotlin-app/
LABEL "com.datadoghq.ad.logs"='[{"source": "kotlin", "service": "kotlin", "log_processing_rules": [{"type": "mask_sequences", "name": "remove_ansi_color_codes", "pattern" : "\\x1b\\[[0-9;]*m", "replace_placeholder" : ""}, {"type": "multi_line", "name": "log_start_with_hour", "pattern" : "(\\x1b\\[[0-9;]*m\\s*)*([0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])[.,][0-9]{3}"}]}]'

# Installs the supervisord and leaves it available to be used by anyone who wants to use it.
RUN apt-get update \
 && apt-get install -y supervisor \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

ADD start-supervisor.sh /opt/start-supervisor.sh
RUN chmod +x /opt/start-supervisor.sh

# Removing unused python 2.* and 3.* version due Vulnerability CVE-2021-3177
# RUN apt-get autoremove python2.* -y
# RUN apt-get autoremove libpython2.* -y
# RUN dpkg --purge libpython2.7-minimal
# RUN dpkg --purge python2.7-minimal

# Updating perl to release 5.28.1-6+deb10u1 version due Vulnerability CVE-2020-10878
# RUN apt-get install libperl5.28 -y

# Default variables to be used by docker-compose.yml.
ENV PROFILE ""
ENV LOCAL_USER_ID 1000
ENV ENABLE_DEBUG false

ENV JAVA_OPTS ""
ENV JAVA_XMS ""
ENV JAVA_XMX ""
ENV JAVA_CPUS ""

# Create default directories.
RUN mkdir -p /opt/kotlin-app/

# Execution configurations.
COPY wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /usr/local/bin/wait-for-it

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

ENV HOME /home/kotlin/

WORKDIR /opt/kotlin-app/

CMD java -javaagent:/opt/kotlin-app/jmx_prometheus_javaagent-0.16.1.jar=9404:/opt/kotlin-app/prometheus.yml $JAVA_OPTS -jar app.jar
