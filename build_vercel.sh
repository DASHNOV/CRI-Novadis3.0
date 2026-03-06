#!/bin/bash

# Déterminer la racine du projet (là où se trouve le script)
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Projet root: $PROJECT_ROOT"

# 1. Cloner Flutter dans un dossier temporaire à la racine du projet
echo "Clonage de Flutter..."
if [ ! -d "$PROJECT_ROOT/_f" ]; then
  git clone https://github.com/flutter/flutter.git -b 3.38.7 --depth 1 "$PROJECT_ROOT/_f"
fi

# 2. Ajouter Flutter au PATH
export PATH="$PROJECT_ROOT/_f/bin:$PATH"

# 3. Aller dans le dossier frontend
# Si on est déjà dans frontend, on n'a rien à faire, sinon on y va
if [ -d "$PROJECT_ROOT/frontend" ]; then
  cd "$PROJECT_ROOT/frontend"
fi

echo "Nous sommes dans : $(pwd)"

# 4. Supprimer la librairie sqlite native
echo "Nettoyage du pubspec.yaml pour le Web..."
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml

# 5. Récupérer les dépendances
flutter pub get

# 6. Build de l'application Web
echo "Lancement du build Flutter Web..."
flutter build web --release --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api
