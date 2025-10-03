// -------------------- DATABASE HELPER (SQLITE) --------------------

// NOTE: This class is assumed to be in a separate file (database_helper.dart)
// but included here for completeness of the overall application logic.
 import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "OneChatDB.db";
  // Increment the version if you change the database schema
  static final _databaseVersion = 3; 

  // Tables
  static final tableName = 'messages';
  static final groupTableName = 'groups_meta';
  static final profileTableName = 'profile';
  static final lastReadTableName = 'last_read';

  // Columns for messages table
  static final columnId = '_id';
  static final columnGroupNumber = 'group_number';
  static final columnSender = 'sender';
  static final columnMessage = 'message';
  static final columnTime = 'time';
  static final columnIsSynced = 'is_synced';

  // Columns for groups_meta table
  static final columnGroupName = 'group_name';
  static final columnGroupNumberMeta = 'group_number'; // Unique ID for group
  static final columnIsCreator = 'is_creator';

  // Columns for profile table
  static final columnUsername = 'username';
  static final columnProfileName = 'name';

  // Columns for last_read table
  static final columnLastReadGroupNumber = 'group_number';
  static final columnLastReadTime = 'last_read_time';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnGroupNumber TEXT NOT NULL,
        $columnSender TEXT NOT NULL,
        $columnMessage TEXT NOT NULL,
        $columnTime TEXT NOT NULL,
        $columnIsSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Group metadata table
    await db.execute('''
      CREATE TABLE $groupTableName (
        $columnGroupNumberMeta TEXT PRIMARY KEY,
        $columnGroupName TEXT NOT NULL,
        $columnIsCreator INTEGER NOT NULL
      )
    ''');
    
    // Profile table
    await db.execute('''
      CREATE TABLE $profileTableName (
        $columnUsername TEXT PRIMARY KEY,
        $columnProfileName TEXT
      )
    ''');

    // Last Read Time table
    await db.execute('''
      CREATE TABLE $lastReadTableName (
        $columnLastReadGroupNumber TEXT PRIMARY KEY,
        $columnLastReadTime TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Simple way to handle upgrades: drop and recreate (only for non-production/testing)
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS $tableName');
      await db.execute('DROP TABLE IF EXISTS $groupTableName');
      await db.execute('DROP TABLE IF EXISTS $profileTableName');
      await db.execute('DROP TABLE IF EXISTS $lastReadTableName');
      await _onCreate(db, newVersion);
    }
  }

  // --- Profile Operations ---
  Future<int> saveProfile(String username, String name) async {
    Database db = await instance.database;
    return await db.insert(
      profileTableName, 
      {columnUsername: username, columnProfileName: name}, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      profileTableName,
      where: '$columnUsername = ?',
      whereArgs: [username]
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // --- Group Operations ---
  Future<void> saveGroups(List<Map<String, dynamic>> serverGroups) async {
    Database db = await instance.database;
    
    // 1. Get current local group numbers
    List<Map<String, dynamic>> localGroups = await db.query(groupTableName, columns: [columnGroupNumberMeta]);
    Set<String> localGroupNumbers = localGroups.map((g) => g[columnGroupNumberMeta] as String).toSet();

    // 2. Get server group numbers
    Set<String> serverGroupNumbers = serverGroups.map((g) => g['number'] as String).toSet();

    // 3. Delete local groups that are NOT in the server list (i.e., deleted or left groups)
    Set<String> groupsToDelete = localGroupNumbers.difference(serverGroupNumbers);
    for (String groupNumber in groupsToDelete) {
        await deleteGroupMetadata(groupNumber);
        await deleteGroupMessages(groupNumber);
        await deleteLastReadTime(groupNumber);
    }

    // 4. Insert/Update remaining groups from the server list
    Batch batch = db.batch();
    for (var group in serverGroups) {
      batch.insert(
        groupTableName,
        {
          columnGroupNumberMeta: group['number'],
          columnGroupName: group['name'],
          columnIsCreator: group['is_creator'] ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(groupTableName);
    return maps.map((map) => {
      'number': map[columnGroupNumberMeta],
      'name': map[columnGroupName],
      'is_creator': map[columnIsCreator] == 1,
    }).toList();
  }

  Future<void> deleteGroupMetadata(String groupNumber) async {
      Database db = await instance.database;
      await db.delete(
          groupTableName,
          where: '$columnGroupNumberMeta = ?',
          whereArgs: [groupNumber]
      );
  }

  // --- Message Operations ---
  Future<int> insertMessage(Map<String, dynamic> message) async {
    Database db = await instance.database;
    return await db.insert(tableName, message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> bulkInsertMessages(List<Map<String, dynamic>> messages) async {
      Database db = await instance.database;
      Batch batch = db.batch();
      for (var message in messages) {
          batch.insert(tableName, message, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMessages(String groupNumber) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
      orderBy: '$columnTime ASC, $columnId ASC', // Sort by time, then local ID for stability
    );
    return maps;
  }
  
  Future<String?> getLatestMessageTime(String groupNumber) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [columnTime],
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
      orderBy: '$columnTime DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first[columnTime] : null;
  }

  Future<List<Map<String, dynamic>>> getPendingMessages(String groupNumber) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnGroupNumber = ? AND $columnIsSynced = 0',
      whereArgs: [groupNumber],
      orderBy: '$columnId ASC',
    );
    return maps;
  }

  Future<void> deleteGroupMessages(String groupNumber) async {
    Database db = await instance.database;
    await db.delete(
      tableName,
      where: '$columnGroupNumber = ?',
      whereArgs: [groupNumber],
    );
  }
  
  // --- Last Read Operations (for Unread Count) ---
  Future<void> setLastReadTime(String groupNumber, DateTime time) async {
      Database db = await instance.database;
      await db.insert(
          lastReadTableName,
          {
              columnLastReadGroupNumber: groupNumber,
              columnLastReadTime: time.toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace
      );
  }

  Future<DateTime?> getLastReadTime(String groupNumber) async {
      Database db = await instance.database;
      List<Map<String, dynamic>> maps = await db.query(
          lastReadTableName,
          columns: [columnLastReadTime],
          where: '$columnLastReadGroupNumber = ?',
          whereArgs: [groupNumber]
      );
      if (maps.isNotEmpty && maps.first[columnLastReadTime] != null) {
          try {
              return DateTime.parse(maps.first[columnLastReadTime] as String);
          } catch (e) {
              return null;
          }
      }
      return null;
  }

  Future<void> deleteLastReadTime(String groupNumber) async {
      Database db = await instance.database;
      await db.delete(
          lastReadTableName,
          where: '$columnLastReadGroupNumber = ?',
          whereArgs: [groupNumber]
      );
  }

  Future<int> getUnreadCount(String groupNumber, DateTime? lastReadTime) async {
      Database db = await instance.database;
      if (lastReadTime == null) {
          // If never read, count all messages
          return Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM $tableName WHERE $columnGroupNumber = ?', 
              [groupNumber]
          )) ?? 0;
      }

      // Count messages newer than the last read time (must be synced messages)
      final lastReadTimeISO = lastReadTime.toUtc().toIso8601String();
      return Sqflite.firstIntValue(await db.rawQuery(
          // Note: Check is_synced=1 is important, as local messages should not affect the unread count calculation on MainPage
          'SELECT COUNT(*) FROM $tableName WHERE $columnGroupNumber = ? AND $columnTime > ? AND $columnIsSynced = 1',
          [groupNumber, lastReadTimeISO]
      )) ?? 0;
  }
}

