import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static const _userNameKey = 'user_name';
  String _name = 'User';

  String get name => _name;

  UserProvider() {
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_userNameKey) ?? 'User';
    notifyListeners();
  }

  Future<void> setName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedName = newName.trim();
    
    if (trimmedName.isEmpty) {
      _name = 'User';
    } else {
      _name = trimmedName;
    }
    
    await prefs.setString(_userNameKey, _name);
    notifyListeners();
  }
}
