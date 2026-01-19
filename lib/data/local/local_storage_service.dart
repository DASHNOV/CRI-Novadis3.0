import 'package:novadis_cri/data/models/cri_model.dart';

/// Service de stockage local pour les CRI
/// Utilise une liste en mémoire pour simuler le stockage
class LocalStorageService {
  // Liste mock de CRI en mémoire
  static final List<CriModel> _criList = [
    CriModel(
      id: '1',
      client: 'Client A',
      site: 'Site Paris Nord',
      typeIntervention: 'Maintenance préventive',
      description: 'Vérification des équipements de sécurité',
      date: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    CriModel(
      id: '2',
      client: 'Client B',
      site: 'Site Lyon Centre',
      typeIntervention: 'Dépannage',
      description: 'Réparation système électrique',
      date: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CriModel(
      id: '3',
      client: 'Client C',
      site: 'Site Marseille Sud',
      typeIntervention: 'Installation',
      description: 'Installation nouveau système de climatisation',
      date: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// Récupère tous les CRI
  Future<List<CriModel>> getAllCri() async {
    // Simule un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_criList);
  }

  /// Récupère un CRI par son ID
  Future<CriModel?> getCriById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _criList.firstWhere((cri) => cri.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ajoute un nouveau CRI
  Future<bool> addCri(CriModel cri) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _criList.add(cri);
    return true;
  }

  /// Met à jour un CRI existant
  Future<bool> updateCri(CriModel cri) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _criList.indexWhere((c) => c.id == cri.id);
    if (index != -1) {
      _criList[index] = cri;
      return true;
    }
    return false;
  }

  /// Supprime un CRI
  Future<bool> deleteCri(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final initialLength = _criList.length;
    _criList.removeWhere((cri) => cri.id == id);
    return _criList.length < initialLength;
  }

  /// Génère un nouvel ID unique
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
