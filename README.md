# aws-ssm
Scripts and things used for ssm. Here I am using a vagrant box that I built and spin up a webserver on it and various other
things. Salt is the configuration manager used on the host, but it came into the picture later after creating the provision.sh script.

This works in a private environment and you can use your own defined vagrant boxes.

You also need an amazon aws account. Here since I am using my own lab it is a little different. I am using a hybrid activation to talk back to 
my on-prem hosts in a lab. I am also only using Centos. Ssm works on a small subset of all the Linux variants that exist, but you should do fine 
with Debian, Ubuntu, Centos, Amazon Linux or Windows. If you are using aws instances the setup will be different; ec2 instances still require the 
agent be installed, but you use roles to allow communication from ssm to the instance agent.

The thing about ssm it allows you to define a Maintenance Window, patch baseline and apply these things to targets (instances) at a defined interval 
thus your servers/instances can be up to date with patching. Then you can set it in motion and forget about it. I included a script that can query 
an account and region to show if any patches are required.


