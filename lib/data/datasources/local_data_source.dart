import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/card_model.dart';
import '../../core/constants/app_constants.dart';

/// DataSource local usando SQLite para persistência
class LocalDataSource {
  Database? _database;
  static bool _initialized = false;

  /// Inicializa o SQLite para desktop (Linux, Windows, macOS)
  static void initializeSqflite() {
    if (_initialized) return;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Inicializa sqflite_ffi para desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ SQLite inicializado com sqflite_ffi para desktop');
    } else {
      print('✅ SQLite usando implementação padrão para mobile');
    }

    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Garante que está inicializado
    initializeSqflite();

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        edition TEXT NOT NULL,
        officialImageUrl TEXT NOT NULL,
        localImagePath TEXT,
        artCropUrl TEXT,
        borderCropUrl TEXT,
        description TEXT,
        flavorText TEXT,
        rarity TEXT NOT NULL,
        rarityCode TEXT,
        typeLine TEXT,
        manaCost TEXT,
        cmc INTEGER,
        power TEXT,
        toughness TEXT,
        colors TEXT,
        colorIdentity TEXT,
        setCode TEXT,
        setName TEXT,
        collectorNumber TEXT,
        artist TEXT,
        keywords TEXT,
        layout TEXT,
        releasedAt TEXT,
        legalities TEXT,
        edhrecRank INTEGER,
        pennyRank INTEGER,
        scryfallUri TEXT,
        tcgplayerId INTEGER,
        prices TEXT NOT NULL,
        scannedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migração da versão 1 para 2 - adiciona novos campos básicos
      await db.execute('ALTER TABLE cards ADD COLUMN localImagePath TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN typeLine TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN manaCost TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN cmc INTEGER');
      await db.execute('ALTER TABLE cards ADD COLUMN power TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN toughness TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN colors TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN setCode TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN collectorNumber TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN artist TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN keywords TEXT');
    }
    if (oldVersion < 3) {
      // Migração da versão 2 para 3 - adiciona campos detalhados
      await db.execute('ALTER TABLE cards ADD COLUMN artCropUrl TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN borderCropUrl TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN flavorText TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN rarityCode TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN colorIdentity TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN setName TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN layout TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN releasedAt TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN legalities TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN edhrecRank INTEGER');
      await db.execute('ALTER TABLE cards ADD COLUMN pennyRank INTEGER');
      await db.execute('ALTER TABLE cards ADD COLUMN scryfallUri TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN tcgplayerId INTEGER');
    }
  }

  /// Salva uma carta no banco de dados
  Future<void> saveCard(CardModel card) async {
    print('💾 LocalDataSource.saveCard: Iniciando salvamento...');
    final db = await database;
    final json = card.toJson();

    print('   Card ID: ${json['id']}');
    print('   Card Name: ${json['name']}');
    print('   Local Image Path: ${json['localImagePath']}');

    // Serializa arrays e maps como JSON string para SQLite
    json['prices'] = jsonEncode(json['prices']);
    if (json['colors'] != null) {
      json['colors'] = jsonEncode(json['colors']);
    }
    if (json['colorIdentity'] != null) {
      json['colorIdentity'] = jsonEncode(json['colorIdentity']);
    }
    if (json['keywords'] != null) {
      json['keywords'] = jsonEncode(json['keywords']);
    }
    if (json['legalities'] != null) {
      json['legalities'] = jsonEncode(json['legalities']);
    }

    try {
      await db.insert(
        'cards',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('   ✅ Carta inserida no banco de dados!');
    } catch (e) {
      print('   ❌ Erro ao inserir no banco: $e');
      rethrow;
    }
  }

  /// Obtém todas as cartas do histórico
  Future<List<CardModel>> getAllCards() async {
    print('📚 LocalDataSource.getAllCards: Carregando histórico...');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      orderBy: 'scannedAt DESC',
    );

    print('   Total de cartas no banco: ${maps.length}');

    if (maps.isEmpty) {
      print('   ⚠️  Nenhuma carta encontrada no banco de dados!');
      return [];
    }

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // Deserializa JSON strings
      if (map['prices'] is String) {
        map['prices'] = jsonDecode(map['prices'] as String);
      }
      if (map['colors'] is String && map['colors'] != null) {
        map['colors'] = jsonDecode(map['colors'] as String);
      }
      if (map['colorIdentity'] is String && map['colorIdentity'] != null) {
        map['colorIdentity'] = jsonDecode(map['colorIdentity'] as String);
      }
      if (map['keywords'] is String && map['keywords'] != null) {
        map['keywords'] = jsonDecode(map['keywords'] as String);
      }
      if (map['legalities'] is String && map['legalities'] != null) {
        map['legalities'] = jsonDecode(map['legalities'] as String);
      }

      if (i == 0) {
        print('   Primeira carta: ${map['name']} (ID: ${map['id']})');
      }

      return CardModel.fromJson(map);
    });
  }

  /// Remove uma carta do histórico
  Future<void> deleteCard(String cardId) async {
    final db = await database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Limpa todo o histórico
  Future<void> clearAllCards() async {
    final db = await database;
    await db.delete('cards');
  }

  /// Verifica se uma carta já existe no histórico
  Future<bool> cardExists(String cardId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Salva uma imagem localmente e retorna o caminho
  Future<String> saveImageLocally(String imagePath, String cardId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/card_images');

      // Cria o diretório se não existir
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final file = File(imagePath);
      final extension = imagePath.split('.').last;
      final newPath = '${imagesDir.path}/$cardId.$extension';

      // Copia a imagem para o diretório do app
      await file.copy(newPath);

      return newPath;
    } catch (e) {
      print('Erro ao salvar imagem localmente: $e');
      return imagePath; // Retorna o caminho original em caso de erro
    }
  }

  /// Deleta uma imagem local
  Future<void> deleteLocalImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao deletar imagem local: $e');
    }
  }
}
