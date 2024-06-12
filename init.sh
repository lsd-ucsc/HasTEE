git submodule init
git submodule update
pip install autoconf
cabal update
openssl genrsa -out ssl/ca.key 2048
openssl req -x509 -new -nodes -key ssl/ca.key -sha256 -days 1024 -out ssl/ca.crt -config ssl/ca_config.conf
openssl genrsa -out ssl/server.key 2048
openssl req -new -key ssl/server.key -out ssl/server.csr -config ssl/ca_config.conf
openssl x509 -req -days 360 -in ssl/server.csr -CA ssl/ca.crt -CAkey ssl/ca.key -CAcreateserial -out ssl/server.crt
cd ghc-trusted
./boot
./configure
cd mk
printf "BUILD_SPHINX_HTML = NO\nBUILD_SPHINX_PDF = NO" > build.mk
exec bash