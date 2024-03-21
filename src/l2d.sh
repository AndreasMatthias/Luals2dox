#!/bin/sh

basedir=$(realpath $(dirname "$0"))

exec /usr/bin/lua5.3 \
     -e "package.path=\"${basedir}/?.lua;${basedir}/?/init.lua;\" .. package.path" \
     ${basedir}/l2d.lua "$@"
