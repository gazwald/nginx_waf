FROM centos:latest
EXPOSE 80 443

ARG nginx_version
ENV nginx_version ${nginx_version:-1.17.2}

RUN yum update -y

RUN yum install -y gcc gcc-c++ make automake autoconf libcurl-devel openssl-devel libgeoip-devel pcre2-devel libxml2-devel yajl-devel zlib-devel libtool-ltdl-devel pkgconfig libtool wget git GeoIP-devel GeoIP-data

RUN groupadd -r nginx
RUN useradd -r -g nginx -s /sbin/nologin -M nginx
RUN mkdir -p /var/log/nginx && chown nginx:nginx /var/log/nginx
RUN mkdir -p /var/cache/nginx && chown nginx:nginx /var/cache/nginx

# Download $nginx_version
RUN wget -O /tmp/release-$nginx_version.tar.gz https://github.com/nginx/nginx/archive/release-$nginx_version.tar.gz
RUN tar xf /tmp/release-$nginx_version.tar.gz -C /tmp/

# Clone ModSecurity-nginx module
RUN git clone --depth 1 -b master https://github.com/SpiderLabs/ModSecurity-nginx.git /tmp/ModSecurity-nginx

# Clone ModSecurity and initialise submodules
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /tmp/ModSecurity \
    && cd /tmp/ModSecurity \
    && git submodule init \
    && git submodule update

# Clone OWASP ModSecurity Core Rule Set
RUN git clone -b v3.0/master https://github.com/SpiderLabs/owasp-modsecurity-crs.git /tmp/owasp-modsecurity-crs

# Build ModSecurity
RUN cd /tmp/ModSecurity \
    && sed -i '/AC_PROG_CC/a\AM_PROG_CC_C_O' configure.ac \
    && sed -i '1 i\AUTOMAKE_OPTIONS = subdir-objects' Makefile.am \
    && ./build.sh \
    && ./configure \
    && make -j $(nproc) \
    && make install 

# Build nginx modules, then build nginx
RUN cd /tmp/nginx-release-$nginx_version \
    && ./auto/configure --with-compat \
                        --user=nginx \
                        --group=nginx \
                        --add-module=../ModSecurity-nginx \
                        --with-file-aio \
                        --with-http_ssl_module \
                        --with-http_v2_module \
                        --with-stream \
                        --with-stream_ssl_module \
                        --with-threads \
    && make modules -j $(nproc) \
    && make -j $(nproc)\
    && make install

# Copy OWASP Modsecurity CSR into nginx config 
RUN cd /usr/local/nginx/conf \
    && mv /tmp/owasp-modsecurity-crs /usr/local/nginx/conf \
    && cp /usr/local/nginx/conf/owasp-modsecurity-crs/crs-setup.conf.example /usr/local/nginx/conf/owasp-modsecurity-crs/crs-setup.conf

# Copy config for nginx and modsecurity
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY unicode.mapping /usr/local/nginx/conf/unicode.mapping
COPY modsecurity.conf /usr/local/nginx/conf/modsecurity.conf
COPY modsec_includes.conf /usr/local/nginx/conf/modsec_includes.conf

CMD [ "/usr/local/nginx/sbin/nginx", "-g", "daemon off;" ]
