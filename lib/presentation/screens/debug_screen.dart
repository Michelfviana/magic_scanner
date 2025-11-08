import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../../data/datasources/local_data_source.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  Future<Map<String, dynamic>> _getDatabaseInfo() async {
    try {
      // Garante que o SQLite está inicializado
      LocalDataSource.initializeSqflite();

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'magic_scanner.db');

      final db = await openDatabase(path);

      // Verifica tabelas
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

      // Conta registros
      final count = await db.rawQuery("SELECT COUNT(*) as count FROM cards");

      // Pega todos os registros
      final cards = await db.rawQuery("SELECT * FROM cards");

      await db.close();

      return {
        'database_path': path,
        'tables': tables,
        'card_count': count.first['count'],
        'cards': cards,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Banco de Dados'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDatabaseInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          }

          final info = snapshot.data!;

          if (info.containsKey('error')) {
            return Center(
              child: Text('Erro ao acessar banco: ${info['error']}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caminho do Banco de Dados:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SelectableText(
                  info['database_path'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tabelas:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text((info['tables'] as List).toString()),
                const SizedBox(height: 16),
                Text(
                  'Total de Cartas:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${info['card_count']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registros:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...(info['cards'] as List).map((card) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${card['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Nome: ${card['name']}'),
                          Text('Edição: ${card['edition']}'),
                          Text('Raridade: ${card['rarity']}'),
                          Text('Scanned At: ${card['scannedAt']}'),
                          if (card['localImagePath'] != null)
                            Text('Imagem Local: ${card['localImagePath']}'),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(historyProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Histórico atualizado!')),
                    );
                  },
                  child: const Text('Atualizar Histórico'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
