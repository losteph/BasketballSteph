import 'sound_service_mobile.dart' if (dart.library.js_interop) 'sound_service_web.dart';

class SoundService {
  static void playWhistle() {
    playCustomSound('whistle');
  }

  static void playBell() {
    playCustomSound('bell');
  }
}