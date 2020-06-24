#!/usr/bin/env python3

import boto3
import os
import re
import socket
import subprocess
import time


# Set globals and env vars
stack_name = 'bedrockServer-test'

if 'AWS_PROFILE' not in os.environ:
    os.environ['AWS_PROFILE'] = 'ryapric'
if 'AWS_DEFAULT_REGION' not in os.environ:
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'

cfn = boto3.client('cloudformation')
ec2 = boto3.client('ec2')


def test_stack():
    # Deploy stack
    with open('./cloudformation/main.yaml') as f:
        template_body = f.read()

    print(f"Submitting stack '{stack_name}'...")
    try:
        cfn.create_stack(
            StackName = stack_name,
            TemplateBody = template_body,
            Capabilities = ['CAPABILITY_IAM']
        )
    except cfn.exceptions.AlreadyExistsException:
        print(f"Stack '{stack_name}' already exists")
    
    # Wait for stack creation to succeed
    print(f"Waiting for stack '{stack_name}' to finish creating/updating...")
    stack_status = cfn.describe_stacks(StackName = stack_name)['Stacks'][0]['StackStatus']
    if 'CREATE' in stack_status:
        cfn.get_waiter('stack_create_complete').wait(StackName = stack_name)
    elif 'UPDATE' in stack_status:
        cfn.get_waiter('stack_update_complete').wait(StackName = stack_name)

    # Get exported values from stack
    stack_details = cfn.describe_stacks(StackName = stack_name)['Stacks'][0]
    stack_outputs = stack_details['Outputs']
    
    doorknocker_iid = [x for x in stack_outputs[:] if x['ExportName'] == f'{stack_name}-DoorknockerId']
    doorknocker_iid = doorknocker_iid[0]['OutputValue']
    
    worker_iid = [x for x in stack_outputs[:] if x['ExportName'] == f'{stack_name}-WorkerId']
    worker_iid = worker_iid[0]['OutputValue']


    # Hit the doorknocker
    instance_grace_seconds = 60
    print(f'Giving instances {instance_grace_seconds} seconds to come up...')
    time.sleep(instance_grace_seconds)

    doorknocker_ip = ec2.describe_instances(
        InstanceIds = [doorknocker_iid]
    )['Reservations'][0]['Instances'][0]['PublicIpAddress']

    msg = "knock-knock"
    bytes = str.encode(msg)
    ip_port = (doorknocker_ip, 19132)

    # Create a UDP socket
    sock = socket.socket(family = socket.AF_INET, type = socket.SOCK_DGRAM)

    # Send to server using created UDP socket
    print(sock.sendto(bytes, ip_port))
# end test_stack


def test_delete_stack():
    # # Delete stack
    # print(f"Sending stack delete request for stack '{stack_name}'...")
    # cfn.delete_stack(StackName = stack_name)

    # print(f"Waiting for delete completion for stack '{stack_name}'...")
    # cfn.get_waiter('stack_delete_complete').wait(StackName = stack_name)

    # Leave the stack up for now, so you can debug in the console
    print('Stack left up; be sure to delete it!')
# end test_delete_stack
