#!/bin/bash

source /etc/environment

HOMEDIR=$(eval echo "~`whoami`")

AWS_CREDS=""
if [ ! -z $AWS_ACCESS_KEY ]; then
    AWS_CREDS=" -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY \
     -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY "
fi

sudo docker run --rm \
    -v ${HOMEDIR}:/data/ $AWS_CREDS behance/docker-aws-s3-downloader \
     us-east-1 $CONTROL_TIER_S3SECURE_BUCKET .sumologic

SUMOLOGIC_ACCESS_ID=$(sudo cat ${HOMEDIR}/.sumologic | grep ID | cut -d= -f2)
SUMOLOGIC_SECRET=$(sudo cat ${HOMEDIR}/.sumologic | grep SECRET | cut -d= -f2)
etcdctl set /sumologic_id $SUMOLOGIC_ACCESS_ID
etcdctl set /sumologic_secret $SUMOLOGIC_SECRET
