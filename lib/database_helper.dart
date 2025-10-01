// database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // --- Table and Column Names ---
  static const String tableName = 'messages';
  static const String columnId = '_id';
  static const String columnGroupNumber = 'group_number';
  static const String columnSender = 'sender';
  static const String columnMessage = 'message';
  static const String columnTime = 'time'; // ISO 8601 string (Crucial for ordering/sync)
  static const String columnIsSynced = 'is_synced'; // 0 for pending, 1 for synced

  static const String groupTableName = 'user_groups';
  static const String groupColumnNumber = 'group_number';
  static const String groupColumnName = 'name';
  static const String groupColumnIsCreator = 'is_creator';

  static const String userTableName = 'user_profile';
  static const String userColumnUsername = 'username';
  static const String userColumnName = 'name';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('onechat_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Messages Table (for chat history)
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId $idType,
        $columnGroupNumber $textType,
        $columnSender $textType,
        $columnMessage $textType,
        $columnTime $textType,
        $columnIsSynced $intType,
        UNIQUE ($columnGroupNumber, $columnSender, $columnMessage, $columnTime) ON CONFLICT REPLACE
      )
    ''');

    // 2. User Groups Table (for offline group list)
    await db.execute('''
      CREATE TABLE $groupTableName (
        $groupColumnNumber TEXT PRIMARY KEY,
        $groupColumnName TEXT NOT NULL,
        $groupColumnIsCreator $intType
      )
    ''');

    // 3. User Profile Table (for offline profile info)
    await db.execute('''
      CREATE TABLE $userTableName (
        $userColumnUsername TEXT PRIMARY KEY,
        $userColumnName TEXT
      )
    ''');
  }

  // --- Profile CRUD Operations ---

  Future<void> saveProfile(String username, String name) async {
      final db = await instance.database;
      await db.insert(
          userTableName,
          {userColumnUsername: username, userColumnName: name},
          conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
      final db = await instance.database;
      final results = await db.query(userTableName, where: '$userColumnUsername = ?', whereArgs: [username]);
      return results.isNotEmpty ? results.first : null;
  }

  // --- Group Metadata CRUD Operations ---

  Future<void> saveGroups(List<Map<String, dynamic>> groups) async {
      final db = await instance.database;
      await db.transaction((txn) async {
          // Clear old groups first to ensure deleted/left groups are removed
          await txn.delete(groupTableName); 
          for (final group in groups) {
              await txn.insert(
                  groupTableName,
                  {
                      groupColumnNumber: group['number'],
                      groupColumnName: group['name'],
                      groupColumnIsCreator: group['is_creator'] ? 1 : 0,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace);
          }
      });
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
      final db = await instance.database;
      final results = await db.query(groupTableName);
      // Map integer (1/0) back to boolean
      return results.map((map) => {
          'number': map[groupColumnNumber],
          'name': map[groupColumnName],
          'is_creator': (map[groupColumnIsCreator] as int) == 1,
      }).toList();
  }
  
  Future<int> deleteGroupMetadata(String groupNumber) async {
      final db = await instance.database;
      return await db.delete(
        groupTableName,
        where: '$groupColumnNumber = ?',
        whereArgs: [groupNumber],
      );
  }


  // --- Message CRUD Operations ---

  // Insert a single message (used for local-first send/outbox)
  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    message.remove(columnId);
    return await db.insert(tableName, message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Bulk insert/update messages from the server
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> messages) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (final message in messages) {
        final mapToInsert = {
          columnGroupNumber: message[columnGroupNumber] ?? message['groupNumber'],
          columnSender: message[columnSender] ?? message['sender'],
          columnMessage: message[columnMessage] ?? message['message'],
          columnTime: message[columnTime] ?? message['time'],
          columnIsSynced: message[columnIsSynced] ?? 1, // Assume server data is synced (1)
        };
        mapToInsert.remove(columnId);
        
        await txn.insert(
          tableName,
          mapToInsert,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get all messages for a specific group, ordered by time
  Future<List<Map<String, dynamic>>> getMessages(String groupNumber) async {
    final db = await instance.database;
    return await db.query(
      tableName,
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
      orderBy: '$columnTime ASC', // Order chronologically
    );
  }

  // Delete all messages for a specific group (when leaving/deleting)
  Future<int> deleteGroupMessages(String groupNumber) async {
    final db = await instance.database;
    return await db.delete(
      tableName,
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
    );
  }
  
  // Get all pending messages for a specific group (for outbox sync)
  Future<List<Map<String, dynamic>>> getPendingMessages(String groupNumber) async {
    final db = await instance.database;
    return await db.query(
        tableName,
        where: '$columnGroupNumber = ? AND $columnIsSynced = ?',
        whereArgs: [groupNumber, 0],
        orderBy: '$columnTime ASC',
    );
  }
}
