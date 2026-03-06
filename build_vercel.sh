#!/bin/bash

# 1. Cloner Flutter (version stable spécifiée) dans un dossier temporaire
echo "Clonage de Flutter..."
git clone https://github.com/flutter/flutter.git -b 3.38.7 --depth 1 _f

# 2. Ajouter Flutter au PATH
export PATH="$PWD/_f/bin:$PATH"

# 3. Aller dans le dossier frontend
cd frontend

# 4. Supprimer la librairie sqlite native (cause des erreurs de compilation Web)
echo "Nettoyage du pubspec.yaml pour le Web..."
sed -i '/sqlite3_flutter_libs/d' pubspec.yaml

# 5. Récupérer les dépendances
flutter pub get

# 6. Build de l'application Web
echo "Lancement du build Flutter Web..."
flutter build web --release --dart-define=API_URL=https://armando-coenobitic-ebony.ngrok-free.dev/api

# 7. Déplacer le résultat à la racine si nécessaire (Vercel cherche souvent dans 'public' ou 'dist')
# Si votre Root Directory sur Vercel est 'frontend', le dossier 'build/web' sera utilisé automatiquement.
