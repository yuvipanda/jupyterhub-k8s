#!/bin/bash
# Builds and pushes a given image to gcr.io + all nodes in current kubectl context
set -e

# Bail if we're on a dirty git tree
if ! git diff-index --quiet HEAD; then
    echo "You have uncommited changes. Please commit them before building and populating"
    echo "This helps ensure that all docker images are traceable back to a git commit"
    echo "If you push anyway Yuvi will be sad :("
    exit 1
fi

IMAGE="$1"
GIT_REV=$(git log -n 1 --pretty=format:%h -- ${IMAGE})
TAG="${GIT_REV}"

if [ "${IMAGE}" == "user" ]; then
    USER_IMAGE_TYPE="${2}"
    DOCKERFILE="Dockerfile.${USER_IMAGE_TYPE}"
    IMAGE_SPEC="gcr.io/data-8/jupyterhub-k8s-${IMAGE}-${USER_IMAGE_TYPE}:${TAG}"
else
    DOCKERFILE="Dockerfile"
    IMAGE_SPEC="gcr.io/data-8/jupyterhub-k8s-${IMAGE}:${TAG}"
fi

cd ${IMAGE}
docker build -t ${IMAGE_SPEC} -f ${DOCKERFILE} .
gcloud docker -- push ${IMAGE_SPEC}

echo "Pushed ${IMAGE_SPEC}"

echo "Run ./populate.bash ${IMAGE_SPEC} to populate all nodes in current context with this image"
