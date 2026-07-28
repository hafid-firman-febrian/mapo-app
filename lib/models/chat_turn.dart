import 'mapo_response.dart';

/// Satu baris di layar chat. `sealed` supaya `switch` di UI wajib lengkap.
sealed class ChatTurn {
  const ChatTurn();
}

class UserTurn extends ChatTurn {
  final String text;
  const UserTurn(this.text);
}

class MapoTurn extends ChatTurn {
  final MapoResponse response;
  const MapoTurn(this.response);
}

/// Mapo sedang mengetik. Dimodelkan sebagai turn, bukan sebagai state
/// pengganti — supaya riwayat di atasnya tetap terlihat saat menunggu.
class PendingTurn extends ChatTurn {
  const PendingTurn();
}

class ErrorTurn extends ChatTurn {
  final String message;
  const ErrorTurn(this.message);
}
