#!/bin/sh

set -e

cd `dirname $0`
./recompile.sh
if [ "x$1" = "x-g" ]; then
    GDB="gdb -ex run"
else
    GDB=""
fi

if [ "x$1" = "x-l" ]; then
    SNEEZY="(while sleep 10; do ./sneezy; done)"
else
    SNEEZY="./sneezy"
fi

mkdir -p "log"
SNEEZY="$SNEEZY" > "log/sneezy-`date -u +%Y-%m-%dT%H:%M:%SZ`"
CMD="/scripts/setup_mysql.sh && $GDB $SNEEZY; killall mysqld"

# support multiple Sneezies per box
if [ "`whoami`" = "sneezy" ]; then
  CONTAINER="sneezy"
  PORT=7900
else
  CONTAINER="sneezy-`whoami`"
  PORT=7900
  while (netstat -lptn | grep -q $PORT); do
    PORT=$(($PORT+1))
  done
fi

docker rm "$CONTAINER" || true  # nuke the previous run if needed

echo "Sneezy will listen on port $PORT"
docker run --name "$CONTAINER" --cap-add=SYS_PTRACE -it -p $PORT:7900 -v `pwd`:/home/sneezy/sneezymud-docker -v `pwd`/mysql:/var/lib/mysql sneezy /bin/sh -c "$CMD"
