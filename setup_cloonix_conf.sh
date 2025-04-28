#!/usr/bin/env bash

CONF_FILE_NAME=".cloonix_conf"
CONF_FILE_DIR=$HOME

CONF_FILE=$CONF_FILE_DIR/$CONF_FILE_NAME
CLOONIX_EXEC_PATH=/usr/local/bin/cloonix_net

CUSTOM_EXEC_PATH=$HOME/.local/bin
CUSTOM_EXEC=$CUSTOM_EXEC_PATH/cloonix_net

mkdir -p $CUSTOM_EXEC_PATH

echo -e "xrdb -merge $CONF_FILE\n. $CLOONIX_EXEC_PATH \"\$@\"" > $CUSTOM_EXEC
chmod +x $CUSTOM_EXEC

echo -e "urxvt.font: xft:Monospace:size=12\nurxvt.foreground: #eeeeee\nurxvt.background: #222222" > $CONF_FILE

if [ ! $(echo $PATH | grep "$HOME/.local/bin") ]; then
  cat >> $HOME/.bashrc <<-END
		
		if [ -d "\$HOME/.local/bin" ] && [ ! \$(echo \$PATH | grep "\$HOME/.local/bin") ]; then
		  export PATH="\$HOME/.local/bin/:\$PATH"
		fi
	END
fi                                                    
