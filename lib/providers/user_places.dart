import 'package:favorite_places/models/place.dart';
import 'package:riverpod/riverpod.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'dart:io';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'places.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_places(id TEXT PRIMARY KEY,title TEXT, image TEXT, lat REAL, lng REAL,address TEXT)');
    },
    version: 1,
  ); //oncreate function will be executed for once the database created
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);
  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places');
    final places = data.map((row) {
      return Place(
          id: row['id'].toString(),
          title: row['title'].toString(),
          image: File(row['image'].toString()),
          location: PlaceLocation(
              latitude: row['lat'] as double,
              longitude: row['lng'] as double,
              address: row['address'].toString()));
    }).toList();
    state = places;
  }

  void addPlace(Place place) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final filename = path.basename(place.image.path); //to get the file name
    final copiedImage = await place.image.copy('${appDir.path}/$filename');
    final newPlace =
        Place(title: place.title, image: copiedImage, location: place.location);
    final db = await _getDatabase();
    db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': newPlace.image.path,
      'lat': newPlace.location.latitude,
      'lng': newPlace.location.longitude,
      'address': newPlace.location.address
    });
    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
        (ref) => UserPlacesNotifier());
