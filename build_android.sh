#!/bin/bash
set -e

# Déterminer la racine du projet
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Projet root: $PROJECT_ROOT"

# 1. Cloner Flutter si absent
if [ ! -d "$PROJECT_ROOT/_f" ]; then
  echo "Clonage de Flutter..."
  git clone https://github.com/flutter/flutter.git -b 3.38.7 --depth 1 "$PROJECT_ROOT/_f"
fi

# 2. Ajouter Flutter au PATH
export PATH="$PROJECT_ROOT/_f/bin:$PATH"

# 3. Aller dans le dossier frontend
cd "$PROJECT_ROOT/frontend"

# 4. Récupérer les dépendances
flutter pub get

# 5. Build APK release avec obfuscation
# --obfuscate              : obfusque le code Dart (anti rétro-ingénierie)
# --split-debug-info=...   : extrait les symboles de debug dans un dossier séparé
#                            (à conserver pour pouvoir désobfusquer les stack traces)
# --tree-shake-icons       : retire les icônes Material/Cupertino non utilisées
DEBUG_INFO_DIR="$PROJECT_ROOT/build/debug-info-android"
mkdir -p "$DEBUG_INFO_DIR"

echo "Build APK release (obfusqué)..."
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info="$DEBUG_INFO_DIR" \
  --tree-shake-icons \
  --dart-define=API_URL=https://api.cri-novadis.tech/api

echo ""
echo "✅ APK généré : frontend/build/app/outputs/flutter-apk/app-release.apk"
echo "🔒 Symboles de debug : $DEBUG_INFO_DIR"
echo "⚠️  Conserver ce dossier pour désobfusquer les crash reports."
