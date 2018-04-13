Make Nginx real-ip Conf
=============

DESC
-------------
> It is a shell script that takes the ip band of cloudfront and elb and generates the nginx conf file.

Dependency
-------------
> jq[https://stedolan.github.io/jq/]


HOW TO RUN
-------------
> sudo ./make_nginx_real_ip_conf.sh


HOW TO USE
-------------
> Add 'include /etc/nginx/conf.d/sample_real_ip.conf' in your nginx conf file.

TODO
-------------
i will change this source to "python 3"
