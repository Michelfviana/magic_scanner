class AppConstants {
  // API Endpoints - Backend Python FastAPI na porta 8000
  static const String baseUrl = 'http://localhost:8000';
  static const String scanEndpoint = '/api/scan';
  static const String historyEndpoint = '/api/history';

  /// Configurações de banco de dados
  static const String databaseName = 'magic_scanner.db';
  static const int databaseVersion =
      3; // Incrementado para suportar novos campos

  // App Info
  static const String appName = 'Magic Scanner';
  static const String appSubtitle = 'Identificador de cartas MTG';
}
