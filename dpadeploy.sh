#!/bin/zsh

mkdir -p "${HOME}/c5shares/$1"
sudo mount -t cifs "//$1/c$" "${HOME}/c5shares/$1" -o _netdev,credentials="${HOME}/dpasearch"
sudo cp "${HOME}/c5shares/files/LakeShares/Lake DPA/DPA 2018.lnk" "${HOME}/c5shares/$1/Users/Public/Desktop/"
sudo umount "${HOME}/c5shares/$1"
