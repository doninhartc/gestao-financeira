import 'dart:async'; // Necessário para o Timer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../viewmodels/auth_provider.dart';
import '../viewmodels/transaction_provider.dart';
import '../models/transaction_model.dart';
import 'login_view.dart';
import '../widgets/transaction_form.dart';
import '../widgets/skeleton_loader.dart';

final newsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = Dio();
  const String apiKey = '2879b7011a854fbd864c59d4d040d4be';
  final response = await dio.get('https://newsapi.org/v2/everything?q=finanças&language=pt&apiKey=$apiKey');
  return response.data['articles'] ?? [];
});

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  bool _isFetchingData = true;
  bool _isBalanceVisible = true;
  Timer? _newsTimer; // Timer para atualizar as notícias

  @override
  void initState() {
    super.initState();
    _simulateNetworkLoad();
    
    // Configura a atualização automática das notícias a cada 1 minuto (60 segundos)
    _newsTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      ref.invalidate(newsProvider);
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel(); // Limpa o timer da memória ao fechar a tela
    super.dispose();
  }

  Future<void> _simulateNetworkLoad() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isFetchingData = false);
  }

  // Função auxiliar para atualizar manualmente ao puxar a página (Pull-to-refresh opcional)
  Future<void> _refreshPage() async {
    ref.invalidate(newsProvider);
    await _simulateNetworkLoad();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final transactions = ref.watch(transactionProvider);
    final txNotifier = ref.read(transactionProvider.notifier);
    final newsAsync = ref.watch(newsProvider);

    final String initial = user?.name != null && user!.name.isNotEmpty 
        ? user.name[0].toUpperCase() 
        : 'U';

    // Layout Responsivo: Define a largura do card com base na tela para não cortar feio
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth > 600 ? 280 : screenWidth * 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFF11141E), 
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () => _showTransactionForm(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPage, // Atualiza quando o usuário arrasta para baixo
          backgroundColor: const Color(0xFF23283B),
          color: Colors.blueAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF23283B),
                        child: Text(initial, style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Olá,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(user?.name ?? 'Usuário', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
                        },
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Saldo Disponível', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                            child: Icon(_isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isFetchingData ? 'R\$ ...' : _isBalanceVisible ? 'R\$ ${txNotifier.currentBalance.toStringAsFixed(2)}' : 'R\$ •••••',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(child: _buildInfoCard('Receitas', _isFetchingData ? 0.0 : txNotifier.totalIncome, Icons.call_made, Colors.greenAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoCard('Despesas', _isFetchingData ? 0.0 : txNotifier.totalExpense, Icons.call_received, Colors.redAccent)),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text("Dicas Financeiras", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                // --- CONTEXTO DE UX SUPERIOR: ANIMAÇÃO, SKELETON E ERROS ---
                SizedBox(
                  height: 220, 
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: newsAsync.when(
                      loading: () => ListView.builder(
                        key: const ValueKey('news_loading'),
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        padding: const EdgeInsets.only(right: 24),
                        itemBuilder: (context, index) => _buildSkeletonNewsCard(cardWidth),
                      ),
                      error: (err, _) => Padding(
                        key: const ValueKey('news_error'),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFF5252), // CORRIGIDO: Vermelho transparente em Hexadecimal
                            borderRadius: BorderRadius.circular(12), 
                            border: Border.all(color: const Color(0x4DFF5252)) // CORRIGIDO: Borda em Hexadecimal
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.redAccent), // CORRIGIDO: Ícone válido
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text("Erro de conexão", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text("Não foi possível carregar o feed. Atualizando em instantes.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (news) {
                        if (news == null || news.isEmpty) {
                          return const Center(key: ValueKey('news_empty'), child: Text("Sem dicas no momento.", style: TextStyle(color: Colors.white54)));
                        }
                        
                        // Limitando o feed para exibir no máximo 5 notícias
                        final displayNews = news.take(5).toList();

                        return ListView.builder(
                          key: const ValueKey('news_success'),
                          scrollDirection: Axis.horizontal,
                          itemCount: displayNews.length,
                          padding: const EdgeInsets.only(right: 24),
                          itemBuilder: (context, index) {
                            final article = displayNews[index];
                            final imageUrl = article['urlToImage'];
                            final title = article['title'] ?? 'Sem título';
                            final sourceName = article['source']?['name'] ?? 'Notícia';
                            final articleUrl = article['url'];

                            return Container(
                              width: cardWidth, 
                              margin: const EdgeInsets.only(left: 24, bottom: 8, top: 4), 
                              decoration: BoxDecoration(
                                color: const Color(0xFF23283B),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias, 
                              child: Material(
                                color: Colors.transparent, 
                                child: InkWell(
                                  onTap: () async {
                                    if (articleUrl != null) {
                                      final Uri url = Uri.parse(articleUrl);
                                      try {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Não foi possível abrir o link.'), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (imageUrl != null && imageUrl.toString().startsWith('http'))
                                        Image.network(
                                          imageUrl,
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 110, width: double.infinity, color: const Color(0xFF181C2A),
                                            child: const Icon(Icons.image_not_supported, color: Colors.white24),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 110, width: double.infinity, color: const Color(0xFF181C2A),
                                          child: const Icon(Icons.newspaper, color: Colors.white24),
                                        ),
                                        
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                sourceName.toString().toUpperCase(),
                                                style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text("Transações Recentes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                _isFetchingData
                    ? const SizedBox(height: 300, child: SkeletonLoader())
                    : transactions.isEmpty
                        ? const Center(child: Text('Nenhuma transação.', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF23283B), borderRadius: BorderRadius.circular(12)), child: Icon(tx.type == TransactionType.income ? Icons.account_balance_wallet : Icons.shopping_bag_outlined, color: Colors.white70)),
                                    const SizedBox(width: 16),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx.title, style: const TextStyle(color: Colors.white)), Text('${tx.date.day}/${tx.date.month}', style: const TextStyle(color: Colors.white54))])),
                                    Text('${tx.type == TransactionType.income ? '+' : '-'} R\$ ${tx.value.toStringAsFixed(2)}', style: TextStyle(color: tx.type == TransactionType.income ? Colors.greenAccent : Colors.white)),
                                    
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                                      color: const Color(0xFF2C2C2C),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 400),
                                                child: TransactionForm(transactionToEdit: tx), 
                                              ),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          if (tx.id != null) {
                                            ref.read(transactionProvider.notifier).deleteTransaction(tx.id!);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(children: [Icon(Icons.edit, color: Colors.blueAccent, size: 20), SizedBox(width: 8), Text('Editar', style: TextStyle(color: Colors.white))]),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: Colors.white))]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: const TransactionForm(),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF23283B), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(_isBalanceVisible ? 'R\$ ${value.toStringAsFixed(2)}' : 'R\$ •••••', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR: Skeleton individual para os Cards de Notícia ---
  Widget _buildSkeletonNewsCard(double width) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(left: 24, bottom: 8, top: 4),
      decoration: BoxDecoration(color: const Color(0xFF23283B), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 110, width: double.infinity, color: const Color(0xFF181C2A)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: double.infinity, color: const Color(0xFF181C2A)),
                      const SizedBox(height: 6),
                      Container(height: 12, width: width * 0.6, color: const Color(0xFF181C2A)),
                    ],
                  ),
                  Container(height: 10, width: 60, color: const Color(0xFF181C2A)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}