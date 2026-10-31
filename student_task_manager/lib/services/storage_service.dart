import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const _tasksKey = 'tasks';
  static const _membersKey = 'members';
  static const _themeKey = 'isDarkMode';

  // ── Tasks ──────────────────────────────────────────────
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tasksKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => Task.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _tasksKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  // ── Members ────────────────────────────────────────────
  Future<List<Map<String, String>>> loadMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_membersKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded
        .map<Map<String, String>>((e) => Map<String, String>.from(e))
        .toList();
  }

  Future<void> saveMembers(List<Map<String, String>> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_membersKey, jsonEncode(members));
  }

  // ── Theme ──────────────────────────────────────────────
  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; // default dark
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}
