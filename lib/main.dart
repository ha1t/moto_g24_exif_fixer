import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_exif/native_exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

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
  List<String> searchKeywords = ["_HDR", "_MFNR"];
  String folderPath = "/storage/emulated/0/DCIM/Camera";
  List<String> logMessages = [];
  final TextEditingController folderPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    folderPathController.text = folderPath;
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    final readPermission = await Permission.storage.request();
    final writePermission = await Permission.manageExternalStorage.request();

    if (!readPermission.isGranted || !writePermission.isGranted) {
      addLog("ストレージの読み書き権限が拒否されました");
    } else {
      addLog("ストレージの読み書き権限が許可されました");
    }
  }

  void addLog(String message) {
    setState(() {
      logMessages.add(message);
    });
  }

  Future<void> updateExifData(String filePath) async {
    try {
      // Exifデータを読み取る
      final exif = await Exif.fromPath(filePath);
      final fileName = path.basename(filePath);
      final dateTimeOriginal = await exif.getAttribute('DateTimeOriginal');
      if (dateTimeOriginal != null) {
        addLog("Skip: $fileName");
        return;
      }

      String newDateTime = extractDateFromFileName(filePath);
      if (newDateTime.isEmpty) {
        addLog("ファイル名から日時を取得できません: $fileName");
        return;
      }

      // Exifデータを更新
      await exif.writeAttribute('DateTimeOriginal', newDateTime);
      await exif.close();

      addLog("Update: $fileName");
    } catch (e) {
      addLog("エラーが発生しました: $e");
    }
  }

  bool containsSearchKeyword(String fileName) {
    return searchKeywords.any((keyword) => fileName.contains(keyword));
  }

  Future<void> processImages() async {
    final directory = Directory(folderPath);
    final files = directory.listSync();

    for (var file in files) {
      if (file is File &&
          containsSearchKeyword(file.path) &&
          (file.path.endsWith(".jpg") || file.path.endsWith(".jpeg"))) {
        await updateExifData(file.path);
      }
    }
    addLog("処理完了");
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
        title: Text('Moto G24 Exif Fixer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: folderPathController,
              decoration: InputDecoration(
                labelText: 'Folder Path',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                folderPath = value;
              },
            ),
          ),
          ElevatedButton(
            onPressed: processImages,
            child: Text('Update Exif Data'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(logMessages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
