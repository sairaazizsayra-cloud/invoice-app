import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  Future<String> uploadBusinessLogo({
    required String businessId,
    required Uint8List bytes,
  }) async {
    return _uploadImage(
      refPath: StoragePaths.businessLogo(businessId),
      bytes: bytes,
      sizeError: const AppException(AppStrings.logoUploadFailed, debugCode: 'logo-size'),
    );
  }

  Future<String> uploadProductImage({
    required String businessId,
    required String productId,
    required Uint8List bytes,
  }) async {
    return _uploadImage(
      refPath: StoragePaths.productImage(businessId, productId),
      bytes: bytes,
      sizeError: const AppException(AppStrings.productImageFailed, debugCode: 'product-image-size'),
    );
  }

  Future<String> _uploadImage({
    required String refPath,
    required Uint8List bytes,
    required AppException sizeError,
  }) async {
    if (bytes.isEmpty || bytes.length > AppConstants.maxImageUploadBytes) {
      throw sizeError;
    }

    final ref = _storage.ref(refPath);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=3600'),
    );
    return ref.getDownloadURL();
  }

  Future<Uint8List?> downloadBusinessLogo(String businessId) async {
    if (!FirebaseBootstrap.initialized) return null;
    try {
      return await _storage.ref(StoragePaths.businessLogo(businessId)).getData(AppConstants.maxImageUploadBytes);
    } catch (error, stack) {
      AppLogger.error('Business logo download failed', error, stack);
      return null;
    }
  }

  Future<String> uploadInvoicePdf({
    required String businessId,
    required String invoiceId,
    required Uint8List bytes,
  }) async {
    if (!FirebaseBootstrap.initialized) {
      throw const AppException(AppStrings.authFirebaseNotConfigured, debugCode: 'firebase-unconfigured');
    }
    if (bytes.isEmpty || bytes.length > AppConstants.maxPdfUploadBytes) {
      throw const AppException(AppStrings.pdfUploadFailed, debugCode: 'pdf-size');
    }

    try {
      final ref = _storage.ref(StoragePaths.invoiceDocument(businessId, invoiceId));
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf', cacheControl: 'private,max-age=3600'),
      );
      return ref.getDownloadURL();
    } on AppException {
      rethrow;
    } catch (error, stack) {
      AppLogger.error('Invoice PDF upload failed', error, stack);
      throw const AppException(AppStrings.pdfUploadFailed, debugCode: 'pdf-upload');
    }
  }
}
