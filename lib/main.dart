import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;
  WidgetsBinding.instance.addPersistentFrameCallback((_) {
    if (!debugPaintBaselinesEnabled &&
        !debugPaintSizeEnabled &&
        !debugPaintPointersEnabled) {
      return;
    }

    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintPointersEnabled = false;
  });
  runApp(const PtsDataApp());
}
