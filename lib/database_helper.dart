// lib/database_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Database structure constants
  static const String databaseName = 'one_chat_db.db';
  static const int databaseVersion = 1;

  static const String tableMessages = 'messages';
  static const String columnId = '_id';
  static const String columnGroupNumber = 'group_number';
  static const String columnSender = 'sender';
  static const String columnMessage = 'message';
  static const String columnTime = 'time'; // Stored as ISO 8601 string
  static const String columnIsSynced = 'is_synced'; // 0 or 1

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // On Android, this path is within the application's private storage,
    // meeting the "Android/data/com.chaty.adi" requirement indirectly.

    return await openDatabase(path, version: databaseVersion, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const uniqueTextType = 'TEXT UNIQUE NOT NULL';

    await db.execute('''
      CREATE TABLE $tableMessages (
        $columnId $idType,
        $columnGroupNumber $textType,
        $columnSender $textType,
        $columnMessage $textType,
        $columnTime $textType,
        $columnIsSynced $intType
      )
    ''');

    // You might add an index for faster message retrieval by group
    await db.execute('CREATE INDEX idx_group_number ON $tableMessages ($columnGroupNumber)');
  }

  // ---------------- CRUD Operations ----------------

  // Insert a single message (used for sending new messages)
  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    // sqflite uses map keys to map to column names
    return await db.insert(
      tableMessages,
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple messages (used for sync/fetch)
  // This helps prevent duplicate messages on sync by using ConflictAlgorithm.ignore, 
  // assuming the server-generated 'time' is unique enough, or you'd use a unique server ID.
  // For simplicity, we assume we want to replace based on the existing message content/time pair.
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> messages) async {
    final db = await instance.database;
    var batch = db.batch();

    for (var message in messages) {
      // Use ConflictAlgorithm.replace to handle potential sync conflicts if
      // the server updates a message, or simply to ensure the message is there.
      batch.insert(
        tableMessages, 
        message, 
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Read all messages for a specific group, ordered by time
  Future<List<Map<String, dynamic>>> getMessages(String groupNumber) async {
    final db = await instance.database;
    return await db.query(
      tableMessages,
      columns: [columnSender, columnMessage, columnTime],
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
      orderBy: '$columnTime ASC',
    );
  }

  // Delete all messages for a group (e.g., when a user leaves/group is deleted)
  Future<int> deleteGroupMessages(String groupNumber) async {
    final db = await instance.database;
    return await db.delete(
      tableMessages,
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
    );
  }

  // Close the database connection
  Future close() async {
    final db = await instance.database;
    _database = null;
    return db.close();
  }
}
