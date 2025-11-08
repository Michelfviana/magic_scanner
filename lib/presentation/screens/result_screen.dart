import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/card_model.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? cardData;

  const ResultScreen({super.key, this.cardData});

  @override
  Widget build(BuildContext context) {
    if (cardData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: const Center(child: Text('Nenhum dado disponível')),
      );
    }

    // Se houver card_data, mostra tudo normalmente
    if (cardData!.containsKey('card_data')) {
      final card =
          CardModel.fromJson(cardData!['card_data'] as Map<String, dynamic>);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resultado'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.localImagePath != null &&
                        card.localImagePath!.isNotEmpty)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Imagem Escaneada',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(card.localImagePath!),
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 48),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 16),
                    if (card.officialImageUrl.isNotEmpty)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Imagem Oficial',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                card.officialImageUrl,
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 48),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (card.name.isNotEmpty)
                  Text(card.name,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                const SizedBox(height: 8),
                if (card.description != null &&
                    card.description!.isNotEmpty) ...[
                  const Text('Descrição da Imagem',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Text(card.description!,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[700], height: 1.5)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/scan');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Escanear Nova Carta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    // Se não houver card_data, mas houver nome ou descrição, mostra esses dados
    final name = cardData!['card_name'] as String?;
    final description = cardData!['description'] as String?;
    final localImagePath = cardData?['localImagePath'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (localImagePath != null && localImagePath.isNotEmpty)
                Column(
                  children: [
                    const Text('Imagem Escaneada',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(localImagePath),
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 48),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              if (name != null && name.isNotEmpty)
                Text(name,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Descrição da Imagem',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                Text(description,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[700], height: 1.5)),
              ],
              if ((name == null || name.isEmpty) &&
                  (description == null || description.isEmpty) &&
                  (localImagePath == null || localImagePath.isEmpty))
                const Text('Nenhum dado disponível'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/scan');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Escanear Nova Carta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void launchUrlExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey[700]!;
      case 'uncommon':
        return Colors.grey[500]!;
      case 'rare':
        return Colors.amber[700]!;
      case 'mythic':
      case 'mythic rare':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
