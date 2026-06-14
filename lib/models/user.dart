class User {
  final String id;
  final bool isPremium;
  final DateTime premiumExpiryDate;
  final List<String> downloadedSoundIds;
  final int totalListeningMinutes;
  final DateTime lastListenedDate;
  final bool isFirstLaunch;
  final bool isLoggedIn;
  final String? email;
  final String? displayName;

  User({
    required this.id,
    this.isPremium = false,
    required this.premiumExpiryDate,
    this.downloadedSoundIds = const [],
    this.totalListeningMinutes = 0,
    required this.lastListenedDate,
    this.isFirstLaunch = true,
    this.isLoggedIn = false,
    this.email,
    this.displayName,
  });

  User copyWith({
    String? id,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    List<String>? downloadedSoundIds,
    int? totalListeningMinutes,
    DateTime? lastListenedDate,
    bool? isFirstLaunch,
    bool? isLoggedIn,
    String? email,
    String? displayName,
  }) {
    return User(
      id: id ?? this.id,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      downloadedSoundIds: downloadedSoundIds ?? this.downloadedSoundIds,
      totalListeningMinutes: totalListeningMinutes ?? this.totalListeningMinutes,
      lastListenedDate: lastListenedDate ?? this.lastListenedDate,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
