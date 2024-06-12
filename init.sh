pip install autoconf
cd ghc-trusted
./boot
./configure
cd mk
printf "BUILD_SPHINX_HTML = NO\nBUILD_SPHINX_PDF = NO" > build.mk
exec bash