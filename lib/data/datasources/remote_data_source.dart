import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/models/card_model.dart';
import '../../core/constants/app_constants.dart';

/// DataSource remoto para comunicação com o backend
class RemoteDataSource {
  final Dio _dio;

  RemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout:
                    const Duration(minutes: 5), // 5 minutos para casos extremos
                sendTimeout: const Duration(seconds: 60),
              ),
            );

  /// Envia uma imagem para o backend e recebe a descrição, nome e dados completos (se houver)
  Future<Map<String, dynamic>> scanCard(String imagePath) async {
    // Tenta até 2 vezes em caso de timeout
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final file = File(imagePath);
        final fileName = file.path.split('/').last;

        // Verifica se arquivo existe e não está vazio
        if (!await file.exists()) {
          throw Exception('Arquivo de imagem não encontrado');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Arquivo de imagem está vazio');
        }

        // Limite de 10MB
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception(
              'Imagem muito grande (máximo 10MB). Tente comprimir a imagem ou usar uma menor resolução.');
        }

        print(
            '📤 Tentativa $attempt: Enviando imagem (${(fileSize / 1024).toStringAsFixed(1)}KB)...');

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imagePath,
            filename: fileName,
          ),
        });

        final response = await _dio.post(
          AppConstants.scanEndpoint,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
            // Timeout específico para esta requisição
            receiveTimeout: Duration(minutes: attempt == 1 ? 3 : 5),
            sendTimeout: const Duration(minutes: 2),
          ),
        );

        if (response.statusCode == 200) {
          print('✅ Resposta recebida com sucesso');
          return response.data as Map<String, dynamic>;
        } else {
          throw Exception(
              'Erro HTTP ${response.statusCode}: ${response.statusMessage}');
        }
      } on DioException catch (e) {
        final isLastAttempt = attempt == 2;

        if (e.type == DioExceptionType.receiveTimeout) {
          if (isLastAttempt) {
            throw Exception(
                'Timeout após $attempt tentativas. A imagem pode ser muito complexa para processar. '
                'Tente:\n'
                '• Uma imagem mais simples\n'
                '• Melhor iluminação\n'
                '• Carta mais centralizada\n'
                '• Imagem menor (< 2MB)');
          } else {
            print('⏳ Tentativa $attempt: Timeout, tentando novamente...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } else if (e.type == DioExceptionType.sendTimeout) {
          throw Exception(
              'Timeout no envio da imagem. Verifique sua conexão ou tente uma imagem menor.');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
              'Não foi possível conectar ao servidor. Verifique se o backend está rodando.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception(
              'Erro de conexão. Verifique sua internet e se o servidor está acessível.');
        } else {
          throw Exception('Erro de rede: ${e.message}');
        }
      } catch (e) {
        if (attempt == 2) {
          throw Exception('Erro ao processar imagem: $e');
        } else {
          print('⚠️ Tentativa $attempt falhou: $e');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      }
    }

    throw Exception('Falha após múltiplas tentativas');
  }

  /// Obtém o histórico do servidor (opcional, se houver sincronização)
  Future<List<CardModel>> getHistoryFromServer() async {
    try {
      final response = await _dio.get(AppConstants.historyEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => CardModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Erro ao obter histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao comunicar com o servidor: $e');
    }
  }
}
