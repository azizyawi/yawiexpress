import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  return {
    "firstName": prefs.getString('firstName') ?? '',
    "lastName": prefs.getString('lastName') ?? '',
  };
});
