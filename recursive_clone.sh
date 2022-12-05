#!/bin/bash

usage() { echo "Usage: $0 [-k <path to private key>] [-i <app id>] -r <repo (https)>" 1>&2; exit 1; }

while getopts ":k:i:r:" o; do
    case "${o}" in
        r)
            GITHUB_REPO=${OPTARG}
            ;;
        k)
            PRIVATE_KEY=${OPTARG}
            ;;
        i)
            APP_ID=${OPTARG}
            ;;
        *)
	    echo "Invalid argument $o"
            usage
            ;;
    esac
done
shift $((OPTIND-1))


if [ -z "${PRIVATE_KEY}" ] || [ -z "${APP_ID}" ] || [ -z "$GITHUB_REPO" ]; then
    usage
fi

echo "private key= ${PRIVATE_KEY}"
echo "app id = ${APP_ID}"

TOKEN="$(ruby jwt.rb $PRIVATE_KEY $APP_ID)"

APP_NAME="$(curl --silent -X GET -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" https://api.github.com/app | jq '.slug')"

if [ -z "${APP_NAME}" ]; then
   echo "Get app information failed"
fi

echo "Using GitHub App $APP_NAME"

AUTH_TOKEN_URL=$(curl --silent -X GET -H "Authorization: Bearer $(ruby jwt.rb glasgow-jenkins.2022-12-05.private-key.pem 217303)" -H "Accept: application/vnd.github+json" https://api.github.com/app/installations | jq '.[0].access_tokens_url')

if [ -z "${AUTH_TOKEN_URL}" ]; then
   echo "Get auth url failed"
fi

echo "Using authorization URL: $AUTH_TOKEN_URL"

AUTH_TOKEN=$(curl --silent -X POST -H "Authorization: Bearer $(ruby jwt.rb glasgow-jenkins.2022-12-05.private-key.pem 217303)" -H "Accept: application/vnd.github+json" https://api.github.com/app/installations/27119811/access_tokens | jq -r '.token')

echo "Using authorization token: $AUTH_TOKEN"

git -c url."https://x-access-token:${AUTH_TOKEN}@github.com/".insteadOf='git@github.com:' clone --recursive ${GITHUB_REPO/https:\/\//https:\/\/x-access-token:$AUTH_TOKEN@}

