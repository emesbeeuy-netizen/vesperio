import 'package:share_plus/share_plus.dart';
import '../constants/app_constants.dart';

class SocialService {
  static final SocialService _instance = SocialService._internal();

  factory SocialService() => _instance;

  SocialService._internal();

  Future<void> shareApp() async {
    await Share.share(AppStrings.shareMessage);
  }

  Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
