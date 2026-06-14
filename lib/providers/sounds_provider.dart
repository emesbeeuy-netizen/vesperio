import 'dart:collection';

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';

class SoundsProvider extends ChangeNotifier {
  final List<Sound> _allSounds = [];
  final List<Sound> _freeSounds = [];
  final List<Sound> _premiumSounds = [];
  final List<Sound> _filteredSounds = [];
  late final UnmodifiableListView<Sound> _allSoundsView = UnmodifiableListView(_allSounds);
  late final UnmodifiableListView<Sound> _freeSoundsView = UnmodifiableListView(_freeSounds);
  late final UnmodifiableListView<Sound> _premiumSoundsView = UnmodifiableListView(_premiumSounds);
  late final UnmodifiableListView<Sound> _filteredSoundsView = UnmodifiableListView(_filteredSounds);
  String _selectedCategory = 'all';
  String _selectedSort = 'name'; // name, duration, recent
  String _searchQuery = '';

  List<Sound> get allSounds => _allSoundsView;
  List<Sound> get freeSounds => _freeSoundsView;
  List<Sound> get premiumSounds => _premiumSoundsView;
  List<Sound> get filteredSounds => _filteredSoundsView;
  String get selectedCategory => _selectedCategory;
  String get selectedSort => _selectedSort;
  String get searchQuery => _searchQuery;

  SoundsProvider() {
    _initializeSounds();
  }

  void _initializeSounds() {
    // Create free sounds
    // Development helper: set to `true` to play a network fallback sample
    // instead of local assets when assets are not yet added to the repo.
    // Use local asset paths for sounds. If you want to test network fallbacks,
    // replace the returned `filePath` with a remote URL.
    _freeSounds.addAll(SoundData.basicSounds.map((data) {
      return Sound(
        id: data['id']!,
        name: data['name']!,
        description: data['description']!,
        filePath: 'assets/sounds/free/${data['id']}.m4a',
        duration: const Duration(hours: 8),
        isPremium: false,
        category: data['category']!,
        imageAsset: 'assets/images/${data['id']}.png',
        volume: 1.0,
      );
    }));

    // If assets are missing at runtime, developers can switch to using the fallback URL.

    // Create premium sounds
    _premiumSounds.addAll(SoundData.premiumSounds.map((data) {
      return Sound(
        id: data['id']!,
        name: data['name']!,
        description: data['description']!,
        filePath: 'assets/sounds/premium/${data['id']}.m4a',
        duration: const Duration(hours: 8),
        isPremium: true,
        category: data['category']!,
        imageAsset: 'assets/images/${data['id']}.png',
        volume: 1.0,
      );
    }));

    // Developer helper: when running locally without assets, you can replace
    // each sound's filePath with `fallbackUrl` to test playback from network.

    _allSounds
      ..clear()
      ..addAll(_freeSounds)
      ..addAll(_premiumSounds);
    _sortSounds();
    _applyFilters();
  }

  void _applyFilters() {
    Iterable<Sound> base = _selectedCategory == 'all'
        ? _allSounds
        : _allSounds.where((s) => s.category == _selectedCategory);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q));
    }

    _filteredSounds
      ..clear()
      ..addAll(base);
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    _sortSounds();
    _applyFilters();
    notifyListeners();
  }

  void _sortSounds() {
    switch (_selectedSort) {
      case 'name':
        _allSounds.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'duration':
        _allSounds.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'recent':
        // This would require tracking user data
        break;
    }
  }

  Sound? getSoundById(String id) {
    try {
      return _allSounds.firstWhere((sound) => sound.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getCategories() {
    final categories = <String>{'all'};
    for (final sound in _allSounds) {
      categories.add(sound.category);
    }
    return categories.toList();
  }

  List<Sound> searchSounds(String query) {
    if (query.isEmpty) return _filteredSounds;
    final lowerQuery = query.toLowerCase();
    return _filteredSounds
        .where((sound) =>
            sound.name.toLowerCase().contains(lowerQuery) ||
            sound.description.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
