#!/bin/bash

trap "rm -f /tmp/tmpfile_$$" INT
echo "Creating file /tmp/tmpfile_$$"
date > /tmp/tmpfile_$$

echo "press interrupt (CTRL-C) to interrupt ..."
while [ -f /tmp/tmpfile_$$ ]; do
    echo "File exist"
    sleep 1
done
echo "The file no longer exists"

trap INT
echo "Creating file /tmp/tmpfile_$$"
date > /tmp/tmpfile_$$

echo "press interrupt (CTRL-C) to interrupt ..."
while [ -f /tmp/tmpfile_$$ ]; do
    echo "File exist"
    sleep 1
done
echo "we never get here"
exit 0
