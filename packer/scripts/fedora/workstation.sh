#!/bin/bash -eux

dnf group install -y --allowerasing "Fedora Workstation"
systemctl set-default graphical.target
