#!/bin/bash
echo 'Testing write with a 1GB file...'
dd if=/dev/zero of=./speedTestFile bs=1G count=5 oflag=direct
echo 'Testing read of 1GB file...'
dd if=./speedTestFile of=/dev/zero bs=1G count=5 oflag=dsync
rm ./speedTestFile
