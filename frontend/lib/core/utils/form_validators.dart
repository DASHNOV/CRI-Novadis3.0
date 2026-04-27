import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter/material.dart';

/// Validateurs personnalisés pour les formulaires CRI
class CriFormValidators {
  /// Validateur pour le numéro de commande (CCNNNNN) — optionnel
  static FormFieldValidator<String> projectNumber({String? errorText}) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Champ optionnel
      }

      // Pattern: CC09813
      final regex = RegExp(r'^CC\d{5}$');
      if (!regex.hasMatch(value)) {
        return errorText ?? 'Format invalide (ex: CC09813)';
      }

      return null;
    };
  }

  /// Validateur pour le numéro de commande (CCNNNNN) — optionnel
  static FormFieldValidator<String> ticketNumber({String? errorText}) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Champ optionnel
      }

      // Pattern: CC09813
      final regex = RegExp(r'^CC\d{5}$');
      if (!regex.hasMatch(value)) {
        return errorText ?? 'Format invalide (ex: CC09813)';
      }

      return null;
    };
  }

  /// Validateur pour numéro de téléphone français
  static FormFieldValidator<String> frenchPhone({String? errorText}) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Le téléphone peut être optionnel
      }

      // Supprimer les espaces et tirets
      final cleanedValue = value.replaceAll(RegExp(r'[\s\-\.]'), '');

      // Patterns français valides:
      // - 0612345678 (10 chiffres commençant par 0)
      // - +33612345678 (avec indicatif)
      // - 0033612345678 (avec indicatif alternatif)
      final regex = RegExp(r'^(?:(?:\+|00)33|0)[1-9](?:[0-9]{8})$');

      if (!regex.hasMatch(cleanedValue)) {
        return errorText ?? 'Numéro de téléphone invalide';
      }

      return null;
    };
  }

  /// Validateur pour email
  static FormFieldValidator<String> email({
    String? errorText,
    bool required = false,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return required ? (errorText ?? 'L\'email est requis') : null;
      }

      final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

      if (!regex.hasMatch(value)) {
        return errorText ?? 'Email invalide';
      }

      return null;
    };
  }

  /// Validateur pour s'assurer qu'une date n'est pas dans le futur
  static FormFieldValidator<DateTime> notFutureDate({String? errorText}) {
    return (value) {
      if (value == null) {
        return errorText ?? 'La date est requise';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateToCheck = DateTime(value.year, value.month, value.day);

      if (dateToCheck.isAfter(today)) {
        return errorText ?? 'La date ne peut pas être dans le futur';
      }

      return null;
    };
  }

  /// Validateur pour s'assurer qu'une date n'est pas dans le passé
  static FormFieldValidator<DateTime> notPastDate({String? errorText}) {
    return (value) {
      if (value == null) {
        return null; // La date peut être optionnelle
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateToCheck = DateTime(value.year, value.month, value.day);

      if (dateToCheck.isBefore(today)) {
        return errorText ?? 'La date ne peut pas être dans le passé';
      }

      return null;
    };
  }

  /// Validateur pour comparer deux heures (fin après début)
  static FormFieldValidator<DateTime> timeAfter({
    required DateTime? startTime,
    String? errorText,
  }) {
    return (endTime) {
      if (endTime == null || startTime == null) {
        return null;
      }

      // Comparer seulement l'heure et les minutes
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      if (endMinutes <= startMinutes) {
        return errorText ?? 'L\'heure de fin doit être après l\'heure de début';
      }

      return null;
    };
  }

  /// Validateur pour champ requis avec message personnalisé
  static FormFieldValidator<T> required<T>({String? errorText}) {
    return (value) {
      if (value == null) {
        return errorText ?? 'Ce champ est requis';
      }

      if (value is String && value.trim().isEmpty) {
        return errorText ?? 'Ce champ est requis';
      }

      if (value is List && value.isEmpty) {
        return errorText ?? 'Ce champ est requis';
      }

      return null;
    };
  }

  /// Validateur pour longueur minimale
  static FormFieldValidator<String> minLength({
    required int min,
    String? errorText,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      if (value.length < min) {
        return errorText ?? 'Minimum $min caractères requis';
      }

      return null;
    };
  }

  /// Validateur pour longueur maximale
  static FormFieldValidator<String> maxLength({
    required int max,
    String? errorText,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      if (value.length > max) {
        return errorText ?? 'Maximum $max caractères autorisés';
      }

      return null;
    };
  }

  /// Combiner plusieurs validateurs
  static FormFieldValidator<T> compose<T>(
    List<FormFieldValidator<T>> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }
}

/// Extension pour faciliter l'utilisation avec FormBuilder
extension FormBuilderValidatorsExtension on FormBuilderValidators {
  /// Accès rapide aux validateurs CRI
  static CriFormValidators get cri => CriFormValidators();
}
