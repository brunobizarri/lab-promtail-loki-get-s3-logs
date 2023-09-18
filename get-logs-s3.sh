#!/bin/bash

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
hour=$(date +%H)
hour_utc=$(expr $hour + 3)
last_hour=$year$month$day"T"$hour_utc

loadBalancers=( "brain-delivery-api-uat" "brain-delivery-api-dev" )

profile="brainprod"
bucket_name="brain-lb-logging"
bucket_prefix="loadBalancer/AWSLogs/492982038605/elasticloadbalancing/sa-east-1/$year/$month/$day"

path_app=/Users/c95133a/code/lab-promtail-loki-get-s3-logs
log_all_s3=$path_app/logs_s3/logs_alb_s3.log

function download(){
    if [ -e "$path_app/files_downloaded.txt" ]; then
        download_diff
    else
        download_files
    fi
}

function download_files(){
    for loadBalancer in ${loadBalancers[@]}; do
        able_s3_files=$(aws s3 ls s3://$bucket_name/$bucket_prefix/ --profile $profile | grep $loadBalancer | grep $last_hour | awk '{print $4}')

        for file in $able_s3_files; do
            aws s3 cp s3://$bucket_name/$bucket_prefix/$file $path_app/logs_s3/. --profile $profile
            zcat -f $path_app/logs_s3/$file >> $log_all_s3
            rm -f logs_s3/$file
        done
        echo "$able_s3_files" >> $path_app/files_downloaded.txt
    done
}

function  download_diff(){
    for loadBalancer in ${loadBalancers[@]}; do
        able_s3_files_newer=$(aws s3 ls s3://$bucket_name/$bucket_prefix/ --profile $profile | grep $loadBalancer | grep $last_hour | awk '{print $4}')
        files_downloaded=$(cat $path_app/files_downloaded.txt)

        for file in $able_s3_files_newer; do
            if [[ ! $files_downloaded =~ $file ]]; then
                aws s3 cp s3://$bucket_name/$bucket_prefix/$file $path_app/logs_s3/. --profile $profile
                echo "$file" >> $path_app/files_downloaded.txt
                zcat -f $path_app/logs_s3/$file >> $log_all_s3
                rm -f $path_app/logs_s3/$file
            fi
        done
    done
}

for i in {1..1000}; do
    echo "Count: $i"
    download
    sleep 30
done