import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

class DriveService {
  static const String _targetFolderId = '1E_OdZL65ZAkibe8vHADiNLdYodSddF-q';
  static const int _uploadTimeoutSeconds = 30;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  bool get isAuthenticated => _currentUser != null && _driveApi != null;

  // Initialize and Sign In
  Future<GoogleSignInAccount?> signIn() async {
    try {
      debugPrint('[DriveService] INFO: Attempting sign-in...');
      
      // Try silent sign-in first
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        debugPrint('[DriveService] INFO: Silent sign-in successful for ${_currentUser!.email}');
      } else {
        debugPrint('[DriveService] INFO: Silent sign-in failed, prompting user...');
        _currentUser = await _googleSignIn.signIn();
        if (_currentUser != null) {
          debugPrint('[DriveService] INFO: Interactive sign-in successful for ${_currentUser!.email}');
        }
      }
      
      if (_currentUser != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          debugPrint('[DriveService] INFO: Drive API client initialized successfully');
        } else {
          debugPrint('[DriveService] ERROR: Failed to create authenticated client');
        }
      } else {
        debugPrint('[DriveService] WARNING: Sign-in cancelled by user');
      }
      
      return _currentUser;
    } catch (e, stackTrace) {
      debugPrint('[DriveService] ERROR: Sign-in failed - $e');
      debugPrint('[DriveService] ERROR: Stack trace: $stackTrace');
      return null;
    }
  }

  // Upload File to Drive with comprehensive error handling and logging
  Future<Map<String, String>?> uploadFile(File file, String fileName) async {
    try {
      debugPrint('[DriveService] INFO: Starting upload for file: $fileName');
      
      // Validate file exists
      if (!await file.exists()) {
        debugPrint('[DriveService] ERROR: File does not exist: ${file.path}');
        throw Exception('File does not exist');
      }
      
      // Validate file size (max 10MB for profile pictures)
      final fileSize = await file.length();
      debugPrint('[DriveService] INFO: File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      if (fileSize > 10 * 1024 * 1024) {
        debugPrint('[DriveService] ERROR: File too large: ${fileSize} bytes');
        throw Exception('File size exceeds 10MB limit');
      }
      
      // Ensure authenticated
      if (_driveApi == null) {
        debugPrint('[DriveService] INFO: Not authenticated, initiating sign-in...');
        await signIn();
      }
      
      if (_driveApi == null) {
        debugPrint('[DriveService] ERROR: Failed to initialize Drive API');
        throw Exception('Google Drive authentication failed');
      }

      debugPrint('[DriveService] INFO: Creating Drive file metadata...');
      
      // 1. Create File Metadata
      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [_targetFolderId];
      
      debugPrint('[DriveService] INFO: Target folder ID: $_targetFolderId');

      // 2. Upload Content with timeout
      debugPrint('[DriveService] INFO: Uploading file content...');
      final media = drive.Media(file.openRead(), fileSize);
      
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webContentLink, webViewLink, thumbnailLink, name, parents',
      ).timeout(
        Duration(seconds: _uploadTimeoutSeconds),
        onTimeout: () {
          debugPrint('[DriveService] ERROR: Upload timeout after $_uploadTimeoutSeconds seconds');
          throw Exception('Upload timeout - please check your connection');
        },
      );

      // Validate upload result
      if (result.id == null || result.id!.isEmpty) {
        debugPrint('[DriveService] ERROR: Upload succeeded but no file ID returned');
        throw Exception('Invalid upload response - no file ID');
      }
      
      debugPrint('[DriveService] INFO: Upload successful - File ID: ${result.id}');
      debugPrint('[DriveService] INFO: File parents: ${result.parents}');

      // 3. Make Publicly Readable
      debugPrint('[DriveService] INFO: Setting public read permissions...');
      try {
        final permission = drive.Permission()
          ..role = 'reader'
          ..type = 'anyone';
        
        await _driveApi!.permissions.create(permission, result.id!).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            debugPrint('[DriveService] WARNING: Permission creation timeout');
            throw Exception('Permission creation timeout');
          },
        );
        
        debugPrint('[DriveService] INFO: Public read permission set successfully');
      } catch (e) {
        debugPrint('[DriveService] ERROR: Failed to set permissions - $e');
        // Don't fail the entire upload, just log the error
        debugPrint('[DriveService] WARNING: Continuing despite permission failure');
      }
        
      // Construct public URL
      final publicUrl = 'https://drive.google.com/thumbnail?id=${result.id}&sz=w1000';
      
      // Validate URL format
      if (!publicUrl.contains('drive.google.com') || !publicUrl.contains(result.id!)) {
        debugPrint('[DriveService] ERROR: Generated invalid URL: $publicUrl');
        throw Exception('Invalid URL generated');
      }
      
      debugPrint('[DriveService] INFO: Generated public URL: $publicUrl');
      debugPrint('[DriveService] SUCCESS: Upload completed successfully');

      return {
        'id': result.id!,
        'url': publicUrl,
        'webViewLink': result.webViewLink ?? '',
        'fileName': fileName,
      };
    } on TimeoutException catch (e) {
      debugPrint('[DriveService] ERROR: Timeout exception - $e');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[DriveService] ERROR: Upload failed - $e');
      debugPrint('[DriveService] ERROR: Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Delete file from Drive
  Future<bool> deleteFile(String fileId) async {
    try {
      debugPrint('[DriveService] INFO: Attempting to delete file: $fileId');
      
      if (_driveApi == null) {
        debugPrint('[DriveService] WARNING: Not authenticated, skipping delete');
        return false;
      }
      
      await _driveApi!.files.delete(fileId);
      debugPrint('[DriveService] SUCCESS: File deleted: $fileId');
      return true;
    } catch (e) {
      debugPrint('[DriveService] ERROR: Failed to delete file $fileId - $e');
      return false;
    }
  }
  
  Future<void> signOut() async {
    debugPrint('[DriveService] INFO: Signing out Google account');
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      debugPrint('[DriveService] SUCCESS: Sign-out complete');
    } catch (e) {
      debugPrint('[DriveService] ERROR: Sign-out failed - $e');
    }
  }
  // Static helper to parse public Drive links and convert to direct view URL
  static String? getDirectLinkFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String? fileId;
      
      // Handle standard view URL: drive.google.com/file/d/FILE_ID/view
      if (uri.pathSegments.contains('d')) {
        final index = uri.pathSegments.indexOf('d');
        if (index + 1 < uri.pathSegments.length) {
          fileId = uri.pathSegments[index + 1];
        }
      } 
      // Handle ID parameter: drive.google.com/open?id=FILE_ID
      else if (uri.queryParameters.containsKey('id')) {
        fileId = uri.queryParameters['id'];
      }

      if (fileId != null && fileId.isNotEmpty) {
        // Return direct image view URL
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    } catch (_) {}
    return null;
  }
}
