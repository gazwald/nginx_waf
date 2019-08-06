FROM centos:latest
EXPOSE 80 443
RUN yum install -y gcc gcc-c++ make automake autoconf libcurl-devel openssl-devel libgeoip-devel pcre2-devel libxml2-devel yajl-devel zlib-devel libtool-ltdl-devel pkgconfig libtool wget git GeoIP-devel GeoIP-data

RUN groupadd -r nginx
RUN useradd -r -g nginx -s /sbin/nologin -M nginx
RUN mkdir -p /var/log/nginx && chown nginx:nginx /var/log/nginx
RUN mkdir -p /var/cache/nginx && chown nginx:nginx /var/cache/nginx

RUN wget -O /tmp/release-1.17.2.tar.gz https://github.com/nginx/nginx/archive/release-1.17.2.tar.gz
RUN cd /tmp/ \ 
    && tar xf release-1.17.2.tar.gz
RUN cd /tmp/ \
    && git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
RUN cd /tmp/ModSecurity \
    && git submodule init \
    && git submodule update \
    && sed -i '/AC_PROG_CC/a\AM_PROG_CC_C_O' configure.ac \
    && sed -i '1 i\AUTOMAKE_OPTIONS = subdir-objects' Makefile.am \
    && ./build.sh \
    && ./configure \
    && make \
    && make install 
RUN cd /tmp/ \
    && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
RUN cd /tmp/nginx-release-1.17.2 \
    && ./auto/configure --with-compat --user=nginx --group=nginx --add-module=../ModSecurity-nginx --with-http_ssl_module \
    && make modules \
    && make \
    && make install


RUN cd /usr/local/nginx/conf \
    && git clone -b v3.0/master https://github.com/SpiderLabs/owasp-modsecurity-crs.git \
    && mv /usr/local/nginx/conf/owasp-modsecurity-crs/crs-setup.conf.example /usr/local/nginx/conf/owasp-modsecurity-crs/crs-setup.conf

COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY unicode.mapping /usr/local/nginx/conf/unicode.mapping
COPY modsecurity.conf /usr/local/nginx/conf/modsecurity.conf
COPY modsec_includes.conf /usr/local/nginx/conf/modsec_includes.conf

CMD [ "/usr/local/nginx/sbin/nginx", "-g", "daemon off;" ]
