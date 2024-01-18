
import 'package:keep_clean/model/location.dart';
import 'package:keep_clean/model/task.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class CleaningDatabase {

  static final CleaningDatabase instance = CleaningDatabase._init();

  static Database? _database;
  CleaningDatabase._init();

  Future<Database> get database async{
    if(_database != null) return _database!;
    _database = await _initDB('Cleaning.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onConfigure: _onConfigure, onCreate: _createDB);
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const stringType = 'TEXT NOT NULL';
    const doneType = 'INT NOT NULL';
    const connectionIdType = 'INTEGER NOT NULL';
    const intType = 'INT NOT NULL';

    await db.execute('''
     CREATE TABLE $tableLocation (
     ${LocationFields.id} $idType,
     ${LocationFields.name} $stringType,
     ${LocationFields.iconName} $stringType
     )
    ''');

    await db.execute('''
     CREATE TABLE $tableTask (
     ${TaskFields.id} $idType,
     ${TaskFields.locationId} $intType,
     ${TaskFields.name} $stringType,
     ${TaskFields.nextDate} $stringType,
     ${TaskFields.cycle} $intType,
     FOREIGN KEY (${TaskFields.locationId}) REFERENCES location (${LocationFields.id}) ON DELETE CASCADE
     )
    ''');
  }

  Future insertLocation(Location location) async {
    final db = await instance.database;
    final id = await db.insert(tableLocation, location.toJson());
    location.copyWith(id: id);
  }

  Future<List<Location>> readAllLocations() async {
    final db = await instance.database;
    final result = await db.query(tableLocation);
    return result.map((json) => Location.fromJson(json)).toList();
  }

  Future<List<Task>> readTasksInLocation(int locationId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
          SELECT 
            $tableTask.${TaskFields.id},
            $tableTask.${TaskFields.locationId},
            $tableTask.${TaskFields.name},
            $tableTask.${TaskFields.nextDate},
            $tableTask.${TaskFields.cycle}
          FROM $tableTask
          JOIN $tableLocation ON $tableTask.${TaskFields.locationId} = $tableLocation.${LocationFields.id}
          WHERE $tableTask.${TaskFields.locationId} = ?
      ''', [locationId]);

    print(result);
    final List<Task> tasks = result.map((json) => Task.fromJson(json)).toList();
    //print(tasks);
    return tasks;
  }

  Future insertTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert(tableTask, task.toJson());
    task.copyWith(id: id);
  }

}