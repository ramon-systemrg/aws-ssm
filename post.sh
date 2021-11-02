#!/usr/bin/env bash

# This script runs from the Vagrantfile after rebooting to register the agent
# within the ssm console. The following three items are required. The activation
# code and ID are generated once by setting up a hybrid activation in ssm.

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
