import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction_model.dart';
import '../services/database_service.dart';

class TransactionNotifier extends Notifier<List<TransactionModel>> {
  // Lista temporária na memória para simular o banco na Web e não travar
  static final List<TransactionModel> _webTransactionsDb = [];

  @override
  List<TransactionModel> build() {
    loadTransactions();
    return []; 
  }

  Future<void> loadTransactions() async {
    if (kIsWeb) {
      state = List.from(_webTransactionsDb);
      return;
    }
    
    final data = await DatabaseService.instance.fetchTransactions();
    state = data; 
  }

  // --- CORREÇÃO AQUI: Agora recebe o pacote completo (TransactionModel) ---
  Future<void> addTransaction(TransactionModel transaction) async {
    if (kIsWeb) {
      // Simulação para a Web
      final newTx = TransactionModel(
        id: _webTransactionsDb.length + 1,
        title: transaction.title,
        value: transaction.value,
        type: transaction.type,
        date: transaction.date,
      );
      _webTransactionsDb.add(newTx);
      state = [...state, newTx];
      return;
    }

    // Código real para o celular (SQLite)
    await DatabaseService.instance.insertTransaction(transaction);
    await loadTransactions(); 
  }

  Future<void> deleteTransaction(int id) async {
    if (kIsWeb) {
      _webTransactionsDb.removeWhere((tx) => tx.id == id);
      state = List.from(_webTransactionsDb);
      return;
    }

    await DatabaseService.instance.deleteTransaction(id);
    await loadTransactions();
  }

  // --- Cálculos Automáticos para o Dashboard ---
  
  double get totalIncome {
    return state.where((t) => t.type == TransactionType.income)
                .fold(0.0, (sum, item) => sum + item.value);
  }

  double get totalExpense {
    return state.where((t) => t.type == TransactionType.expense)
                .fold(0.0, (sum, item) => sum + item.value);
  }

  double get currentBalance => totalIncome - totalExpense;
}

// Provider global para acessar as transações em qualquer tela
final transactionProvider = NotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});