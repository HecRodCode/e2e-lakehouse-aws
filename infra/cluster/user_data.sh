#!/bin/bash
# Se ejecuta una sola vez, en el primer arranque, como root.
set -euxo pipefail

# Respaldo de costo: ocho horas despues de este arranque la maquina se apaga.
# La configuracion de la instancia hace que ese apagado la termine y borre el disco.
shutdown -h +480

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y openjdk-17-jre-headless unzip curl git

# AWS CLI v2 (instalador oficial)
cd /tmp
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install