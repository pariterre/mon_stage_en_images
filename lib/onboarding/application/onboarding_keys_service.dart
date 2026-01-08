import 'package:flutter/cupertino.dart';

/// Source of truth for GlobalKeys used during the onboarding sequences.
/// It registers two types of keys : screenKeys ( GlobalKey`<State<StatefulWidget>>` ) and OnboardingTarget keys
/// ( non typed GlobalKey ), each inside
class OnboardingKeysService {
  /// Map for the OnboardingTarget keys. These keys links an OnboardingTarget with its OnboardingStep object
  final Map<String, GlobalKey> _keysMap = {};

  /// Map for the screenKeys, registered when generating a route (see main : onGeneratedRoute and onInitialGeneratedRoute)

  OnboardingKeysService._();

  static final OnboardingKeysService instance = OnboardingKeysService._();

  void addTarget(String id, GlobalKey key) {
    // Checking for duplicate
    if (_keysMap[id] != null && _keysMap[id] != key) {
      throw 'Global Key with id $id duplicate in OnBoardingKeyService';
    }
    _keysMap[id] = key;
  }

  void removeTarget(String id) {
    _keysMap.remove(id);
  }

  GlobalKey? findTargetKeyWithId(String id) => _keysMap[id];
}
