#!/bin/bash

set -e  # Exit on error

IMAGE_NAME="idhavalmehta/devcontainer-base"
WORKSPACE_FOLDER="./src/devcontainer-base"
DEVCONTAINER_CONFIG="$WORKSPACE_FOLDER/.devcontainer/devcontainer.json"
DEBIAN_VERSION="" # Will be set by check_debian_version

info() {
    echo "⚪ $@"
}

warn() {
    echo "🟡 $@"
}

error() {
    echo "🔴 $@"
}

success() {
    echo "🟢 $@"
}

check_docker_login() {
    output=$(docker login)
    if [[ "$output" == *"Login Succeeded"* ]]; then
        success "Docker is logged in"
    else
        error "Docker is not logged in"
        info "Please login with: docker login"
        exit 1
    fi
}

check_debian_version() {
    if [ ! -f "$DEVCONTAINER_CONFIG" ]; then
        error "Not found: $DEVCONTAINER_CONFIG"
        exit 1
    fi

    DEBIAN_VERSION=$(jq -r '.build.args.VARIANT' "$DEVCONTAINER_CONFIG")
    if [ -z "$DEBIAN_VERSION" ] || [ "$DEBIAN_VERSION" == "null" ]; then
        error "Could not determine Debian version from devcontainer.json"
        exit 1
    fi

    success "Debian version: $DEBIAN_VERSION"
}

build_devcontainer_image() {
    LATEST_TAG="$IMAGE_NAME:latest"
    DEBIAN_TAG="$IMAGE_NAME:$DEBIAN_VERSION"

    info "Building Docker image using Dev Containers CLI..."
    devcontainer build --workspace-folder $WORKSPACE_FOLDER --image-name $LATEST_TAG
    docker tag $LATEST_TAG $DEBIAN_TAG
}

push_devcontainer_image() {
    info "Pushing images to registry..."
    docker push $LATEST_TAG
    docker push $DEBIAN_TAG

    success "Done! Image pushed with tags: $LATEST_TAG, $DEBIAN_TAG"
}

main() {
    check_docker_login
    check_debian_version
    build_devcontainer_image
    push_devcontainer_image
}

main