import 'package:flutter/services.dart';

void playCustomSound(String type) {
  if (type == 'whistle') {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
  } else {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }
}