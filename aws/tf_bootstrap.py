#!/usr/bin/env python3

import boto3
import argparse
from botocore.exceptions import ClientError
import logging

parser = argparse.ArgumentParser()
parser.add_argument('-b', '--bucket', help='bucket to create', required=True)
parser.add_argument('-r', '--region', help='region for bucket', required=True)
parser.add_argument('-k', '--encrypt', help='enable encryption', type=bool, default=True)
parser.add_argument('-v', '--versioning', help='enable versioning', type=bool, default=True)

args = parser.parse_args()

logging.basicConfig(level=logging.INFO)

if __name__ == '__main__':

    s3 = boto3.client('s3')
    # create s3 bucket
    try:
        s3.create_bucket(Bucket=args.bucket, ACL='private', CreateBucketConfiguration = {
            'LocationConstraint': args.region,
        })
        logging.info("bucket created.")
    except ClientError as e:
        if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
            logging.info('bucket already exists.')
        else:
            raise(e)

    # enable versioning
    if args.versioning:
        logging.info("set versioning")
        s3.put_bucket_versioning(Bucket=args.bucket, VersioningConfiguration={'Status': 'Enabled'})

    # set encryption policy
    if args.encrypt:
        logging.info("set encryption policy")
        s3.put_bucket_encryption(
            Bucket=args.bucket,
            ServerSideEncryptionConfiguration={
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}
                ]
            }
        )

    # dynamodb
    dynamodb_client=boto3.client('dynamodb')
    try:
        dynamodb_client.create_table(
            TableName=args.bucket.replace('.', '_'),
            ProvisionedThroughput={
                "ReadCapacityUnits": 20,
                "WriteCapacityUnits": 20,
            },
            KeySchema=[
                {
                    'AttributeName': 'string',
                    'KeyType': 'HASH'
                },
            ],

            AttributeDefinitions=[
                {
                    'AttributeName': 'string',
                    'AttributeType': 'S'
                },
            ]
        )
        print("table created.")
    except dynamodb_client.exceptions.ResourceInUseException as e:
        logging.info("table already exists.")
