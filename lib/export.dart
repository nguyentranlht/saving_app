import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'format.dart';
import 'l10n.dart';
import 'store.dart';

/// Ghi CSV ra file tạm rồi mở bảng chia sẻ (Lưu vào Files, Drive, Zalo, email...).
/// Thêm BOM UTF-8 để Excel hiển thị đúng tiếng Việt.
Future<void> shareCsv(AppStore store) async {
  final dir = await getTemporaryDirectory();
  final n = DateTime.now();
  final name = 'so_thu_chi_${n.year}${two(n.month)}${two(n.day)}.csv';
  final file = File('${dir.path}/$name');
  await file.writeAsString('﻿${store.exportCsv()}', flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv', name: name)],
    subject: S.current.exportSubject,
  );
}
