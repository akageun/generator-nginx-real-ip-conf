#!/bin/sh

AWS_IP_RANGE_API="https://ip-ranges.amazonaws.com/ip-ranges.json"
NGINX_CONF_FILE_PATH="/etc/nginx/conf.d/"
NGINX_CONF_FILE_NM="sample_real_ip.inc"
ELB_IP_LIST="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

function is_root_run
{
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit -1
    fi
}

function is_jq_install
{
    if yum list installed -q jq ; then
        echo "jq installed"
    else
        echo "Required. jq!!"
        echo "you can 'sudo yum install jq'"
        exit -1;
    fi
}

function make_aws_ip_list_json
{
        RTN_CONF_STR="\n"
        TO_DATE_FORMAT=`date +%Y%m%d%H%M%S`
        RTN_CONF_STR+="#Make at ${TO_DATE_FORMAT}\n"

        RTN_CONF_STR+="#your ELB IP \n"
        ELB_IP=(${ELB_IP_LIST//,/' '})

        for ip in ${ELB_IP[@]}
        do
                RTN_CONF_STR+="set_real_ip_from ${ip}; \n"
        done
        RTN_CONF_STR+="\n"
        RTN_CONF_STR+="#AWS CloudFront IP/CIDR range \n"

        for ip in $(curl -Ss ${AWS_IP_RANGE_API} | jq -r  '.prefixes[]| select(.service|contains("CLOUDFRONT"))| .ip_prefix'| sort| uniq); do
                RTN_CONF_STR+="set_real_ip_from ${ip}; \n"
        done

        for ip in $(curl -Ss ${AWS_IP_RANGE_API} | jq -r  '.ipv6_prefixes[]| select(.service|contains("CLOUDFRONT"))| .ipv6_prefix'| sort| uniq); do
                RTN_CONF_STR+="set_real_ip_from ${ip}; \n"
        done

        RTN_CONF_STR+="\n"
        RTN_CONF_STR+="# always put the following 2 lines in the bottom of ip list \n"
        RTN_CONF_STR+="real_ip_header X-Forwarded-For; \n"
        RTN_CONF_STR+="real_ip_recursive on; \n"

        echo -e ${RTN_CONF_STR} > ${NGINX_CONF_FILE_PATH}${NGINX_CONF_FILE_NM}
}

function mv_config_nginx
{
        if nginx -t ; then
                echo "=======NGINX OK========"
                systemctl reload nginx.service

        else
                echo "=======NGINX ERROR========"
                rm -rf ${NGINX_CONF_FILE_PATH}${NGINX_CONF_FILE_NM}
                exit -1;
        fi
}

is_root_run
is_jq_install
make_aws_ip_list_json
mv_config_nginx
