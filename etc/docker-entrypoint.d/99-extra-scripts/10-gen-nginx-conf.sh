#!/bin/sh

if [ -n "$NETBOX_BASE_PATH" ] && [ "$NETBOX_BASE_PATH" != "/" ] ; then
  export NETBOX_BASE_PATH_PREFIX="/${NETBOX_BASE_PATH#/}"
else
  export NETBOX_BASE_PATH_PREFIX=
fi

envsubst < /etc/nginx/templates/netbox.conf.template \
  | sed 's;§;$;g' > /etc/nginx/http.d/netbox.conf
