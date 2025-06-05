# docker-kotlin

An open-source project that provides a Docker image designed for running Kotlin-based applications.

## What This Image Does

This customized Kotlin Docker image is built on top of `openjdk:21-jdk-slim-bullseye` and includes several enhancements 
for production-ready Kotlin applications:

### Core Features
- **Java 21**: Latest LTS version of Java for optimal performance and features
- **Locale Configuration**: Preconfigured with en_US.UTF-8 locale
- **Timezone Support**: Default timezone set to America/Sao_Paulo, configurable via environment variables
- **User Management**: Creates a non-root 'kotlin' user for better security

### Development & Debugging Tools
- **Remote Debugging**: Optional JVM debugging on port 8090 (enabled via ENABLE_DEBUG)
- **Utility Tools**: Includes curl, wget, vim, and net-tools for troubleshooting
- **Wait-for-it Script**: Utility for service dependency management

### Monitoring & Observability
- **Prometheus Integration**: Built-in JMX exporter on port 9404 for metrics collection
- **Datadog APM**: Optional Datadog Java agent for application performance monitoring
- **JMX Support**: Optional JMX monitoring on port 9010 (enabled via ENABLE_JMX)

### Document Generation
- **HTML to PDF Conversion**: Includes wkhtmltopdf for generating PDF documents from HTML templates

### Process Management
- **Supervisord**: Includes [Supervisor](https://supervisord.org/) for managing and monitoring processes, 
  configured to run in non-daemon mode
- **Process Control**: Start-supervisor script available at `/opt/start-supervisor.sh` for easy process management
- **Multi-Process Applications**: Allows running multiple processes in a single container, ideal for microservices 
  or applications with multiple components

### Performance Tuning
- **Memory Management**: Configurable heap settings via JAVA_XMS and JAVA_XMX
- **CPU Optimization**: Parallel GC and ForkJoinPool thread configuration via JAVA_CPUS
- **Metaspace Configuration**: Optimized metaspace settings for Java applications

### Environment Variables
- `PROFILE`: Sets Spring profiles for application configuration
- `LOCAL_USER_ID`: Configures the user ID for the 'kotlin' user (default: 1000)
- `ENABLE_DEBUG`: Enables remote debugging (true/false)
- `ENABLE_JMX`: Enables JMX monitoring (true/false)
- `ENABLE_DD_APM`: Enables Datadog APM (true/false)
- `JAVA_OPTS`: Additional JVM options
- `JAVA_XMS`: Initial heap size
- `JAVA_XMX`: Maximum heap size
- `JAVA_CPUS`: Number of CPUs for parallel GC and ForkJoinPool

## Prerequisites

Ensure Docker is installed on your machine. 
If not, download and install it from the [Docker official website](https://www.docker.com/get-started/)

## How to build

1. Retrieve the login command to use to authenticate your Docker client to your registry:

   `docker login -u <USER> api.repoflow.io`

2. Build your Docker image using the following command. You can skip this step if your image is already built:

   `docker build --progress=plain -t kotlin:21 .`

   > Ps.: Remember to disconnect any VPM from your local machine.

3. After the build completes, tag your image, so you can push the image to your repository:

   `docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:21`
   `docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:latest`

4. Run the following command to push this image to your repository:

   `docker push api.repoflow.io/desiderati/docker/kotlin:21`
   `docker push api.repoflow.io/desiderati/docker/kotlin:latest`

### Commands

   ```
   docker build --progress=plain -t kotlin:21 .
   docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:21
   docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:latest
   docker push api.repoflow.io/desiderati/docker/kotlin:21
   docker push api.repoflow.io/desiderati/docker/kotlin:latest
   ```

## How to Use

You can use this image in your projects by referencing it in a `docker-compose.yml` file 
or directly with Docker commands.

### Docker Compose Example

```yaml
version: '3'
services:
  kotlin:
    container_name: kotlin
    image: 'api.repoflow.io/desiderati/docker/library/kotlin:21'
    ports:
      - '9090:9090'

      # Port for remote debugging
      #- '9091:8090'

      # Port for JMX monitoring (uncomment if needed)
      #- '9010:9010'

      # Port for Prometheus metrics
      #- '9404:9404'

    environment:
      # Set the user ID to match your local user (run 'id -u ${USER}' to get your ID)
      - LOCAL_USER_ID=1000

      # Enable remote debugging
      - ENABLE_DEBUG=true

      # Enable JMX monitoring (uncomment if needed)
      #- ENABLE_JMX=true

      # Enable Datadog APM (uncomment if needed)
      #- ENABLE_DD_APM=true
      #- DD_JAVA_OPTS=-Ddd.service=my-service -Ddd.env=dev

      # Spring profile configuration
      - PROFILE=dev

      # JVM configuration
      - JAVA_XMS=256m
      - JAVA_XMX=512m
      - JAVA_CPUS=1
      - JAVA_OPTS=-XX:+UseG1GC -Dfile.encoding=UTF-8

      # System configuration
      - TZ=America/Sao_Paulo
      - LOG_FILE=/opt/kotlin-app/logs/kotlin.log

    volumes:
       # Uncomment to mount supervisord configuration (optional)
       #- ./supervisord.conf:/etc/supervisor/conf.d/supervisord.conf
       
       # Mount temporary files
      - ./temp/:/tmp/

      # Mount configuration files
      - ./config/:/opt/kotlin-app/config/

      # Mount logs directory
      - ./logs/:/opt/kotlin-app/logs/

      # Mount your application JAR
      - ./path-to-your-application.jar:/opt/kotlin-app/app.jar

    # Uncomment to use supervisord instead of directly running the Java application
    #command: /opt/start-supervisor.sh
```

### Running with Docker Command

```bash
# Standard run command
docker run -d \
  --name kotlin-app \
  -p 9090:9090 \
  -e LOCAL_USER_ID=$(id -u) \
  -e JAVA_XMX=512m \
  -e JAVA_CPUS=1 \
  -v $(pwd)/path-to-your-application.jar:/opt/kotlin-app/app.jar \
  -v $(pwd)/logs:/opt/kotlin-app/logs \
  api.repoflow.io/desiderati/docker/library/kotlin:21
```

### Running with Docker Command (Using Supervisord)

```bash
docker run -d \
  --name kotlin-app \
  -p 9090:9090 \
  -e LOCAL_USER_ID=$(id -u) \
  -e JAVA_XMX=512m \
  -e JAVA_CPUS=1 \
  -v $(pwd)/path-to-your-application.jar:/opt/kotlin-app/app.jar \
  -v $(pwd)/logs:/opt/kotlin-app/logs \
  -v $(pwd)/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf \
  api.repoflow.io/desiderati/docker/library/kotlin:21 \
  /opt/start-supervisor.sh
```

### Using with Spring Boot Applications

This image is particularly well-suited for Spring Boot applications.
Build your application as an executable JAR and mount it to `/opt/kotlin-app/app.jar` in the container.

### Monitoring Your Application

1. **Prometheus Metrics**: Access metrics at http://localhost:9404/metrics, if enabled.
2. **Datadog APM**: Enable with `ENABLE_DD_APM=true` and configure with `DD_JAVA_OPTS`.
3. **JMX Monitoring**: Enable with `ENABLE_JMX=true` and connect using JConsole or similar tools.

### Debugging Your Application

When `ENABLE_DEBUG=true`, you can connect a remote debugger to port 8090.

### Using Supervisord for Process Management

This image includes [Supervisor](http://supervisord.org/), a process control system that allows you to monitor 
and control multiple processes within a single container.

#### How to Use Supervisord

1. **Create a Supervisor Configuration File**:
   Create a file named `supervisord.conf` or individual `.conf` files in the `/etc/supervisor/conf.d/` directory:

   ```ini
   [supervisord]
   nodaemon=true
   user=root

   [program:kotlin-app]
   command=java -javaagent:/opt/kotlin-app/jmx_prometheus_javaagent-1.3.0.jar=9404:/opt/kotlin-app/prometheus.yml -Xms%(ENV_JAVA_XMS)s -Xmx%(ENV_JAVA_XMX)s -Duser.timezone="$TZ" -Dlogging.config=file:/opt/kotlin-app/logback.xml -Dhazelcast.logging.type=slf4j -Djava.net.preferIPv4Stack=true --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -jar /opt/kotlin-app/app.jar
   directory=/opt/kotlin-app
   autostart=true
   autorestart=true
   stdout_logfile=/dev/stdout
   stdout_logfile_maxbytes=0
   stderr_logfile=/dev/stderr
   stderr_logfile_maxbytes=0
   ```

2. **Mount Your Configuration**:
   Add the configuration file to your container by mounting it in your `docker-compose.yml`:

   ```yaml
   volumes:
     - ./supervisord.conf:/etc/supervisor/conf.d/supervisord.conf
   ```

3. **Use the Start-Supervisor Script**:
   Override the default CMD in your docker-compose.yml to use the provided `start-supervisor.sh` script:

   ```yaml
   command: /opt/start-supervisor.sh
   ```

#### Benefits of Using Supervisord

- **Process Monitoring**: Automatically restarts processes if they crash
- **Process Control**: Start, stop, and restart processes individually
- **Logging**: Captures stdout and stderr from each process
- **Status Reporting**: Provides status information for all managed processes

For more information about Supervisor, visit the [official documentation](http://supervisord.org/).

## License

This project is licensed under the MIT License.
