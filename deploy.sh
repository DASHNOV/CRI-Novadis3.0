#!/bin/bash
set -e

VPS_USER="root"
VPS_HOST="104.168.10.190"  # à remplir : ex. 51.210.x.x
IMAGE_NAME="cri-novadis-api"
IMAGE_TAG="latest"

echo "==> Build de l'image Docker..."
docker build \
  -t ${IMAGE_NAME}:${IMAGE_TAG} \
  ./backend/src/NovadisApi

echo "==> Export et transfert de l'image vers le VPS..."
docker save ${IMAGE_NAME}:${IMAGE_TAG} | ssh ${VPS_USER}@${VPS_HOST} "docker load"

echo "==> Transfert du docker-compose.yml..."
scp docker-compose.yml ${VPS_USER}@${VPS_HOST}:/opt/cri-novadis/

echo "==> Redémarrage des services sur le VPS..."
ssh ${VPS_USER}@${VPS_HOST} "cd /opt/cri-novadis && docker compose up -d --remove-orphans"

echo "==> Vérification des containers..."
ssh ${VPS_USER}@${VPS_HOST} "docker compose -f /opt/cri-novadis/docker-compose.yml ps"

echo "==> Déploiement terminé ✓"
