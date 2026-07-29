import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/debug/mock_data.dart';

void main() {
  test('mockTurnsHome kosong', () {
    expect(mockTurnsHome(), isEmpty);
  });

  test('mockTurnsLoading berakhir dengan PendingTurn', () {
    expect(mockTurnsLoading().last, isA<PendingTurn>());
  });

  test('mockTurnsSingle berakhir dengan MapoTurn response_type single', () {
    final last = mockTurnsSingle().last as MapoTurn;
    expect(last.response.responseType, ResponseType.single);
    expect(last.response.recommendations, isNotEmpty);
  });

  test('mockTurnsOptions punya lebih dari satu rekomendasi', () {
    final last = mockTurnsOptions().last as MapoTurn;
    expect(last.response.responseType, ResponseType.options);
    expect(last.response.recommendations.length, greaterThan(1));
  });

  test('mockTurnsClarify punya quick_replies', () {
    final last = mockTurnsClarify().last as MapoTurn;
    expect(last.response.responseType, ResponseType.clarify);
    expect(last.response.followUp?.quickReplies, isNotEmpty);
  });

  test('mockTurnsError berakhir dengan ErrorTurn', () {
    expect(mockTurnsError().last, isA<ErrorTurn>());
  });

  test('mockMealHistoryEntries menyertakan satu entri harga null', () {
    expect(mockMealHistoryEntries().where((e) => e.price == null), isNotEmpty);
  });

  test('mockMealHistoryEmpty kosong', () {
    expect(mockMealHistoryEmpty, isEmpty);
  });
}
