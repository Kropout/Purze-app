/// Run with: dart tool/download_fonts.dart
/// Downloads Geist and Inter font files from Google Fonts CDN and
/// places them under assets/fonts/ for offline APK bundling.

import 'dart:io';

// google_fonts downloads from:
// https://fonts.gstatic.com/s/{lowerFamily}/v{n}/{hash}.ttf
// The hash is the SHA256 of the file content stored in the package source.

// Geist hashes from google_fonts 8.0.2 (part_g.dart)
const geistFonts = [
  ('Geist-Thin',      '100', 'normal', '4061f09e0cb1d3f7b2f12d2bf0c6642be5110f667e0f42dc3a403edeaff667ee'),
  ('Geist-ExtraLight','200', 'normal', 'cd8c8aee1286c6a5f879829dba94e87ce421cef800d9b1c1ce1e1103d7e0e4df'),
  ('Geist-Light',     '300', 'normal', '8417e56724541b6d6ce39f4f074782631aa10d8e874733c170399fa919aec825'),
  ('Geist-Regular',   '400', 'normal', 'e8c77de0dcaef23dc92d0c6f1e32778b0e0f06b91197a503495a9f126c9752a1'),
  ('Geist-Medium',    '500', 'normal', 'ae7ee8606ec4b58cb0126a2410f15da7eb0a255131917cf679f815b9b4585a06'),
  ('Geist-SemiBold',  '600', 'normal', 'b38bd0250f78c22b151234a057c59778beb0dcca4c08396be4c407e29fda3b5e'),
  ('Geist-Bold',      '700', 'normal', 'f1d1176090d3f4b11d6116bb6e3dfac0e80f9d383dac3af5c8fe373de2e3ceff'),
  ('Geist-ExtraBold', '800', 'normal', '169f1a011ccc97cdb51cd5db1eb5e6d02d04e50540d5efe5820bd28d07733bdd'),
  ('Geist-Black',     '900', 'normal', 'e42ce1df1dd6dd6937e77e765897e4f89b125e175fa1d0a0c9682d22b1308569'),
];

// Inter hashes from google_fonts 8.0.2 (part_i.dart) — we need to find these
// We'll download the ones we actually use: 400, 500, 600, 700
// Inter is a variable font but google_fonts uses static instances.
// We'll fetch from Google's CDN directly using the css API to get TTF URLs.

const String baseUrl = 'https://fonts.gstatic.com/s';

Future<void> main() async {
  final client = HttpClient();
  
  // --- Download Geist ---
  final geistDir = Directory('assets/fonts/Geist');
  if (!geistDir.existsSync()) geistDir.createSync(recursive: true);
  
  print('Downloading Geist fonts...');
  for (final (name, weight, style, hash) in geistFonts) {
    final url = '$baseUrl/geist/v1/$hash.ttf';
    final file = File('assets/fonts/Geist/$name.ttf');
    
    if (file.existsSync()) {
      print('  ✓ $name (cached)');
      continue;
    }
    
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (prev, el) => prev..addAll(el));
        file.writeAsBytesSync(bytes);
        print('  ✓ $name (${bytes.length} bytes)');
      } else {
        print('  ✗ $name: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('  ✗ $name: $e');
    }
  }
  
  // --- Download Inter via Google Fonts CSS API ---
  print('\nDownloading Inter fonts...');
  final interDir = Directory('assets/fonts/Inter');
  if (!interDir.existsSync()) interDir.createSync(recursive: true);
  
  // Google Fonts CSS2 API for Inter static instances
  final interWeights = ['400', '500', '600', '700'];
  for (final weight in interWeights) {
    final cssUrl = 'https://fonts.googleapis.com/css2?family=Inter:wght@$weight&display=swap';
    try {
      final request = await client.getUrl(Uri.parse(cssUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final css = await response.transform(const SystemEncoding().decoder).join();
        // Extract TTF/WOFF2 URL from CSS
        final urlMatch = RegExp(r"url\(([^)]+\.(?:ttf|woff2))\)").firstMatch(css);
        if (urlMatch != null) {
          final fontUrl = urlMatch.group(1)!.replaceAll("'", "");
          
          final name = 'Inter-${_weightName(weight)}';
          final fontFile = File('assets/fonts/Inter/$name.ttf');
          
          if (!fontFile.existsSync()) {
            final fontRequest = await client.getUrl(Uri.parse(fontUrl));
            final fontResponse = await fontRequest.close();
            if (fontResponse.statusCode == 200) {
              final bytes = await fontResponse.fold<List<int>>([], (prev, el) => prev..addAll(el));
              fontFile.writeAsBytesSync(bytes);
              print('  ✓ $name (${bytes.length} bytes)');
            } else {
              print('  ✗ $name: HTTP ${fontResponse.statusCode}');
            }
          } else {
            print('  ✓ $name (cached)');
          }
        } else {
          print('  ✗ Inter $weight: no url found in CSS');
        }
      } else {
        print('  ✗ Inter $weight: CSS HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('  ✗ Inter $weight: $e');
    }
  }
  
  // --- Download Roboto as fallback ---
  print('\nDownloading Roboto fallback...');
  final robotoDir = Directory('assets/fonts/Roboto');
  if (!robotoDir.existsSync()) robotoDir.createSync(recursive: true);
  
  final robotoWeights = ['400', '500', '700'];
  for (final weight in robotoWeights) {
    final cssUrl = 'https://fonts.googleapis.com/css2?family=Roboto:wght@$weight&display=swap';
    try {
      final request = await client.getUrl(Uri.parse(cssUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final css = await response.transform(const SystemEncoding().decoder).join();
        final urlMatch = RegExp(r"url\(([^)]+\.(?:ttf|woff2))\)").firstMatch(css);
        if (urlMatch != null) {
          final fontUrl = urlMatch.group(1)!.replaceAll("'", "");
          final name = 'Roboto-${_weightName(weight)}';
          final fontFile = File('assets/fonts/Roboto/$name.ttf');
          
          if (!fontFile.existsSync()) {
            final fontRequest = await client.getUrl(Uri.parse(fontUrl));
            final fontResponse = await fontRequest.close();
            if (fontResponse.statusCode == 200) {
              final bytes = await fontResponse.fold<List<int>>([], (prev, el) => prev..addAll(el));
              fontFile.writeAsBytesSync(bytes);
              print('  ✓ $name (${bytes.length} bytes)');
            }
          } else {
            print('  ✓ $name (cached)');
          }
        }
      }
    } catch (e) {
      print('  ✗ Roboto $weight: $e');
    }
  }
  
  client.close();
  
  print('\n✅ Done! Add the fonts to pubspec.yaml assets.');
}

String _weightName(String weight) {
  return switch (weight) {
    '100' => 'Thin',
    '200' => 'ExtraLight',
    '300' => 'Light',
    '400' => 'Regular',
    '500' => 'Medium',
    '600' => 'SemiBold',
    '700' => 'Bold',
    '800' => 'ExtraBold',
    '900' => 'Black',
    _ => weight,
  };
}
