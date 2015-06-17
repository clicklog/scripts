#!/bin/bash

# http://qiita.com/ar1/items/8213c8155bd0153757a8

for region in `aws ec2 describe-regions --query "Regions[].[RegionName]" --output text`
do
    aws ec2 import-key-pair --cli-input-json file://sshkey.json --no-dry-run --region $region
done
