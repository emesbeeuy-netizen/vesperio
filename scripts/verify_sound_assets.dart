import 'dart:convert';
import 'dart:io';

void main() {
  final manifestFile = File('assets/sounds/sounds_manifest.json');

  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing manifest: ${manifestFile.path}');
    exit(1);
  }

  final manifest = jsonDecode(manifestFile.readAsStringSync());
  if (manifest is! List) {
    stderr.writeln('Invalid manifest format: expected a JSON array.');
    exit(1);
  }

  final missingAudio = <String>[];
  final missingImages = <String>[];
  final actualAudioFiles = <String>{};
  final expectedAudioFiles = <String>{};

  for (final entry in manifest) {
    if (entry is! Map) continue;
    final id = entry['id']?.toString() ?? '<unknown>';
    final filePath = entry['filePath']?.toString() ?? '';
    final imagePath = entry['imageAsset']?.toString() ?? '';

    expectedAudioFiles.add(filePath);

    if (!File(filePath).existsSync()) {
      missingAudio.add('$id -> $filePath');
    } else {
      actualAudioFiles.add(filePath);
    }

    if (imagePath.isNotEmpty && !File(imagePath).existsSync()) {
      missingImages.add('$id -> $imagePath');
    }
  }

  final audioFolder = Directory('assets/sounds');
  if (audioFolder.existsSync()) {
    for (final file in audioFolder.listSync(recursive: true)) {
      if (file is File) actualAudioFiles.add(file.path);
    }
  }

  stdout.writeln('Sound asset manifest audit');
  stdout.writeln('--------------------------------');
  stdout.writeln('Expected sound count: ${manifest.length}');
  stdout.writeln('Actual audio files found: ${actualAudioFiles.length}');
  stdout.writeln('Missing audio assets: ${missingAudio.length}');
  stdout.writeln('Missing image assets: ${missingImages.length}');

  if (missingAudio.isNotEmpty) {
    stdout.writeln('\nMissing audio files:');
    for (final missing in missingAudio) {
      stdout.writeln('  - $missing');
    }
  }

  if (missingImages.isNotEmpty) {
    stdout.writeln('\nMissing image files:');
    for (final missing in missingImages) {
      stdout.writeln('  - $missing');
    }
  }

  if (missingAudio.isNotEmpty || missingImages.isNotEmpty) {
    stderr.writeln('\nProduction sound assets are not complete. Please add the missing files before release.');
    exit(1);
  }

  stdout.writeln('\nAll sound assets referenced by the manifest are present.');
}
