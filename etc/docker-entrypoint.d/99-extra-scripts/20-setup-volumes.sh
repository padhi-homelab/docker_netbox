#!/bin/sh

touch /run/nginx/nginx.pid

chown -R netbox:netbox /etc/nginx \
                       /opt/netbox/netbox/media \
                       /opt/netbox/netbox/reports \
                       /opt/netbox/netbox/scripts \
                       /run/nginx/nginx.pid \
                       /var/lib/nginx \
                       /var/log/nginx
