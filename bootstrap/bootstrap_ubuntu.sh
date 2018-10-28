#!/bin/bash


# TODO maybe change to stable/beta branch once it's out for bionic?
sudo add-apt-repository ppa:fish-shell/nightly-master
sudo apt update

# yes, no accounting for which directory it got called from

sudo apt install $(< apt_packages.txt)

# other, special cases
sudo apt install fish

# set fish as the default shell
chsh -s `which fish`

git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
#TODO checkout develop branch, run dotty to get emacs snippets and .spacemacs
sudo apt install emacs

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.3

# add the current user to the docker group so it can talk to the dockers
usermod -a -G docker $USER