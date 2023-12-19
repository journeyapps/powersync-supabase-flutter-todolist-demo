import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachments/local_storage_adapter.dart';
import 'package:powersync_flutter_demo/attachments/remote_storage_adapter.dart';
import 'package:powersync_flutter_demo/models/schema.dart';

/// Global reference to the queue
late final PhotoAttachmentQueue attachmentQueue;
final localStorage = LocalStorageAdapter();
final remoteStorage = SupabaseStorageAdapter();

class PhotoAttachmentQueue extends AbstractAttachmentQueue {
  PhotoAttachmentQueue(db, localStorage, remoteStorage)
      : super(db: db, localStorage: localStorage, remoteStorage: remoteStorage);

  @override
  init() async {
    if (AppConfig.supabaseStorageBucket.isEmpty) {
      log.info(
          'No Supabase bucket configured, skip setting up PhotoAttachmentQueue watches');
      return;
    }

    await super.init();
  }

  @override
  Future<Attachment> savePhoto(String photoId, int size) async {
    String filename = '$photoId.jpg';
    Attachment photoAttachment = Attachment(
      id: photoId,
      filename: filename,
      state: AttachmentState.queuedUpload.index,
      mediaType: 'image/jpeg',
      localUri: getLocalFilePathSuffix(filename),
      size: size,
    );

    return attachmentsService.saveAttachment(photoAttachment);
  }

  @override
  Future<Attachment> deletePhoto(String photoId) async {
    String filename = '$photoId.jpg';
    Attachment photoAttachment = Attachment(
        id: photoId,
        filename: filename,
        state: AttachmentState.queuedDelete.index);

    return attachmentsService.saveAttachment(photoAttachment);
  }

  @override
  StreamSubscription<void> watchIds() {
    log.info('Watching photos in $TODOS_TABLE...');
    return db.watch('''
      SELECT photo_id FROM $TODOS_TABLE
      WHERE photo_id IS NOT NULL
    ''').map((results) {
      return results.map((row) => row['photo_id'] as String).toList();
    }).listen((ids) async {
      List<String> idsInQueue = await attachmentsService.getAttachmentIds();
      for (String id in ids) {
        await syncingService.reconcileId(id, idsInQueue);
      }
    });
  }
}

initializeAttachmentQueue(PowerSyncDatabase db) async {
  attachmentQueue = PhotoAttachmentQueue(db, localStorage, remoteStorage);
  await attachmentQueue.init();
}
