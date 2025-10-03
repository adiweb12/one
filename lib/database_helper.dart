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
  
  // 🌟 NEW: Table for tracking group status (e.g., last read time)
  static const String statusTableName = 'group_status';
  static const String statusColumnGroupNumber = 'group_number';
  static const String statusColumnLastReadTime = 'last_read_time'; // ISO 8601 string


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('onechat_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Use an onUpgrade function to handle existing databases from older versions
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }
  
  // 🌟 NEW: Database migration for version 2
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
        // Create the new group_status table if upgrading from a version that didn't have it
        await _createGroupStatusTable(db);
    }
  }

  Future _createGroupStatusTable(Database db) async {
    const textType = 'TEXT NOT NULL';
    await db.execute('''
      CREATE TABLE $statusTableName (
        $statusColumnGroupNumber $textType PRIMARY KEY,
        $statusColumnLastReadTime $textType 
      )
    ''');
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
    
    // 🌟 NEW: 4. Group Status Table
    await _createGroupStatusTable(db);
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
  
  // 🌟 FIX: Ensure group status is also deleted
  Future<int> deleteGroupMetadata(String groupNumber) async {
      final db = await instance.database;
      // Also delete group status when deleting group metadata
      await db.delete(statusTableName, where: '$statusColumnGroupNumber = ?', whereArgs: [groupNumber]); 
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
  
  // 🌟 NEW: Get only the latest message time for a group
  Future<String?> getLatestMessageTime(String groupNumber) async {
      final db = await instance.database;
      final results = await db.query(
          tableName,
          columns: [columnTime],
          where: '$columnGroupNumber = ?',
          whereArgs: [groupNumber],
          orderBy: '$columnTime DESC',
          limit: 1,
      );
      return results.isNotEmpty ? results.first[columnTime] as String : null;
  }
  
  // 🌟 NEW: Get count of unread messages for a group
  Future<int> getUnreadCount(String groupNumber, String? lastReadTime) async {
      final db = await instance.database;
      
      if (lastReadTime == null) {
          // If no read time is set, all messages are unread
          final count = await db.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $columnGroupNumber = ?', 
              [groupNumber]
          );
          return Sqflite.firstIntValue(count) ?? 0;
      }
      
      // Find the count of messages with a time strictly GREATER than the last read time
      final count = await db.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $columnGroupNumber = ? AND $columnTime > ?',
          [groupNumber, lastReadTime]
      );
      return Sqflite.firstIntValue(count) ?? 0;
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
  
  // --- Group Status (Last Read Time) CRUD Operations ---
  
  Future<void> setLastReadTime(String groupNumber, DateTime time) async {
      final db = await instance.database;
      await db.insert(
          statusTableName,
          {
              statusColumnGroupNumber: groupNumber,
              statusColumnLastReadTime: time.toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<String?> getLastReadTime(String groupNumber) async {
      final db = await instance.database;
      final results = await db.query(
          statusTableName, 
          columns: [statusColumnLastReadTime],
          where: '$statusColumnGroupNumber = ?', 
          whereArgs: [groupNumber]
      );
      return results.isNotEmpty ? results.first[statusColumnLastReadTime] as String? : null;
  }
}
