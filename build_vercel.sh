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

# 4. Télécharger sqlite3.wasm (le drift_worker.dart est compilé après pub get)
echo "Téléchargement de sqlite3.wasm..."
curl -L https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm -o web/sqlite3.wasm

echo "Nettoyage des dépendances pour le Web..."
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml

# 5. Récupérer les dépendances
flutter pub get

# 6. Compiler drift_worker.js (nécessite pub get d'abord pour résoudre les packages)
echo "Compilation de drift_worker.js..."
dart compile js -O2 -o web/drift_worker.js web/drift_worker.dart

# 7. Build de l'application Web
echo "Lancement du build Flutter Web..."
flutter build web --release --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
