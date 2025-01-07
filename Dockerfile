ARG NETBOX_VERSION=4.1.10
ARG NETBOX_SHA_512=e89d1acc34fe187b0ec1578abdfe9fad4df1e6c5184b382731e488aa40dec04dfe976aac6124bcec47e842b86e0be2822973f02abac1148f2043775e9cdaae3b


FROM alpine:3.21.1 AS build


ARG NETBOX_VERSION
ARG NETBOX_SHA_512


ADD "https://github.com/netbox-community/netbox/archive/refs/tags/v${NETBOX_VERSION}.tar.gz" \
    /tmp/netbox.tar.gz


RUN cd /tmp \
 && echo "${NETBOX_SHA_512}  netbox.tar.gz" > netbox.tar.gz.sha512 \
 && sha512sum -c netbox.tar.gz.sha512 \
 && tar -xzf netbox.tar.gz -C /opt/ \
 && cp -r /opt/netbox-${NETBOX_VERSION} /opt/netbox \
 && apk add --update build-base \
                     cargo \
                     libffi-dev libjpeg-turbo-dev libpq-dev \
                     python3 python3-dev \
                     zlib-dev \
 && python3 -m venv /opt/netbox/venv \
 && /opt/netbox/venv/bin/python3 -m pip install --upgrade pip \
                                                          setuptools \
                                                          wheel \
 && /opt/netbox/venv/bin/pip install -r /opt/netbox/requirements.txt


FROM padhihomelab/alpine-base:3.21.0_0.19.0_0.2


ARG NETBOX_VERSION


COPY --from=build /opt/netbox-${NETBOX_VERSION} \
                  /opt/netbox/

COPY ./etc/docker-entrypoint.d/99-extra-scripts \
     /etc/docker-entrypoint.d/99-extra-scripts

COPY ./usr/local/bin/netbox-healthcheck   /usr/local/bin/
COPY ./usr/local/bin/netbox-housekeeping  /usr/local/bin/
COPY ./usr/local/bin/netbox-rq            /usr/local/bin/
COPY ./usr/local/bin/netbox-wsgi          /usr/local/bin/
COPY ./usr/local/bin/start-netbox         /usr/local/bin/


RUN chmod +x /etc/docker-entrypoint.d/99-extra-scripts/*.sh \
             /usr/local/bin/* \
 && apk add --no-cache --update envsubst \
                                libffi libjpeg-turbo libpq \
                                nginx \
                                openssl \
                                python3 \
                                zlib


COPY ./etc/nginx/templates/netbox.conf.template \
     /etc/nginx/templates/netbox.conf.template

COPY --from=build /opt/netbox/venv \
                  /opt/netbox/venv

COPY ./opt/netbox/netbox/netbox/config/configuration.py \
     /opt/netbox/netbox/netbox/configuration.py


ARG SECRET_KEY="~~~~~~~~~~~~~~< SuperSecretDummyKey! >~~~~~~~~~~~~~~"


RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && rm /etc/nginx/http.d/default.conf \
 && cd /opt/netbox \
 && cp contrib/gunicorn.py . \
 && ./venv/bin/python -m mkdocs build \
                      --config-file /opt/netbox/mkdocs.yml \
                      --site-dir /opt/netbox/netbox/project-static/docs \
 && ./venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input


ENV DOCKER_USER=netbox
ENV DOCKER_GROUP=netbox
ENV NETBOX_BASE_PATH=
 
ENV PATH=/opt/netbox/venv/bin:$PATH
 
 
WORKDIR /opt/netbox/netbox


CMD start-netbox


EXPOSE 80


VOLUME [ "/opt/netbox/netbox/media", \
         "/opt/netbox/netbox/reports", \
         "/opt/netbox/netbox/scripts" ]


HEALTHCHECK --interval=15s --timeout=10s --start-period=240s \
        CMD "netbox-healthcheck"
