#!/bin/bash

if [ -e .env ]; then
    export $(cat .env | grep -v ^# | xargs)
fi

function download {
	if command -v curl >/dev/null 2>&1; then
		curl -L -s "$1" > "$2"
	elif command -v wget >/dev/null 2>&1; then
		wget -n -O "$2" "$1"
	else
		echo ''
		return 1
	fi
}

if [[ ${WP_VERSION} =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
    WP_TESTS_TAG="tags/${WP_VERSION}"
elif [[ ${WP_VERSION} == 'nightly' || ${WP_VERSION} == 'trunk' ]]; then
    WP_TESTS_TAG="trunk"
else
    # http serves a single offer, whereas https serves multiple. we only want one
    download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
    grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
    LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
    if [[ -z "$LATEST_VERSION" ]]; then
        echo "Latest WordPress version could not be found."
        exit 1
    fi
    WP_TESTS_TAG="tags/$LATEST_VERSION"
fi

WP_TESTS_DIR=vendor/xwp/wordpress-tests

echo "Installing WordPress PHPUnit Test Suite into '${WP_TESTS_DIR}' ..."

rm -rf ${WP_TESTS_DIR}
svn co -q https://develop.svn.wordpress.org/${WP_TESTS_TAG}/tests/ ${WP_TESTS_DIR}