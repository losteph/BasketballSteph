import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveJsonPlatform(String fileName, String jsonStr) async {
  final bytes = Uint8List.fromList(utf8.encode(jsonStr));

  // 1. Prova prima con il selettore nativo di cartella (FilePicker)
  try {
    final String? resultPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (resultPath != null && resultPath.isNotEmpty) {
      // Su Desktop (Windows/Mac/Linux) saveFile restituisce solo il percorso e dobbiamo scriverci dentro i byte!
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final file = File(resultPath);
        await file.writeAsBytes(bytes, flush: true);
      }
      return true;
    }
  } catch (_) {
    // Se FilePicker fallisce su dispositivi specifici, passa automaticamente al piano B qui sotto
  }

  // 2. Piano B infallibile: Salva in temporaneo e apre il menu "Salva su dispositivo / Condividi"
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
    return true;
  } catch (_) {
    return false;
  }
}