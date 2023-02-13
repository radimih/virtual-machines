#!/bin/bash -eux

# Список всех сред, групп и пакетов: https://pagure.io/fedora-comps/tree/main
# (см. файл comps-f<версия дистрибутива>.xml.in)

dnf install -y --allowerasing '@workstation-product-environment'
systemctl set-default graphical.target
