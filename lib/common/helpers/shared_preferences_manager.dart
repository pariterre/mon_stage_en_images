import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager extends ChangeNotifier {
  // Singleton pattern
  SharedPreferencesManager._();
  static final SharedPreferencesManager _instance =
      SharedPreferencesManager._();
  static SharedPreferencesManager get instance => _instance;

  Future<void> initialize({
    SharedPreferencesOptions sharedPreferencesOptions =
        const SharedPreferencesOptions(),
    SharedPreferencesWithCacheOptions cacheOptions =
        const SharedPreferencesWithCacheOptions(allowList: null),
  }) async {
    if (isInitialized) {
      throw Exception('SharedPreferencesNotifier is already initialized.');
    }

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

  final String _hasSeenOnboardingKey = 'hasSeenOnboarding';
  bool get hasSeenOnboarding {
    _forceFailIfNotInitialized();
    return _prefs!.getBool(_hasSeenOnboardingKey) ?? false;
  }

  set hasSeenOnboarding(bool value) {
    _forceFailIfNotInitialized();
    _prefs!
        .setBool(_hasSeenOnboardingKey, value)
        .then((_) => notifyListeners());
  }

  final String _hasAlreadySeenTheIrrstPageKey = 'hasAlreadySeenTheIrrstPage';
  bool get hasAlreadySeenTheIrrstPage {
    _forceFailIfNotInitialized();
    return _prefs!.getBool(_hasAlreadySeenTheIrrstPageKey) ?? false;
  }

  set hasAlreadySeenTheIrrstPage(bool value) {
    _forceFailIfNotInitialized();
    _prefs!
        .setBool(_hasAlreadySeenTheIrrstPageKey, value)
        .then((_) => notifyListeners());
  }

  void _forceFailIfNotInitialized() {
    if (!isInitialized) {
      throw Exception(
          'SharedPreferencesNotifier is not initialized. Call initialize() first.');
    }
  }
}
