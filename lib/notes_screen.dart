import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  Database? _database;
  List<Map<String, dynamic>> _notes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    // Initialize the database factory for Desktop platforms (Linux, macOS, Windows)
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), 'notes_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY, title TEXT, content TEXT, is_hidden INTEGER)',
        );
      },
      version: 1,
    );
    await _seedDatabase();
    _refreshNotes();
  }

  Future<void> _seedDatabase() async {
    final db = _database;
    if (db == null) return;
    
    await db.delete('notes');
    await db.insert('notes', {
      'title': 'Travel Plans',
      'content': 'Trip to Paris in July.',
      'is_hidden': 0,
    });
    await db.insert('notes', {
      'title': 'Grocery List',
      'content': 'Milk, Eggs, Bread, Butter.',
      'is_hidden': 0,
    });
    await db.insert('notes', {
      'title': 'Admin Secret',
      'content': 'SuperSecretKey_9912',
      'is_hidden': 1,
    });
  }

  Future<void> _refreshNotes([String query = '']) async {
    final db = _database;
    if (db == null) return;

    List<Map<String, dynamic>> notes;
    if (query.isEmpty) {
      notes = await db.query('notes', where: 'is_hidden = 0');
    } else {
      notes = await db.rawQuery(
        "SELECT * FROM notes WHERE is_hidden = 0 AND title LIKE '%$query%'"
      );
    }
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => _refreshNotes(value),
              decoration: InputDecoration(
                labelText: 'Search Notes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    color: const Color(0xFF1B263B),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        note['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        note['content'],
                        style: const TextStyle(color: Color(0xFF778DA9)),
                      ),
                      trailing: note['is_hidden'] == 1
                          ? const Icon(Icons.security, color: Colors.redAccent)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
