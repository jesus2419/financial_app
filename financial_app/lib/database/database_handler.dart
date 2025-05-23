// lib/database/database_handler.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/usuario.dart';

class DatabaseHandler {
  static const _databaseName = "DB_super";
  static const _databaseVersion = 1;
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

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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
}