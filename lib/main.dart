import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_exif/native_exif.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExifEditor(),
    );
  }
}

class ExifEditor extends StatefulWidget {
  const ExifEditor({super.key});

  @override
  _ExifEditorState createState() => _ExifEditorState();
}

class _ExifEditorState extends State<ExifEditor> {
  String searchKeyword = "_HDR";
  String folderPath = "/storage/emulated/0/DCIM/Camera";

  Future<void> updateExifData(String path) async {
    try {
      // Exifデータを読み取る
      final exif = await Exif.fromPath(path);
      final dateTimeOriginal = await exif.getAttribute('DateTimeOriginal');
      if (dateTimeOriginal == null) {
        print("Exifデータが見つかりません: $path");
        return;
      }

      String newDateTime = extractDateFromFileName(path);
      if (newDateTime.isEmpty) {
        print("ファイル名から日時を取得できません: $path");
        return;
      }

      // Exifデータを更新
      await exif.writeAttribute('DateTimeOriginal', newDateTime);
      await exif.close();

      print("Exifデータを更新しました: $path");
    } catch (e) {
      print("Exifデータの更新に失敗しました: $e");
    }
  }

  Future<void> processImages() async {
    final directory = Directory(folderPath);
    final files = directory.listSync();

    for (var file in files) {
      if (file is File &&
          file.path.contains(searchKeyword) &&
          (file.path.endsWith(".jpg") || file.path.endsWith(".jpeg"))) {
        await updateExifData(file.path);
      }
    }
    print("処理完了");
  }

  String extractDateFromFileName(String fileName) {
    // 正規表現でファイル名から必要な情報を抽出
    final regex = RegExp(r'IMG_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})');
    final match = regex.firstMatch(fileName);

    if (match != null) {
      // 各グループからデータを取得
      final year = match.group(1);
      final month = match.group(2);
      final day = match.group(3);
      final hour = match.group(4);
      final minute = match.group(5);
      final second = match.group(6);

      // フォーマットに従って文字列を生成
      return '$year:$month:$day $hour:$minute:$second';
    }

    // マッチしなかった場合は空文字列を返す
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exif Fixer'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: processImages,
          child: Text('Update Exif Data'),
        ),
      ),
    );
  }
}
