import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _userIdKey = 'user_id';

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      // Parse user from stored JSON
      final Map<String, dynamic> userMap = Map<String, dynamic>.from(
        (userJson.split(',').asMap().map((i, val) => MapEntry(i.toString(), val))),
      );
      
      // Try to get from login response format
      final storedData = prefs.getString(_userKey);
      if (storedData != null) {
        // Simple storage: userId|name|email|role
        final parts = storedData.split('|');
        if (parts.length == 4) {
          return User(
            userId: int.parse(parts[0]),
            name: parts[1],
            email: parts[2],
            role: parts[3],
          );
        }
      }
    }
    
    return null;
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    // Simple storage format: userId|name|email|role
    await prefs.setString(_userKey, '${user.userId}|${user.name}|${user.email}|${user.role}');
    await prefs.setInt(_userIdKey, user.userId);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
  }

  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<User> login(String email, String password) async {
    final response = await ApiService.login(email: email, password: password);
    final userData = response['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);
    await saveUser(user);
    return user;
  }

  static Future<User> register(String name, String email, String password, {String role = 'user'}) async {
    final response = await ApiService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    
    // After registration, login automatically
    return login(email, password);
  }
}
