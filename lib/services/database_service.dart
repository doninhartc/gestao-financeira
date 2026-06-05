import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  // Instância única para o padrão Singleton
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_control.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Executado na primeira vez que o banco de dados é criado no dispositivo
  Future _createDB(Database db, int version) async {
    // Tabela de Usuários para Autenticação
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Tabela de Transações Financeiras
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        value REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
  }

  // --- OPERAÇÕES DE USUÁRIO (CRUD & Autenticação) ---

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // --- OPERAÇÕES DE TRANSAÇÕES (CRUD completo) ---

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    final db = await instance.database;
    // Ordena por data decrescente (as mais recentes aparecem primeiro no feed)
    final result = await db.query('transactions', orderBy: 'date DESC');

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}