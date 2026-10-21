#!/bin/sh
cd "$(dirname "$0")" || exit 1

: "${UUID:?UUID is required}"
HPORT="${SERVER_PORT:-${PORT:-8080}}"
HOST="${DOMAIN:-fi14.bot-hosting.cloud}"
SB_VER="1.12.0"

mkdir -p bin

if ! ./bin/sing-box version >/dev/null 2>&1; then
  echo "[hy2] downloading sing-box ${SB_VER}..."
  rm -f bin/sing-box
  curl -fL -o bin/sb.tgz "https://github.com/SagerNet/sing-box/releases/download/v${SB_VER}/sing-box-${SB_VER}-linux-amd64.tar.gz" || { echo "[hy2] download failed"; exit 1; }
  tar -xzf bin/sb.tgz -C bin --strip-components=1 "sing-box-${SB_VER}-linux-amd64/sing-box" || { echo "[hy2] extract failed"; exit 1; }
  rm -f bin/sb.tgz
  chmod +x bin/sing-box
  ./bin/sing-box version >/dev/null 2>&1 || { echo "[hy2] sing-box binary not working"; exit 1; }
fi

if [ ! -f bin/hy2.crt ]; then
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
    -keyout bin/hy2.key -out bin/hy2.crt -days 3650 -subj "/CN=www.bing.com" >/dev/null 2>&1
fi

cat > ./hy2.json <<EOF
{
  "log": {"level": "warn"},
  "inbounds": [{
    "type": "hysteria2",
    "listen": "0.0.0.0",
    "listen_port": ${HPORT},
    "obfs": {"type": "salamander", "password": "${UUID}"},
    "users": [{"password": "${UUID}"}],
    "tls": {
      "enabled": true,
      "alpn": ["h3"],
      "certificate_path": "./bin/hy2.crt",
      "key_path": "./bin/hy2.key"
    }
  }],
  "outbounds": [{"type": "direct"}]
}
EOF

./bin/sing-box check -c ./hy2.json || { echo "[hy2] config invalid"; exit 1; }

echo "[hy2] LINK: hysteria2://${UUID}@${HOST}:${HPORT}?obfs=salamander&obfs-password=${UUID}&sni=www.bing.com&insecure=1#BotHosting-HY2"

exec ./bin/sing-box run -c ./hy2.json
