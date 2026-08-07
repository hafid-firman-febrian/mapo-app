import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dilempar saat user menutup Google account picker tanpa memilih akun.
/// Dipisah dari error lain supaya pemanggil bisa diam saja, bukan
/// menampilkan pesan error ke user yang memang sengaja membatalkan.
class GoogleSignInCancelledException implements Exception {
  @override
  String toString() =>
      'GoogleSignInCancelledException: user membatalkan sign-in';
}

/// `true` kalau kode error Firebase berarti akun Google yang dipilih sudah
/// ter-link ke Firebase user lain. Fungsi murni (bukan method) supaya bisa
/// diuji tanpa Firebase asli.
bool isCredentialConflict(String code) => code == 'credential-already-in-use';

/// Web client ID (`client_type: 3`) dari android/app/google-services.json —
/// diisi setelah Task 1 selesai. Dibutuhkan di Android supaya
/// GoogleSignIn.authenticate() mengembalikan idToken yang audience-nya
/// dikenali Firebase. Client ID bukan rahasia, aman untuk hardcode.
const _androidServerClientId = '169082720857-eliif939c7gt35ia60r1883467sfincc.apps.googleusercontent.com';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  AuthService(this._auth, [GoogleSignIn? googleSignIn])
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _androidServerClientId);
    _initialized = true;
  }

  /// Link akun anonim saat ini ke Google. Kalau akun Google itu sudah
  /// ter-link ke UID lain, fallback ke signInWithCredential — pindah ke
  /// akun lama alih-alih gagal (spec §Keputusan desain #1).
  Future<void> linkOrSignInWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google tidak mengembalikan idToken — cek serverClientId di Firebase Console',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Tidak ada sesi anonim untuk di-link (mis. signOut() sebelumnya gagal
      // membuat sesi anonim baru) — sign-in langsung sebagai fallback aman,
      // supaya tombol "Masuk" tetap bisa memulihkan app tanpa restart.
      await _auth.signInWithCredential(credential);
      return;
    }

    try {
      await currentUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (isCredentialConflict(e.code)) {
        await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }
  }

  /// Sign out dari Google + Firebase, lalu langsung signInAnonymously()
  /// lagi — app tidak boleh pernah dalam keadaan currentUser == null
  /// selagi berjalan (spec §Keputusan desain #2).
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  /// Firebase menolak `user.delete()` dengan `requires-recent-login` kalau sesi
  /// sudah basi. Dipanggil SEBELUM data apa pun dihapus, supaya kegagalan yang
  /// paling mungkin terjadi di titik yang belum merusak apa-apa — kalau
  /// urutannya dibalik, user bisa kehilangan riwayat sementara akunnya tetap
  /// hidup.
  Future<void> reauthenticateWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google tidak mengembalikan idToken — cek serverClientId di Firebase Console',
      );
    }

    // Fail-fast, bukan `currentUser?.` yang diam. App menegakkan invarian
    // "currentUser tidak pernah null selagi berjalan"; kalau invarian itu
    // dilanggar, re-autentikasi yang dilewati diam-diam akan membuat pemanggil
    // mengira sesi sudah segar padahal belum. Konsisten dengan StateError di
    // atas untuk idToken.
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Tidak ada sesi untuk di-reautentikasi — currentUser seharusnya tidak pernah null',
      );
    }

    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Sesudah akun dihapus, app langsung membuat sesi anonim baru — invarian
  /// yang sama dengan [signOut]: `currentUser` tidak pernah null selagi app
  /// berjalan.
  ///
  /// Data Firestore harus sudah dihapus SEBELUM ini dipanggil. Begitu akunnya
  /// hilang, `firestore.rules` tidak lagi mengizinkan menghapusnya dan
  /// `meal_history` jadi yatim selamanya.
  Future<void> deleteAccount() async {
    await _ensureInitialized();

    // Fail-fast, bukan `currentUser?.delete()` yang diam. Kalau delete
    // dilewati diam-diam, method ini tetap sign out + signInAnonymously dan
    // kembali seolah sukses — pemanggil mengira akun sudah terhapus padahal
    // masih hidup.
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Tidak ada akun untuk dihapus — currentUser seharusnya tidak pernah null',
      );
    }

    await user.delete();
    await _googleSignIn.signOut();
    await _auth.signInAnonymously();
  }
}
