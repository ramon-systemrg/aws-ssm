#!/usr/bin/env python3

import boto3
from argparse import ArgumentParser


def get_instance_patches(instance_id):

  host_patches = []
  instance_patches = ssm.describe_instance_patches(
    InstanceId=instance_id,
      Filters=[
        {
            'Key': 'State',
            'Values': ['Missing']
        },
      ],
  MaxResults=50
  )
  for i in instance_patches['Patches']:
    host_patches.append(i['Title'])
  return host_patches


def list_instance_patches():
  counter = 0

  for i in instances['InstanceInformationList']:
    # Print the heading.
    if counter == 0:
        print(f"{'--------------------':20}  {'-------------------------------------------------------':55}  {'--------------------------------------------------':50}")
        print(f"{'InstanceId':<20}  {'Hostname':<55s}  {'Updates':<50s}")
        print(f"{'--------------------':20}  {'-------------------------------------------------------':55}  {'--------------------------------------------------':50}")
    else:
        instance_id = i['InstanceId']
        computer_name = i['ComputerName']
        patch_list = get_instance_patches(i['InstanceId'])
        # We didn't find any missing patches so just print the Instance ID and Computer Name.
        if not patch_list:
            print(f"{instance_id:<20}  {computer_name:<55}")
        else:
            print(f"{instance_id:<20}  {computer_name:<55}\n")
            for i in patch_list:
                print(f"{'                                                                                '}{i}")
            print()
    counter += 1

parser = ArgumentParser(description='Get the current list of patches per host per region.')
parser.add_argument('region', help='region used to get hosts list, ex/ us-west-2')
parser.add_argument('role', help='Profile to use such as my-aws-user1-account')
args = parser.parse_args()
print()
print("Current region:  ", args.region)
print("Current profile: ", args.role)
print()

my_session = boto3.session.Session(region_name=args.region,profile_name=args.role)
ssm = my_session.client('ssm')
instances = ssm.describe_instance_information(MaxResults=50)
list_instance_patches()
