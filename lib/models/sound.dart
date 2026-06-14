class Sound {
  final String id;
  final String name;
  final String description;
  final String filePath;
  final Duration duration;
  final bool isPremium;
  final bool isDownloaded;
  final String category; // rain, sea, wind, forest, thunderstorm, train, waterfall, coffee, etc.
  final String imageAsset;
  final double volume;

  Sound({
    required this.id,
    required this.name,
    required this.description,
    required this.filePath,
    required this.duration,
    this.isPremium = false,
    this.isDownloaded = false,
    required this.category,
    required this.imageAsset,
    this.volume = 1.0,
  });

  Sound copyWith({
    String? id,
    String? name,
    String? description,
    String? filePath,
    Duration? duration,
    bool? isPremium,
    bool? isDownloaded,
    String? category,
    String? imageAsset,
    double? volume,
  }) {
    return Sound(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      isPremium: isPremium ?? this.isPremium,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      volume: volume ?? this.volume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sound &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
