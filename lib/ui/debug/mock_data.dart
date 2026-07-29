import '../../models/chat_turn.dart';
import '../../models/mapo_response.dart';
import '../../models/meal_history_entry.dart';

MapoResponse mockSingleResponse() => const MapoResponse(
      responseType: ResponseType.single,
      message: 'Buat kamu yang lagi pengen anget',
      recommendations: [
        Recommendation(
          name: 'Soto Ayam',
          reason: 'Kuahnya anget pas buat cuaca hujan, ringan, dan masih di bawah budget kamu.',
          category: 'berkuah',
          priceEstimate: 13000,
          spiceLevel: 'sedang',
          prepTime: 'cepat',
          tags: ['hangat'],
        ),
      ],
      contextUsed: ContextUsed(weather: 'hujan ringan'),
    );

MapoResponse mockOptionsResponse() => const MapoResponse(
      responseType: ResponseType.options,
      message: 'Ada 3 pilihan yang cocok buat cuaca hujan hari ini:',
      recommendations: [
        Recommendation(
          name: 'Soto Ayam',
          reason: 'Kuahnya anget',
          category: 'berkuah',
          priceEstimate: 13000,
          spiceLevel: 'sedang',
          prepTime: 'cepat',
        ),
        Recommendation(
          name: 'Bakso',
          reason: 'Kuahnya agak pedas',
          category: 'pedas',
          priceEstimate: 15000,
          spiceLevel: 'pedas',
          prepTime: 'cepat',
        ),
        Recommendation(
          name: 'Bakmi Godog',
          reason: 'Gurih dan mengenyangkan',
          category: 'mie',
          priceEstimate: 12000,
          spiceLevel: 'tidak_pedas',
          prepTime: 'sedang',
        ),
      ],
    );

MapoResponse mockClarifyResponse() => const MapoResponse(
      responseType: ResponseType.clarify,
      message: 'Siap bantu!',
      followUp: FollowUp(
        question: 'Biar pas, kamu lagi pengen yang gimana nih?',
        quickReplies: ['yang murah', 'yang pedas', 'yang cepet', 'yang sehat'],
      ),
    );

List<ChatTurn> mockTurnsHome() => const [];

List<ChatTurn> mockTurnsLoading() => const [UserTurn('lagi hujan, pengen anget'), PendingTurn()];

List<ChatTurn> mockTurnsSingle() =>
    [const UserTurn('lagi hujan, pengen anget'), MapoTurn(mockSingleResponse())];

List<ChatTurn> mockTurnsOptions() =>
    [const UserTurn('bingung, kasih pilihan dong'), MapoTurn(mockOptionsResponse())];

List<ChatTurn> mockTurnsClarify() => [const UserTurn('aku laper'), MapoTurn(mockClarifyResponse())];

List<ChatTurn> mockTurnsError() =>
    const [UserTurn('laper'), ErrorTurn('Mapo lagi bingung, coba lagi ya')];

List<MealHistoryEntry> mockMealHistoryEntries() => [
      MealHistoryEntry(
        name: 'Soto Ayam',
        category: 'berkuah',
        eatenAt: DateTime.now().subtract(const Duration(hours: 2)),
        price: 13000,
      ),
      MealHistoryEntry(
        name: 'Ayam Bakar',
        category: 'bakar',
        eatenAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        price: 20000,
      ),
      // Harga null — kondisi nyata sebelum Task 6 arsitektur menyimpan harga.
      MealHistoryEntry(
        name: 'Bakso',
        category: 'berkuah',
        eatenAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      ),
    ];

const mockMealHistoryEmpty = <MealHistoryEntry>[];
