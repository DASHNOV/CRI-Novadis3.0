#!/bin/bash

# Déterminer la racine du projet
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Projet root: $PROJECT_ROOT"

# 1. Cloner Flutter (version stable spécifiée)
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

echo "Nettoyage agressif des dépendances natives pour le Web..."
# On retire toutes les dépendances purement natives qui peuvent bloquer dart2js
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml
sed -i '/path_provider/d' pubspec.yaml
sed -i '/open_file_plus/d' pubspec.yaml
sed -i '/permission_handler/d' pubspec.yaml

# 4. Récupérer les dépendances
flutter pub get

# 5. Build de l'application Web
echo "Lancement du build Flutter Web..."
# On force le renderer html car Canvaskit peut parfois saturer la RAM sur Vercel
flutter build web --release --web-renderer html --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
