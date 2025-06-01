docker build --progress=plain -t kotlin:21 .
docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:21
docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:latest
docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:21
docker tag kotlin:21 api.repoflow.io/desiderati/docker/kotlin:latest
docker push api.repoflow.io/desiderati/docker/kotlin:21
docker push api.repoflow.io/desiderati/docker/kotlin:latest
