# docker-kotlin

An open-source project that provides a Docker image designed for running Kotlin-based applications.

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

### Example

   ```
   docker build --progress=plain -t kotlin:21 .
   docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:21
   docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:latest
   docker push api.repoflow.io/desiderati/docker/kotlin:21
   docker push api.repoflow.io/desiderati/docker/kotlin:latest
   ```
