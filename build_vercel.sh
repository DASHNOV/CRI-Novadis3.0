#!/bin/bash

# Déterminer la racine du projet
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Projet root: $PROJECT_ROOT"

# 1. Cloner Flutter
echo "Clonage de Flutter..."
if [ ! -d "$PROJECT_ROOT/_f" ]; then
  git clone https://github.com/flutter/flutter.git -b 3.38.7 --depth 1 "$PROJECT_ROOT/_f"
fi

# 2. Ajouter Flutter au PATH
export PATH="$PROJECT_ROOT/_f/bin:$PATH"

# 3. Aller dans le dossier frontend
if [ -d "$PROJECT_ROOT/frontend" ]; then
  cd "$PROJECT_ROOT/frontend"
fi

# 4. Télécharger les binaires SQLite/Drift pour le Web (pour éviter les erreurs CORS)
echo "Téléchargement des binaires SQLite Web..."
mkdir -p web
curl -L https://unpkg.com/@sql.js/sql.js@1.10.3/dist/sql-wasm.wasm -o web/sqlite3.wasm
curl -L https://unpkg.com/drift@2.20.0/dist/drift_worker.js -o web/drift_worker.js

echo "Nettoyage des dépendances pour le Web..."
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml

# 5. Récupérer les dépendances
flutter pub get

# 6. Build de l'application Web
echo "Lancement du build Flutter Web..."
flutter build web --release --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
