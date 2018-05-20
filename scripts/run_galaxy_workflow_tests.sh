#!/bin/bash

: ${PLANEMO_TARGET:="planemo==0.50.1"}
: ${PLANEMO_OPTIONS:=""}  # e.g. PLANEMO_OPTIONS="--verbose"
: ${PLANEMO_PROFILE_NAME:="wxflowtest"}
: ${PLANEMO_SERVE_PORT:="9019"}
: ${PLANEMO_GALAXY_BRANCH:="master"}
: ${PLANEMO_TEST_STYLE:="serve_and_test"}  # profile_serve_and_test, serve_and_test, docker_serve_and_test, test, docker_test
: ${PLANEMO_SERVE_DATABASE_TYPE:="postgres"}  # used if not using Docker with PLANEMO_TEST_STYLE
: ${PLANEMO_DOCKER_GALAXY_IMAGE:="quay.io/bgruening/galaxy:18.01"}  # used if used Docker with PLANEMO_TEST_STYLE

GALAXY_URL="http://localhost:$PLANEMO_SERVE_PORT"

# Ensure Planemo is installed.
if [ ! -d .venv ]; then
    virtualenv .venv
    . .venv/bin/activate
    pip install -U pip
    # Intentionally expand wildcards in PLANEMO_TARGET.
    shopt -s extglob
    pip install ${PLANEMO_TARGET}
fi
. .venv/bin/activate

# Run test.
# This example shows off a bunch of different ways one could test with Planemo,
# but for actual workflow testing projects - probably best just to take one of the last
# two very easy invocations to simplify things.
if [ "$PLANEMO_TEST_STYLE" = "profile_serve_and_test" ]; then
    planemo $PLANEMO_OPTIONS profile_create \
        --database_type "$PLANEMO_SERVE_DATABASE_TYPE" \
        "$PLANEMO_PROFILE_NAME"
    planemo $PLANEMO_OPTIONS serve \
        --daemon \
        --galaxy_branch "$PLANEMO_GALAXY_BRANCH" \
        --profile "$PLANEMO_PROFILE_NAME" \
        --port "$PLANEMO_SERVE_PORT" \
        "$1"
    planemo $PLANEMO_OPTIONS test \
        --galaxy_url "$GALAXY_URL" \
        --engine external_galaxy \
        "$1"
elif [ "$PLANEMO_TEST_STYLE" = "serve_and_test" ]; then
    planemo $PLANEMO_OPTIONS serve \
        --daemon \
        --galaxy_branch "$PLANEMO_GALAXY_BRANCH" \
        --database_type "$PLANEMO_SERVE_DATABASE_TYPE" \
        --port "$PLANEMO_SERVE_PORT" \
        "$1"
    planemo $PLANEMO_OPTIONS test \
        --galaxy_url "$GALAXY_URL" \
        --engine external_galaxy \
        "$1"
elif [ "$PLANEMO_TEST_STYLE" = "docker_serve_and_test" ]; then
    docker pull "${PLANEMO_DOCKER_GALAXY_IMAGE}"
    planemo $PLANEMO_OPTIONS serve \
        --daemon \
        --engine docker_galaxy \
        --docker_galaxy_image "${PLANEMO_DOCKER_GALAXY_IMAGE}" \
        --docker_extra_volume . \
        --port "$PLANEMO_SERVE_PORT" \
        "$1"
    planemo $PLANEMO_OPTIONS test \
        --galaxy_url "$GALAXY_URL" \
        --engine external_galaxy \
        "$1"
elif [ "$PLANEMO_TEST_STYLE" = "test" ]; then
    # TODO: This variant is broken in initial tests for some reason.
    planemo $PLANEMO_OPTIONS test \
        --database_type "$PLANEMO_SERVE_DATABASE_TYPE" \
        --galaxy_branch "$PLANEMO_GALAXY_BRANCH" \
        "$1"
elif [ "$PLANEMO_TEST_STYLE" = "docker_test" ]; then
    # TODO: This variant isn't super usable yet because there is too much logging, hence the dev null
    # redirect.
    docker pull "${PLANEMO_DOCKER_GALAXY_IMAGE}"
    planemo $PLANEMO_OPTIONS test \
        --engine docker_galaxy \
        --docker_galaxy_image "${PLANEMO_DOCKER_GALAXY_IMAGE}" \
        --docker_extra_volume . \
        "$1" > /dev/null
else
    echo "Unknown test style ${PLANEMO_TEST_STYLE}"
    exit 1
fi