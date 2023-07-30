import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nothing_gallery/classes/AlbumInfo.dart';
import 'package:nothing_gallery/constants/sharedPrefKey.dart';
import 'package:nothing_gallery/main.dart';
import 'package:nothing_gallery/style.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

Future<List<AssetEntity>> loadAllImages() async {
  int total = await PhotoManager.getAssetCount();
  List<AssetEntity> pictures =
      await PhotoManager.getAssetListRange(start: 0, end: total);
  pictures.sort((a, b) => b.createDateTime.millisecondsSinceEpoch
      .compareTo(a.createDateTime.millisecondsSinceEpoch));
  return pictures;
}

Future<AlbumInfo> getAlbumInfo(AssetPathEntity album) async {
  int assetCount = await album.assetCountAsync;
  List<AssetEntity> images =
      await album.getAssetListRange(start: 0, end: assetCount);
  images.sort((a, b) => b.createDateTime.millisecondsSinceEpoch
      .compareTo(a.createDateTime.millisecondsSinceEpoch));

  return AlbumInfo(album, images, images[0], assetCount);
}

Future<void> confirmDelete(BuildContext context,
    List<AssetEntity> deleteEntityList, bool useTrash) async {
  List<File> backups = [];
  if (useTrash) {
    for (var item in deleteEntityList) {
      File? backup = await moveToTrash(item);
      if (backup != null) backups.add(backup);
    }
  }

  List<String> result = await PhotoManager.editor
      .deleteWithIds(deleteEntityList.map((e) => e.id).toList());
  if (result.isEmpty) {
    print("Files not deleted. Removing Backup");
    for (var element in backups) {
      element.deleteSync();
    }
  }
}

Future<File?> moveToTrash(AssetEntity entity) async {
  Directory private = await getApplicationDocumentsDirectory();

  Uint8List? originBytes = await entity.originBytes;
  File? originFile = await entity.originFile;
  Directory trash_dir = Directory("${private.path}/trash");

  if (!(await trash_dir.exists())) {
    await trash_dir.create();
  }

  if (originFile != null && originBytes != null) {
    Uint8List imageInUnit8List = originBytes;
    var lastSeparator = originFile.path.lastIndexOf(Platform.pathSeparator);

    File file = await File(
            '${trash_dir.path}${originFile.path.substring(lastSeparator)}')
        .create();
    file.writeAsBytesSync(imageInUnit8List);
    return file;
  }
  return null;
}
