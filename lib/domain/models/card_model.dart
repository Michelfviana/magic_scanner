class CardModel {
  final String id;
  final String name;
  final String edition;
  final String officialImageUrl;
  final String? localImagePath; // Caminho da imagem escaneada salva localmente
  final String? artCropUrl; // URL da arte recortada
  final String? borderCropUrl; // URL com borda
  final String? description; // Texto da carta (oracle text)
  final String? flavorText; // Texto de sabor
  final String rarity;
  final String?
      rarityCode; // Código da raridade (common, uncommon, rare, mythic)
  final String? typeLine; // Tipo da carta (ex: "Creature — Human Wizard")
  final String? manaCost; // Custo de mana (ex: "{2}{U}{U}")
  final int? cmc; // Converted Mana Cost
  final String? power; // Poder (criaturas)
  final String? toughness; // Resistência (criaturas)
  final List<String>? colors; // Cores da carta
  final List<String>? colorIdentity; // Identidade de cor
  final String? setCode; // Código do set
  final String? setName; // Nome do set
  final String? collectorNumber; // Número do colecionador
  final String? artist; // Nome do artista
  final List<String>? keywords; // Palavras-chave (Flying, Haste, etc.)
  final String? layout; // Layout da carta (normal, transform, modal_dfc, etc.)
  final String? releasedAt; // Data de lançamento
  final Map<String, dynamic>? legalities; // Legalidades em formatos
  final int? edhrecRank; // Ranking EDHREC
  final int? pennyRank; // Ranking Penny Dreadful
  final String? scryfallUri; // Link para Scryfall
  final int? tcgplayerId; // ID TCGPlayer
  final Map<String, double>
      prices; // { 'tcgplayer': 10.50, 'ligamagic': 45.00 }
  final DateTime scannedAt;

  CardModel({
    required this.id,
    required this.name,
    required this.edition,
    required this.officialImageUrl,
    required this.rarity,
    required this.prices,
    required this.scannedAt,
    this.localImagePath,
    this.artCropUrl,
    this.borderCropUrl,
    this.description,
    this.flavorText,
    this.rarityCode,
    this.typeLine,
    this.manaCost,
    this.cmc,
    this.power,
    this.toughness,
    this.colors,
    this.colorIdentity,
    this.setCode,
    this.setName,
    this.collectorNumber,
    this.artist,
    this.keywords,
    this.layout,
    this.releasedAt,
    this.legalities,
    this.edhrecRank,
    this.pennyRank,
    this.scryfallUri,
    this.tcgplayerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'edition': edition,
      'officialImageUrl': officialImageUrl,
      'localImagePath': localImagePath,
      'artCropUrl': artCropUrl,
      'borderCropUrl': borderCropUrl,
      'description': description,
      'flavorText': flavorText,
      'rarity': rarity,
      'rarityCode': rarityCode,
      'typeLine': typeLine,
      'manaCost': manaCost,
      'cmc': cmc,
      'power': power,
      'toughness': toughness,
      'colors': colors,
      'colorIdentity': colorIdentity,
      'setCode': setCode,
      'setName': setName,
      'collectorNumber': collectorNumber,
      'artist': artist,
      'keywords': keywords,
      'layout': layout,
      'releasedAt': releasedAt,
      'legalities': legalities,
      'edhrecRank': edhrecRank,
      'pennyRank': pennyRank,
      'scryfallUri': scryfallUri,
      'tcgplayerId': tcgplayerId,
      'prices': prices,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      edition: json['edition'] as String,
      officialImageUrl: json['officialImageUrl'] as String,
      localImagePath: json['localImagePath'] as String?,
      artCropUrl: json['artCropUrl'] as String?,
      borderCropUrl: json['borderCropUrl'] as String?,
      description: json['description'] as String?,
      flavorText: json['flavorText'] as String?,
      rarity: json['rarity'] as String,
      rarityCode: json['rarityCode'] as String?,
      typeLine: json['typeLine'] as String?,
      manaCost: json['manaCost'] as String?,
      cmc: json['cmc'] as int?,
      power: json['power'] as String?,
      toughness: json['toughness'] as String?,
      colors: json['colors'] != null
          ? List<String>.from(json['colors'] as List)
          : null,
      colorIdentity: json['colorIdentity'] != null
          ? List<String>.from(json['colorIdentity'] as List)
          : null,
      setCode: json['setCode'] as String?,
      setName: json['setName'] as String?,
      collectorNumber: json['collectorNumber'] as String?,
      artist: json['artist'] as String?,
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'] as List)
          : null,
      layout: json['layout'] as String?,
      releasedAt: json['releasedAt'] as String?,
      legalities: json['legalities'] != null
          ? Map<String, dynamic>.from(json['legalities'] as Map)
          : null,
      edhrecRank: json['edhrecRank'] as int?,
      pennyRank: json['pennyRank'] as int?,
      scryfallUri: json['scryfallUri'] as String?,
      tcgplayerId: json['tcgplayerId'] as int?,
      prices: Map<String, double>.from(json['prices'] as Map),
      scannedAt: json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'] as String)
          : DateTime.now(),
    );
  }

  CardModel copyWith({
    String? id,
    String? name,
    String? edition,
    String? officialImageUrl,
    String? localImagePath,
    String? artCropUrl,
    String? borderCropUrl,
    String? description,
    String? flavorText,
    String? rarity,
    String? rarityCode,
    String? typeLine,
    String? manaCost,
    int? cmc,
    String? power,
    String? toughness,
    List<String>? colors,
    List<String>? colorIdentity,
    String? setCode,
    String? setName,
    String? collectorNumber,
    String? artist,
    List<String>? keywords,
    String? layout,
    String? releasedAt,
    Map<String, dynamic>? legalities,
    int? edhrecRank,
    int? pennyRank,
    String? scryfallUri,
    int? tcgplayerId,
    Map<String, double>? prices,
    DateTime? scannedAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      edition: edition ?? this.edition,
      officialImageUrl: officialImageUrl ?? this.officialImageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      artCropUrl: artCropUrl ?? this.artCropUrl,
      borderCropUrl: borderCropUrl ?? this.borderCropUrl,
      description: description ?? this.description,
      flavorText: flavorText ?? this.flavorText,
      rarity: rarity ?? this.rarity,
      rarityCode: rarityCode ?? this.rarityCode,
      typeLine: typeLine ?? this.typeLine,
      manaCost: manaCost ?? this.manaCost,
      cmc: cmc ?? this.cmc,
      power: power ?? this.power,
      toughness: toughness ?? this.toughness,
      colors: colors ?? this.colors,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      setCode: setCode ?? this.setCode,
      setName: setName ?? this.setName,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      artist: artist ?? this.artist,
      keywords: keywords ?? this.keywords,
      layout: layout ?? this.layout,
      releasedAt: releasedAt ?? this.releasedAt,
      legalities: legalities ?? this.legalities,
      edhrecRank: edhrecRank ?? this.edhrecRank,
      pennyRank: pennyRank ?? this.pennyRank,
      scryfallUri: scryfallUri ?? this.scryfallUri,
      tcgplayerId: tcgplayerId ?? this.tcgplayerId,
      prices: prices ?? this.prices,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}
