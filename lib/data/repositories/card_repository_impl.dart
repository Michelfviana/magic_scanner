import '../../domain/models/card_model.dart';
import 'card_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// Implementação concreta do CardRepository
class CardRepositoryImpl implements CardRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;

  CardRepositoryImpl({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> scanCard(String imagePath) async {
    try {
      print('🔍 CardRepository: Iniciando scan da imagem: $imagePath');

      // Recebe resposta flexível do backend
      final result = await _remoteDataSource.scanCard(imagePath);

      print('📦 CardRepository: Resposta do backend recebida');
      print('   Keys presentes: ${result.keys.toList()}');
      print('   Contém card_data: ${result.containsKey('card_data')}');

      // Se houver dados completos, salva no histórico
      if (result.containsKey('card_data')) {
        print('✅ CardRepository: card_data encontrado, processando...');

        final cardData = result['card_data'] as Map<String, dynamic>;
        print('   Nome da carta: ${cardData['name']}');

        final card = CardModel.fromJson(cardData);
        print('   Card model criado com ID: ${card.id}');

        // Salva a imagem localmente
        print('💾 CardRepository: Salvando imagem localmente...');
        final localImagePath = await _localDataSource.saveImageLocally(
          imagePath,
          card.id,
        );
        print('   Imagem salva em: $localImagePath');

        // Atualiza o card com o caminho da imagem local
        final cardWithLocalImage = card.copyWith(
          localImagePath: localImagePath,
          scannedAt: DateTime.now(),
        );

        print('💿 CardRepository: Salvando no histórico...');
        await addToHistory(cardWithLocalImage);
        print('✅ CardRepository: Carta salva no histórico com sucesso!');
      } else {
        print('⚠️  CardRepository: card_data NÃO encontrado na resposta');
      }

      return result;
    } catch (e) {
      print('❌ CardRepository: Erro ao processar scan: $e');
      rethrow;
    }
  }

  @override
  Future<List<CardModel>> getHistory() async {
    // Por enquanto, retorna apenas do banco local
    // Futuramente pode sincronizar com o servidor
    return await _localDataSource.getAllCards();
  }

  @override
  Future<void> addToHistory(CardModel card) async {
    print('💿 addToHistory: Verificando se carta já existe...');
    // Verifica se já existe para evitar duplicatas
    final exists = await _localDataSource.cardExists(card.id);
    print('   Carta existe? $exists');

    if (!exists) {
      print('   Salvando nova carta no banco...');
      await _localDataSource.saveCard(card);
      print('   ✅ Carta salva com sucesso!');
    } else {
      print('   ℹ️  Carta já existe no histórico, pulando...');
    }
  }

  @override
  Future<void> removeFromHistory(String cardId) async {
    // Primeiro, busca a carta para obter o caminho da imagem local
    final allCards = await _localDataSource.getAllCards();
    final card = allCards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => throw Exception('Carta não encontrada'),
    );

    // Deleta a imagem local se existir
    if (card.localImagePath != null) {
      await _localDataSource.deleteLocalImage(card.localImagePath);
    }

    // Deleta a entrada do banco
    await _localDataSource.deleteCard(cardId);
  }

  @override
  Future<void> clearHistory() async {
    // Primeiro, obtém todas as cartas para deletar as imagens
    final allCards = await _localDataSource.getAllCards();

    // Deleta todas as imagens locais
    for (final card in allCards) {
      if (card.localImagePath != null) {
        await _localDataSource.deleteLocalImage(card.localImagePath);
      }
    }

    // Limpa o banco de dados
    await _localDataSource.clearAllCards();
  }
}
