import 'dart:io';

void main() {
  var d = Directory('c:/Users/youcef.alouat/.gemini/antigravity/scratch/marketplace-controlee/mobile/marketplace_app/lib');
  for (var f in d.listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      var s = f.readAsStringSync();
      if (s.contains('\$([char]10)')) {
        print('Fixing \${f.path}');
        f.writeAsStringSync(s.replaceAll('\$([char]10)', '\n'));
      }
    }
  }
}
