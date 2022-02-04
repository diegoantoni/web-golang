# web-golang

# Build image to be used in the build process by openshift:

* `time DOCKER_BUILDKIT=1 docker build -t $NOMEIMAGEM --no-cache . `

# Upload this image to DockerHub:

* `docker tag repo_name/image_name:tag `

* `docker push repo_name/image_name:tag `