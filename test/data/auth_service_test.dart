import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/auth_service.dart';

void main() {
  test('GoogleSignInCancelledException punya pesan yang bisa dibaca', () {
    expect(
      GoogleSignInCancelledException().toString(),
      contains('membatalkan'),
    );
  });

  test('isCredentialConflict true untuk kode credential-already-in-use', () {
    expect(isCredentialConflict('credential-already-in-use'), isTrue);
  });

  test('isCredentialConflict false untuk kode lain', () {
    expect(isCredentialConflict('network-request-failed'), isFalse);
  });
}
