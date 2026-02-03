import 'dart:io';

void main() async {
  final file = File(
    r'c:\Users\rdenimal\Documents\App_Novadis\CRI_Novadis2.0\CRI_Novadis2.0\frontend\lib\data\local\app_database.g.dart',
  );
  final lines = await file.readAsLines();
  bool insideCriService = false;
  for (var line in lines) {
    if (line.contains('class CriService extends DataClass') ||
        line.trim().startsWith('class CriService ')) {
      insideCriService = true;
      print('Found CriService class');
    }
    if (insideCriService) {
      if (line.contains('interventionDurationMinutes')) {
        print(line.trim());
      }
      if (line.startsWith('class ') && !line.contains('CriService')) {
        if (line.startsWith('class ')) break;
      }
    }
  }
}
