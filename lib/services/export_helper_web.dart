import 'dart:convert';
import 'dart:js_interop';

@JS('eval')
external void _eval(JSString code);

Future<bool> saveJsonPlatform(String fileName, String jsonStr) async {
  try {
    final base64Data = base64Encode(utf8.encode(jsonStr));
    final jsCode = '''
      (function() {
        var a = document.createElement('a');
        a.href = 'data:application/json;base64,$base64Data';
        a.download = '$fileName';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
      })();
    ''';
    _eval(jsCode.toJS);
    return true;
  } catch (_) {
    return false;
  }
}