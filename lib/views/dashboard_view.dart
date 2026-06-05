import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
  return response.data['articles'];
});

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  bool _isFetchingData = true;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _simulateNetworkLoad();
  }

  Future<void> _simulateNetworkLoad() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isFetchingData = false);
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
        child: SingleChildScrollView(
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
              
              SizedBox(
                height: 140,
                child: newsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => const Padding(padding: EdgeInsets.all(24), child: Text("Erro ao carregar", style: TextStyle(color: Colors.red))),
                  data: (news) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: news.length,
                    itemBuilder: (context, index) => Container(
                      width: 200, margin: const EdgeInsets.only(left: 24), padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF23283B), borderRadius: BorderRadius.circular(16)),
                      child: Text(news[index]['title'], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 4, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text("Transações Recentes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              _isFetchingData
                  ? const SkeletonLoader()
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
}