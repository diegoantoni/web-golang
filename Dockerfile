FROM centos/s2i-core-centos7

# RHSCL rh-nginx112 image.
#
# Volumes:
#  * /var/opt/rh/rh-nginx112/log/nginx/ - Storage for logs

EXPOSE 8281
EXPOSE 8443

ENV NAME=nginx \
    NGINX_VERSION=1.12 \
    NGINX_SHORT_VER=112 \
    VERSION=0

ENV SUMMARY="Platform for running nginx $NGINX_VERSION or building nginx-based application" \
    DESCRIPTION="Nginx is a web server and a reverse proxy server for HTTP, SMTP, POP3 and IMAP \
protocols, with a strong focus on high concurrency, performance and low memory usage. The container \
image provides a containerized packaging of the nginx $NGINX_VERSION daemon. The image can be used \
as a base image for other applications based on nginx $NGINX_VERSION web server. \
Nginx server image can be extended using source-to-image tool."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Nginx ${NGINX_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.expose-services="8443:https" \
      io.openshift.tags="builder,${NAME},rh-${NAME}${NGINX_SHORT_VER}" \
      com.redhat.component="rh-${NAME}${NGINX_SHORT_VER}-container" \
      name="centos/${NAME}-${NGINX_SHORT_VER}-centos7" \
      version="${NGINX_VERSION}" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>" \
      help="For more information visit https://github.com/sclorg/${NAME}-container" \
      usage="s2i build <SOURCE-REPOSITORY> centos/${NAME}-${NGINX_SHORT_VER}-centos7:latest <APP-NAME>"

ENV NGINX_CONFIGURATION_PATH=${APP_ROOT}/etc/nginx.d \
    NGINX_CONF_PATH=/etc/opt/rh/rh-nginx${NGINX_SHORT_VER}/nginx/nginx.conf \
    NGINX_DEFAULT_CONF_PATH=${APP_ROOT}/etc/nginx.default.d \
    NGINX_CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/nginx \
    NGINX_APP_ROOT=${APP_ROOT} \
    NGINX_LOG_PATH=/var/opt/rh/rh-nginx${NGINX_SHORT_VER}/log/nginx \
    NGINX_PERL_MODULE_PATH=${APP_ROOT}/etc/perl

RUN yum install -y yum-utils gettext hostname && \
    yum install -y centos-release-scl-rh && \
    INSTALL_PKGS="nss_wrapper bind-utils rh-nginx${NGINX_SHORT_VER} rh-nginx${NGINX_SHORT_VER}-nginx \
                  rh-nginx${NGINX_SHORT_VER}-nginx-mod-stream rh-nginx${NGINX_SHORT_VER}-nginx-mod-http-perl" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN sed -i -f ${NGINX_APP_ROOT}/nginxconf.sed ${NGINX_CONF_PATH} && \
    chmod a+rwx ${NGINX_CONF_PATH} && \
    mkdir -p ${NGINX_APP_ROOT}/etc/nginx.d/ && \
    mkdir -p ${NGINX_APP_ROOT}/etc/nginx.default.d/ && \
    mkdir -p ${NGINX_APP_ROOT}/src/nginx-start/ && \
    mkdir -p ${NGINX_CONTAINER_SCRIPTS_PATH}/nginx-start && \
    mkdir -p ${NGINX_LOG_PATH} && \
    mkdir -p ${NGINX_PERL_MODULE_PATH} && \
    ln -s ${NGINX_LOG_PATH} /var/log/nginx && \
    ln -s /etc/opt/rh/rh-nginx${NGINX_SHORT_VER}/nginx /etc/nginx && \
    ln -s /opt/rh/rh-nginx${NGINX_SHORT_VER}/root/usr/share/nginx /usr/share/nginx && \
    chmod -R a+rwx ${NGINX_APP_ROOT}/etc && \
    chmod -R a+rwx /var/opt/rh/rh-nginx${NGINX_SHORT_VER} && \
    chmod -R a+rwx ${NGINX_CONTAINER_SCRIPTS_PATH}/nginx-start && \
    chown -R 1001:0 ${NGINX_APP_ROOT} && \
    chown -R 1001:0 /var/opt/rh/rh-nginx${NGINX_SHORT_VER} && \
    chown -R 1001:0 ${NGINX_CONTAINER_SCRIPTS_PATH}/nginx-start && \
    chmod -R a+rwx /var/run && \
    chown -R 1001:0 /var/run && \
    rpm-file-permissions

USER 1001

# Not using VOLUME statement since it's not working in OpenShift Online:
# https://github.com/sclorg/httpd-container/issues/30
# VOLUME ["/opt/rh/rh-nginx112/root/usr/share/nginx/html"]
# VOLUME ["/var/opt/rh/rh-nginx112/log/nginx/"]

ENV BASH_ENV=${NGINX_APP_ROOT}/etc/scl_enable \
    ENV=${NGINX_APP_ROOT}/etc/scl_enable \
    PROMPT_COMMAND=". ${NGINX_APP_ROOT}/etc/scl_enable"

CMD $STI_SCRIPTS_PATH/usage
