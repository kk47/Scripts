#!/bin/bash
set -x
function add_startup {
    local rfile=/etc/rc.d/rc.local
    local pfile=/root/.bash_profile
    if [[ ! -e "$rfile" ]]; then
        if [[ -e "/etc/rc.local" ]]; then
            local rfile=/etc/rc.local
        else
            return
        fi
    fi
    if [[ ! -e "$pfile" ]]; then
        if [[ -e "/root/.bashrc" ]]; then
            local pfile=/root/.bashrc
        else
            return
        fi
    fi
    
    grep "/etc/dayu/env.sh" $rfile &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "source /etc/dayu/env.sh" >> $rfile
    fi
    grep '${DAYU_INSTALL_DIR}/bin/dayumgr boot' $rfile &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo '${DAYU_INSTALL_DIR}/bin/dayumgr boot' >> $rfile
    fi

    grep "/etc/dayu/env.sh" $pfile &>/dev/null 
    if [[ $? -ne 0 ]]; then
        echo "source /etc/dayu/env.sh" >> $pfile
    fi
    grep '${DAYU_INSTALL_DIR}/bin/dayurc' $pfile &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo 'source ${DAYU_INSTALL_DIR}/bin/dayurc' >> $pfile
    fi
}

add_startup
