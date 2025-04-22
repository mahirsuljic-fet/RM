#!/usr/bin/env bash

CONF_FILE_NAME=".cloonix_conf"
CONF_FILE_DIR=$HOME

CONF_FILE=$CONF_FILE_DIR/$CONF_FILE_NAME
CLOONIX_EXEC_PATH=/usr/local/bin/cloonix_net

CUSTOM_EXEC=$HOME/.local/bin/cloonix_net

echo -e "xrdb -merge $CONF_FILE\n. $CLOONIX_EXEC_PATH \"\$@\"" > $CUSTOM_EXEC
chmod +x $CUSTOM_EXEC

echo -e "urxvt.font: xft:Monospace:size=14\nurxvt.foreground: #eeeeee\nurxvt.background: #222222" > $CONF_FILE
