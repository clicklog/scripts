#!/bin/sh

sg="mydefaultsecuritygroup"
desc="My Default Security Group"

accountid=`aws iam get-user --query 'User.Arn' | perl -pe 's#"arn:aws:iam::([0-9]+):user/.*#$1#'`
mkdir -p ${sg}

aws configure set output text
for region in `aws ec2 describe-regions --query "Regions[].[RegionName]" | sort`
do
    aws configure set region ${region}
    printf "%-14s" $region

    # see if ${sg} exists
    gid=`aws ec2 describe-security-groups --group-name "${sg}" --query 'SecurityGroups[0].GroupId' 2> /dev/null`
    if [ "x$gid" == "x" ]; then
        gid=`aws ec2 create-security-group --group-name "${sg}" --description "${desc}" --query 'GroupId'`
        /bin/echo -n " ${gid} (new)"
    else
        /bin/echo -n " ${gid}      "
    fi

    # add default egress rule
    aws ec2 authorize-security-group-egress --group-id ${gid} --protocol -1 --cidr 0.0.0.0/0 2> /dev/null

    # remove current ingress rule
    cat ${sg}.json | sed -e 's/_ACCOUNTID_/435182983470/g' | sed -e "s/_GROUPID_/$gid/g" > temp.json
    aws ec2 describe-security-groups --group-id ${gid} --query 'SecurityGroups[0].IpPermissions' --output json > ${sg}/${region}.json 2> /dev/null
    if [ -s ${sg}/${region}.json ]; then
        aws ec2 revoke-security-group-ingress --group-id ${gid} --ip-permission file://${sg}/${region}.json
        /bin/echo -n " removed old"
    fi

    # add new ingress rule
    aws ec2 authorize-security-group-ingress --group-id ${gid} --ip-permission file://temp.json
    /bin/echo " added new"
    rm -f temp.json
done

# revert to default
aws configure set region ap-northeast-1
aws configure set output json
