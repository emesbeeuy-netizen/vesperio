import 'package:flutter/material.dart';

// Duration extensions
extension DurationExtensions on Duration {
  String toFormattedString() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours == 0) {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  String toSimpleString() {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m';
    } else {
      return '${inSeconds}s';
    }
  }
}

// String extensions
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// List extensions
extension ListExtensions<T> on List<T> {
  List<T> removeItem(T item) {
    final list = List<T>.from(this);
    list.remove(item);
    return list;
  }

  List<T> addItemIfNotExists(T item) {
    final list = List<T>.from(this);
    if (!list.contains(item)) {
      list.add(item);
    }
    return list;
  }
}

// BuildContext extensions

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  bool get isDarkMode =>
      MediaQuery.of(this).platformBrightness == Brightness.dark;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < 600;

  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  bool get isDesktop => screenWidth >= 1200;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
}
