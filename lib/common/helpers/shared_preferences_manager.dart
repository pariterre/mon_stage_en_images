import 'package:flutter/widgets.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesController extends ChangeNotifier {
  // Singleton pattern
  SharedPreferencesController._();
  static final SharedPreferencesController _instance =
      SharedPreferencesController._();
  static SharedPreferencesController get instance => _instance;

  Future<void> initialize({
    SharedPreferencesOptions sharedPreferencesOptions =
        const SharedPreferencesOptions(),
    SharedPreferencesWithCacheOptions cacheOptions =
        const SharedPreferencesWithCacheOptions(allowList: null),
  }) async {
    if (isInitialized) {
      throw Exception('SharedPreferencesNotifier is already initialized.');
    }

    WidgetsFlutterBinding.ensureInitialized();

    _prefs = await SharedPreferencesWithCache.create(
        sharedPreferencesOptions: sharedPreferencesOptions,
        cacheOptions: cacheOptions);
  }

  SharedPreferencesWithCache? _prefs;
  bool get isInitialized => _prefs != null;

  final String _showValidationWarningKey = 'showValidationWarning';
  bool get showValidationWarning {
    _forceFailIfNotInitialized();
    return _prefs!.getBool(_showValidationWarningKey) ?? true;
  }

  set showValidationWarning(bool value) {
    _forceFailIfNotInitialized();
    _prefs!
        .setBool(_showValidationWarningKey, value)
        .then((_) => notifyListeners());
  }

  final String _userTypeKey = 'userType';
  UserType get userType {
    _forceFailIfNotInitialized();
    return UserType.deserialize(_prefs!.getString(_userTypeKey));
  }

  set userType(UserType userType) {
    _forceFailIfNotInitialized();
    _prefs!
        .setString(_userTypeKey, userType.serialize())
        .then((_) => notifyListeners());
  }

  final String _showPermissionRefusedKey = 'showPermissionRefused';
  bool get showPermissionRefused {
    _forceFailIfNotInitialized();
    return _prefs!.getBool(_showPermissionRefusedKey) ?? true;
  }

  set showPermissionRefused(bool value) {
    _forceFailIfNotInitialized();
    _prefs!
        .setBool(_showPermissionRefusedKey, value)
        .then((_) => notifyListeners());
  }

  void _forceFailIfNotInitialized() {
    if (!isInitialized) {
      throw Exception(
          'SharedPreferencesNotifier is not initialized. Call initialize() first.');
    }
  }
}
