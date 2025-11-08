import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/card_model.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/card_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';

/// Provider para LocalDataSource (singleton)
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSource();
});

/// Provider para RemoteDataSource (singleton)
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return RemoteDataSource();
});

/// Provider para CardRepository (singleton)
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepositoryImpl(
    localDataSource: ref.watch(localDataSourceProvider),
    remoteDataSource: ref.watch(remoteDataSourceProvider),
  );
});

/// Provider para o estado de carregamento do scan
final scanLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider para armazenar o resultado do último scan
final scanResultProvider = StateProvider<CardModel?>((ref) => null);

/// Provider para o histórico de cartas (com auto-refresh)
final historyProvider = FutureProvider<List<CardModel>>((ref) async {
  final repository = ref.watch(cardRepositoryProvider);
  return await repository.getHistory();
});

