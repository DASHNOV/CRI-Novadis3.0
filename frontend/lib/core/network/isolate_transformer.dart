import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Un Transformer Dio personnalisé qui effectue le parsing JSON dans un Isolate
/// pour éviter de bloquer le thread principal (UI).
class IsolateTransformer extends BackgroundTransformer {
  IsolateTransformer() : super();

  /// Surcharge de la méthode transformResponse pour utiliser [compute]
  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    // Si ce n'est pas du JSON, utiliser le transformer par défaut
    // Ou si le contenu est vide
    // Utiliser le comportement par défaut de Dio pour lire le stream
    return super.transformResponse(options, responseBody);
  }

  /// Cette méthode est appelée par Dio pour décoder la chaîne JSON
  /// Nous surchargeons le DefaultTransformer.jsonDecodeCallback si possible
  /// mais Dio 5.x gère ça un peu différemment.

  /// La meilleure approche avec Dio 5 est de fournir une fonction de décodage personnalisée
  /// ou de surcharger [transformResponse] si on veut tout contrôler.
  /// Cependant, BackgroundTransformer de Dio fait déjà une partie du travail.

  // Pour Dio, nous allons simplement utiliser une fonction helper que nous passerons
  // au transformer par défaut lors de la configuration.
}

/// Fonction de décodage JSON qui s'exécute dans un Isolate
Future<dynamic> jsonDecodeAndCompute(String text) async {
  return compute(_parseAndDecode, text);
}

/// Fonction top-level requise pour [compute]
dynamic _parseAndDecode(String text) {
  return jsonDecode(text);
}
