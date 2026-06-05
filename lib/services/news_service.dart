import 'package:dio/dio.dart';

class NewsService {
  final Dio _dio = Dio();
  
  // Use a constante aqui, ou melhor, use-a no método abaixo:
  Future<List<dynamic>> fetchFinanceNews() async {
    const String apiKey = '2879b7011a854fbd864c59d4d040d4be'; // Declare aqui ou mantenha como atributo
    
    try {
      final response = await _dio.get(
        'https://newsapi.org/v2/everything?q=finanças&language=pt&apiKey=$apiKey', // Usando a variável
      );
      
      if (response.statusCode == 200) {
        return response.data['articles'];
      }
    } catch (e) {
      print("Erro ao buscar notícias: $e");
    }
    return [];
  }
}