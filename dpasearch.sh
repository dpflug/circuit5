#!/bin/zsh

mkdir -p "${HOME}/c5shares/$1"
sudo mount -t cifs "//$1/c$" "${HOME}/c5shares/$1" -o _netdev,credentials="${HOME}/dpasearch"
echo "==="
echo "$1:"
ls "${HOME}/c5shares/$1/"Users/*/Desktop/DPA*
sudo umount "${HOME}/c5shares/$1"
