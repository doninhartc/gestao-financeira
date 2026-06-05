import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../viewmodels/transaction_provider.dart';

class TransactionForm extends ConsumerStatefulWidget {
  // ADICIONADO: Variável opcional para receber a transação que será editada
  final TransactionModel? transactionToEdit;
  
  const TransactionForm({super.key, this.transactionToEdit});

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;

  // ADICIONADO: Preenche os campos automaticamente se for uma edição
  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _titleController.text = widget.transactionToEdit!.title;
      _valueController.text = widget.transactionToEdit!.value.toStringAsFixed(2);
      _selectedType = widget.transactionToEdit!.type;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final value = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;

      // ADICIONADO: Verifica se estamos editando ou criando uma nova
      if (widget.transactionToEdit != null) {
        // Atualiza mantendo o ID e a Data originais
        final updatedTransaction = TransactionModel(
          id: widget.transactionToEdit!.id,
          title: title,
          value: value,
          date: widget.transactionToEdit!.date,
          type: _selectedType,
        );
        ref.read(transactionProvider.notifier).updateTransaction(updatedTransaction);
      } else {
        // Cria uma nova
        final newTransaction = TransactionModel(
          title: title,
          value: value,
          date: DateTime.now(),
          type: _selectedType,
        );
        ref.read(transactionProvider.notifier).addTransaction(newTransaction);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Altera os textos dependendo se é criação ou edição
    final isEditing = widget.transactionToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24, bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Editar Transação' : 'Nova Transação',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Título (ex: Mercado, Salário)',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.description, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe o valor';
                if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = TransactionType.income),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == TransactionType.income ? Colors.greenAccent.withOpacity(0.2) : const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == TransactionType.income ? Colors.greenAccent : Colors.transparent,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Receita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = TransactionType.expense),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == TransactionType.expense ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == TransactionType.expense ? Colors.redAccent : Colors.transparent,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Despesa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'ADICIONAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}