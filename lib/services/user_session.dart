import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserSession {
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _currentListIdKey = 'current_list_id';
  static const _currentListNameKey = 'current_list_name';
  static const _currentListInviteCodeKey = 'current_list_invite_code';

  final _uuid = const Uuid();

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await prefs.setString(_userIdKey, newId);
    return newId;
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name.trim());
  }

  Future<void> clearUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
  }

  Future<String?> getCurrentListId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentListIdKey);
  }

  Future<String?> getCurrentListName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentListNameKey);
  }

  Future<String?> getCurrentListInviteCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentListInviteCodeKey);
  }

  Future<void> saveCurrentList({
    required String listId,
    required String listName,
    required String inviteCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentListIdKey, listId);
    await prefs.setString(_currentListNameKey, listName);
    await prefs.setString(_currentListInviteCodeKey, inviteCode);
  }

  Future<void> clearCurrentList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentListIdKey);
    await prefs.remove(_currentListNameKey);
    await prefs.remove(_currentListInviteCodeKey);
  }
}