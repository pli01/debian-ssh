#!/bin/bash

set -e

bash -x /set_root_pw.sh
exec /usr/sbin/sshd -D
