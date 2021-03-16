FROM nginx:alpine

ENV consul_server_ip consulserver

RUN apk --update --no-cache add curl \
    && curl -JO https://releases.hashicorp.com/consul-template/0.25.2/consul-template_0.25.2_linux_amd64.tgz \
    && tar -xvf consul-template_0.25.2_linux_amd64.tgz -C /usr/local/bin \
    && rm -rf consul-template_0.25.2_linux_amd64.tgz

ADD nginx.conf.ctmpl /etc/consul-templates/nginx.conf.ctmpl

CMD /usr/sbin/nginx -c /etc/nginx/nginx.conf && consul-template -consul-addr=$(echo $consul_server_ip):8500 -template "/etc/consul-templates/nginx.conf.ctmpl:/etc/nginx/conf.d/app.conf:nginx -s reload"
