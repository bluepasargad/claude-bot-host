FROM caddy:alpine
RUN apk add --no-cache curl unzip \
 && curl -L -o /tmp/x.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
 && unzip /tmp/x.zip xray -d /usr/local/bin && chmod +x /usr/local/bin/xray && rm /tmp/x.zip
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
