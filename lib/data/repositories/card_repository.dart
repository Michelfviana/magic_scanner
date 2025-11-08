import '../../domain/models/card_model.dart';

/// Repository abstrato para gerenciar dados de cartas
///
/// Esta classe será implementada com:
/// - RemoteDataSource: Para chamadas ao backend
/// - LocalDataSource: Para persistência local (SQLite/Hive)
abstract class CardRepository {
  /// Escaneia uma carta a partir de uma imagem
  /// Retorna um Map com descrição, nome e dados completos (se houver)
  Future<Map<String, dynamic>> scanCard(String imagePath);

  /// Obtém o histórico de cartas escaneadas
  Future<List<CardModel>> getHistory();

  /// Adiciona uma carta ao histórico
  Future<void> addToHistory(CardModel card);

  /// Remove uma carta do histórico
  Future<void> removeFromHistory(String cardId);

  /// Limpa todo o histórico
  Future<void> clearHistory();
}
