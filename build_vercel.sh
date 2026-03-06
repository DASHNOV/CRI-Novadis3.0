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

echo "Nettoyage des dépendances pour le Web..."
# On retire uniquement sqlite3_flutter_libs qui est le plus suspect
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml

# 4. Récupérer les dépendances
flutter pub get

# 5. Analyse (pour voir s'il y a des erreurs Dart cachées)
echo "Analyse du code..."
flutter analyze || echo "L'analyse a trouvé des problèmes, mais on tente quand même le build."

# 6. Build de l'application Web
echo "Lancement du build Flutter Web..."
# On force le renderer canvaskit qui est plus stable sur certains environnements de build
flutter build web --release --web-renderer canvaskit --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
