#!/bin/bash

# Déterminer la racine du projet
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Projet root: $PROJECT_ROOT"

# 1. Cloner Flutter
echo "Clonage de Flutter..."
if [ ! -d "$PROJECT_ROOT/_f" ]; then
  git clone https://github.com/flutter/flutter.git -b 3.38.7 --depth 1 "$PROJECT_ROOT/_f"
fi

# 2. PATH
export PATH="$PROJECT_ROOT/_f/bin:$PATH"

# 3. Frontend folder
if [ -d "$PROJECT_ROOT/frontend" ]; then
  cd "$PROJECT_ROOT/frontend"
fi

# 4. Nettoyage agressif des dépendances natives pour le Web
echo "Nettoyage agressif du pubspec.yaml pour le Web..."
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml
sed -i '/path_provider/d' pubspec.yaml
sed -i '/open_file_plus/d' pubspec.yaml
sed -i '/permission_handler/d' pubspec.yaml

# 5. Pub get
flutter pub get

# 6. Build Web avec plus de détails en cas d'erreur
echo "Lancement du build Flutter Web (Verbose)..."
flutter build web --release --verbose --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
