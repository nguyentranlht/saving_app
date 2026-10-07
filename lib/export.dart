import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup.dart';
import 'format.dart';
import 'l10n.dart';
import 'store.dart';

/// Ghi CSV ra file tạm rồi mở bảng chia sẻ (Lưu vào Files, Drive, Zalo, email...).
/// Thêm BOM UTF-8 để Excel hiển thị đúng tiếng Việt.
/// [origin]: vùng nút vừa bấm (toạ độ màn hình), cần cho iPad và iOS 26 trở lên.
Future<void> shareCsv(AppStore store, {Rect? origin}) async {
  final dir = await getTemporaryDirectory();
  final n = DateTime.now();
  final name = 'ting_ting_${n.year}${two(n.month)}${two(n.day)}.csv';
  final file = File('${dir.path}/$name');
  await file.writeAsString('﻿${store.exportCsv()}', flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv', name: name)],
    subject: S.current.exportSubject,
    sharePositionOrigin: origin,
  );
}

/// Ghi file sao lưu .json rồi mở bảng chia sẻ. Trả về true nếu người dùng đã lưu/gửi file.
Future<bool> shareBackup(AppStore store, {Rect? origin}) async {
  final dir = await getTemporaryDirectory();
  final n = DateTime.now();
  final name = 'ting_ting_backup_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}.json';
  final file = File('${dir.path}/$name');
  await file.writeAsString(store.toBackup().encode(), flush: true);
  final r = await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: name)],
    subject: S.current.backupSubject,
    sharePositionOrigin: origin,
  );
  // "unavailable": nền tảng không báo kết quả; coi như đã lưu.
  return r.status != ShareResultStatus.dismissed;
}

/// Cho người dùng chọn file sao lưu. Trả về null nếu bỏ qua;
/// ném [FormatException] nếu file không hợp lệ.
Future<Backup?> pickBackup() async {
  final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
  final f = r?.files.single;
  if (f == null) return null;
  final bytes = f.bytes ?? (f.path == null ? null : await File(f.path!).readAsBytes());
  if (bytes == null) throw const FormatException('cannot read file');
  return Backup.parse(utf8.decode(bytes, allowMalformed: true));
}
