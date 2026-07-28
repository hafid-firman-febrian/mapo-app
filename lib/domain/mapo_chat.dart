import 'package:firebase_ai/firebase_ai.dart';

/// Satu-satunya interface abstrak di proyek ini, dan alasannya spesifik:
/// [GenerativeModel] adalah `final class` sehingga tidak bisa disubclass atau
/// di-mock. Tanpa seam ini, logika domain tidak bisa diuji tanpa memanggil
/// Gemini sungguhan.
abstract interface class MapoChat {
  /// Mengirim [text] dan mengembalikan teks respons mentah, atau `null`
  /// kalau model tidak mengembalikan kandidat apa pun.
  Future<String?> send(String text);
}

class FirebaseMapoChat implements MapoChat {
  final ChatSession _session;

  FirebaseMapoChat(this._session);

  @override
  Future<String?> send(String text) async {
    final response = await _session.sendMessage(Content.text(text));
    return response.text;
  }
}
