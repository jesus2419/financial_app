// lib/database/database_handler.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/usuario.dart';
import '../model/account.dart';
import '../model/category.dart';
import '../model/transaction.dart' as tx;
import '../model/transfer.dart';
import '../model/mandatory_payment.dart';
import '../model/mandatory_payment_log.dart';
import '../model/savings_goal.dart';

class DatabaseHandler {
  static const _databaseName = "DB_super";
  static const _databaseVersion = 2;
  static const tableName = "Users2";

  // Columnas
  static const colId = 'id';
  static const colNombre = 'nombre';
  static const colApellidoP = 'apellido_p';
  static const colApellidoM = 'apellido_m';
  static const colEmail = 'email';
  static const colPass = 'pass';

  // Singleton
  DatabaseHandler._privateConstructor();
  static final DatabaseHandler instance = DatabaseHandler._privateConstructor();

  static Database? databaseInstance; // <-- Cambia el nombre a databaseInstance
  Future<Database> get database async {
    if (databaseInstance != null) return databaseInstance!;
    databaseInstance = await _initDatabase();
    return databaseInstance!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE $tableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colNombre TEXT NOT NULL,
        $colApellidoP TEXT NOT NULL,
        $colApellidoM TEXT NOT NULL,
        $colEmail TEXT UNIQUE NOT NULL,
        $colPass TEXT NOT NULL
      )
    ''');

    // Tabla accounts
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('cash', 'debit', 'credit')),
        bank_name TEXT,
        credit_limit REAL,
        cut_off_day INTEGER,
        description TEXT
      )
    ''');

    // Tabla categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        icon TEXT,
        color TEXT
      )
    ''');

    // Tabla transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER,
        description TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Tabla transfers
    await db.execute('''
      CREATE TABLE transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_account_id INTEGER NOT NULL,
        to_account_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (from_account_id) REFERENCES accounts(id),
        FOREIGN KEY (to_account_id) REFERENCES accounts(id)
      )
    ''');

    // Tabla mandatory_payments
    await db.execute('''
      CREATE TABLE mandatory_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        due_date TEXT NOT NULL,
        frequency TEXT CHECK(frequency IN ('once', 'weekly', 'biweekly', 'monthly')) DEFAULT 'once',
        category_id INTEGER,
        notes TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Tabla mandatory_payment_logs
    await db.execute('''
      CREATE TABLE mandatory_payment_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mandatory_payment_id INTEGER NOT NULL,
        transaction_id INTEGER,
        paid_amount REAL NOT NULL,
        paid_date TEXT NOT NULL,
        FOREIGN KEY (mandatory_payment_id) REFERENCES mandatory_payments(id),
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    // Tabla savings_goals (metas de ahorro)
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline TEXT,
        description TEXT,
        icon TEXT,
        color TEXT
      )
    ''');
  }

  // Insertar usuario
  Future<int> addUser(Usuario usuario) async {
    Database db = await instance.database;
    return await db.insert(tableName, usuario.toMap());
  }

  // Obtener usuario por ID
  Future<Usuario?> getUser(int id) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(
      tableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  // Obtener todos los usuarios
  Future<List<Usuario>> getAllUsers() async {
    Database db = await instance.database;
    List<Map> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Usuario.fromMap(maps[i] as Map<String, dynamic>);
    });
  }

  // Actualizar usuario
  Future<int> updateUser(Usuario user) async {
    Database db = await instance.database;
    return await db.update(
      tableName,
      user.toMap(),
      where: '$colId = ?',
      whereArgs: [user.id],
    );
  }

  // Eliminar usuario
  Future<int> deleteUser(Usuario user) async {
    Database db = await instance.database;
    return await db.delete(
      tableName,
      where: '$colId = ?',
      whereArgs: [user.id],
    );
  }

  // Verificar credenciales
  Future<Usuario?> checkUser(String email, String pass) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(
      tableName,
      where: '$colEmail = ? AND $colPass = ?',
      whereArgs: [email, pass],
    );
    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  // Verificar si email existe
  Future<bool> isEmailExists(String email) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(
      tableName,
      where: '$colEmail = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  // =========================
  // Métodos para Accounts
  // =========================
  Future<int> addAccount(Account account) async {
    Database db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    Database db = await instance.database;
    final maps = await db.query('accounts');
    return maps.map((e) => Account.fromMap(e)).toList();
  }

  Future<int> updateAccount(Account account) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    Database db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // Métodos para Categories
  // =========================
  Future<int> addCategory(Category category) async {
    Database db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    Database db = await instance.database;
    final maps = await db.query('categories');
    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> updateCategory(Category category) async {
    Database db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // Métodos para Transactions
  // =========================
  Future<int> addTransaction(tx.Transaction transaction) async {
    Database db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<tx.Transaction>> getAllTransactions() async {
    Database db = await instance.database;
    final maps = await db.query('transactions');
    return maps.map((e) => tx.Transaction.fromMap(e)).toList();
  }

  Future<int> updateTransaction(tx.Transaction transaction) async {
    Database db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // Métodos para Transfers
  // =========================
  Future<int> addTransfer(Transfer transfer) async {
    Database db = await instance.database;
    return await db.insert('transfers', transfer.toMap());
  }

  Future<List<Transfer>> getAllTransfers() async {
    Database db = await instance.database;
    final maps = await db.query('transfers');
    return maps.map((e) => Transfer.fromMap(e)).toList();
  }

  // =========================
  // Métodos para MandatoryPayments
  // =========================
  Future<int> addMandatoryPayment(MandatoryPayment mp) async {
    Database db = await instance.database;
    return await db.insert('mandatory_payments', mp.toMap());
  }

  Future<List<MandatoryPayment>> getAllMandatoryPayments() async {
    Database db = await instance.database;
    final maps = await db.query('mandatory_payments');
    return maps.map((e) => MandatoryPayment.fromMap(e)).toList();
  }

  // =========================
  // Métodos para MandatoryPaymentLogs
  // =========================
  Future<int> addMandatoryPaymentLog(MandatoryPaymentLog mpl) async {
    Database db = await instance.database;
    return await db.insert('mandatory_payment_logs', mpl.toMap());
  }

  Future<List<MandatoryPaymentLog>> getAllMandatoryPaymentLogs() async {
    Database db = await instance.database;
    final maps = await db.query('mandatory_payment_logs');
    return maps.map((e) => MandatoryPaymentLog.fromMap(e)).toList();
  }

  // =========================
  // Métodos para SavingsGoals
  // =========================
  Future<int> addSavingsGoal(SavingsGoal goal) async {
    Database db = await instance.database;
    return await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoal>> getAllSavingsGoals() async {
    Database db = await instance.database;
    final maps = await db.query('savings_goals');
    return maps.map((e) => SavingsGoal.fromMap(e)).toList();
  }

  Future<int> updateSavingsGoal(SavingsGoal goal) async {
    Database db = await instance.database;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingsGoal(int id) async {
    Database db = await instance.database;
    return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
