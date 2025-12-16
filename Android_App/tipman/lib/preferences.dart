import 'package:shared_preferences/shared_preferences.dart';


enum Settings {
  selectedHeading('selectedHeading'),
  selectedSubHeading('selectedSubHeading'),
  location('location'),
  imageDitherThreshold('imageDitherThreshold'),
  generateQRCode('generateQRCode'),
  addTimeStamp('addTimeStamp'),
  saveImagesWhenPrinting('saveImagesWhenPrinting'),
  saveDitheredImagesWhenPrinting('saveDitheredImagesWhenPrinting'),
  customAlignment('customAlignment'),
  customUnderline('customUnderline'),
  customInverse('customInverse'),
  customUpsideDown('customUpsideDown');
  
  const Settings(this.id);
  final String id;
}

class Preferences
{
  static Future<bool> saveBool(Settings key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key.id, value);
  }
  static Future<bool> saveDouble(Settings key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(key.id, value);
  }
  static Future<bool> saveInt(Settings key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key.id, value);
  }
  static Future<bool> saveString(Settings key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key.id, value);
  }
  static Future<bool> saveStringList(Settings key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key.id, value);
  }


  static Future<bool?> getBool(Settings key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key.id);
  }
  static Future<double?> getDouble(Settings key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key.id);
  }
  static Future<int?> getInt(Settings key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key.id);
  }
  static Future<String?> getString(Settings key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key.id);
  }
  static Future<List<String>?> getStringList(Settings key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key.id);
  }
}