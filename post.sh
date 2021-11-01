#!/usr/bin/env bash

ACTIVATION_CODE='xxxxxxxxxxxxxxxxxxxx'
ACTIVATION_ID='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
REGION='us-east-1'

echo ''
echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo ' Setting up Amazon SSM Agent'
echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo ''

echo 'Registering amazon ssm agent'
systemctl stop amazon-ssm-agent
amazon-ssm-agent -register -code $ACTIVATION_CODE -id $ACTIVATION_ID -region $REGION
echo 'Starting amazon ssm agent'
systemctl start amazon-ssm-agent

echo 'done.'
