import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'selected_genre';

  Future<String> read() async => await _preferences.getString(key) ?? '전체';
  Future<void> save(String genre) => _preferences.setString(key, genre);
}
