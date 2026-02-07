import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';

mixin DioFormdataMixin {
  var logger = (String msg) => dev.log(name: "DioFormdataMixin", msg);

  /// Optimized FormData creation that separates text and files
  Future<FormData> createFormData(dynamic rawData) async {
    if (rawData is! Map<String, dynamic>) return FormData.fromMap({});
    return await _convertToMultipartAsync(rawData);
  }

  /// Async version that processes files without blocking
  Future<FormData> _convertToMultipartAsync(Map<String, dynamic> data) async {
    final formData = FormData();
    final processingTasks = <Future>[];

    void processEntry(String key, dynamic value, {String parentKey = ''}) {
      final fullKey = parentKey.isEmpty ? key : '$parentKey[$key]';

      if (value is Uint8List) {
        // Process single Uint8List asynchronously
        processingTasks.add(_addBytesToFormData(formData, fullKey, value));
      } else if (value is File) {
        // Process single File asynchronously
        processingTasks.add(_addFileToFormData(formData, fullKey, value));
      } else if (value is List<Uint8List>) {
        // Process Uint8List list asynchronously
        processingTasks.add(_addBytesListToFormData(formData, fullKey, value));
      } else if (value is List<File>) {
        // Process File list asynchronously
        processingTasks.add(_addFileListToFormData(formData, fullKey, value));
      } else if (value is List<Map<String, dynamic>>) {
        // Handle list of maps - process each map in the list
        processingTasks.add(_handleMapList(formData, fullKey, value));
      } else if (value is Map<String, dynamic>) {
        if (_isSimpleMap(value)) {
          // Treat simple maps as flat key-value pairs
          value.forEach((nestedKey, nestedValue) {
            final simpleKey =
                '$key[$nestedKey]'; // Creates: paid[amount], paid[currency], etc.
            _addFieldToFormData(formData, simpleKey, nestedValue);
          });
        } else {
          // For complex nested maps, use recursive processing
          value.forEach((nestedKey, nestedValue) {
            processEntry(nestedKey, nestedValue, parentKey: fullKey);
          });
        }
      } else if (value is List) {
        // Handle generic lists
        processingTasks.add(
          _handleGenericList(formData, key, value, parentKey: parentKey),
        );
      } else {
        // Add text data immediately (non-blocking)
        formData.fields.add(MapEntry(fullKey, value.toString()));
      }
    }

    // First pass: separate and process text data immediately
    data.forEach((key, value) {
      processEntry(key, value);
    });

    // Process files in small batches to prevent freezing
    await _processInBatches(processingTasks, batchSize: 3);

    return formData;
  }

  /// Handle list of maps - common for arrays of objects
  Future<void> _handleMapList(
    FormData formData,
    String key,
    List<Map<String, dynamic>> mapList,
  ) async {
    // final arrayKey = key.endsWith("[]") ? key : "$key[]";
    final arrayKey = key;

    for (int i = 0; i < mapList.length; i++) {
      final map = mapList[i];

      // Process each key-value pair in the map
      for (final entry in map.entries) {
        final nestedKey = entry.key;
        final nestedValue = entry.value;
        final fullKey = "$arrayKey[$i][$nestedKey]";

        // Process the value based on its type
        if (nestedValue is Uint8List) {
          await _addBytesToFormData(formData, fullKey, nestedValue);
        } else if (nestedValue is File) {
          await _addFileToFormData(formData, fullKey, nestedValue);
        } else if (nestedValue is List<Uint8List>) {
          await _addBytesListToFormData(formData, fullKey, nestedValue);
        } else if (nestedValue is List<File>) {
          await _addFileListToFormData(formData, fullKey, nestedValue);
        } else if (nestedValue is Map<String, dynamic>) {
          // Recursively handle nested maps
          nestedValue.forEach((deepKey, deepValue) {
            final deepFullKey = "$fullKey[$deepKey]";
            _addFieldToFormData(formData, deepFullKey, deepValue);
          });
        } else if (nestedValue is List<Map<String, dynamic>>) {
          // Handle nested list of maps
          await _handleMapList(formData, fullKey, nestedValue);
        } else {
          // Primitive types
          _addFieldToFormData(formData, fullKey, nestedValue);
        }
      }

      // Yield control every 2 items to prevent freezing
      if (i % 2 == 0) await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Check if map is a simple key-value pair (not containing files/bytes)
  bool _isSimpleMap(Map<String, dynamic> map) {
    for (final value in map.values) {
      if (value is Uint8List ||
          value is File ||
          value is List<Uint8List> ||
          value is List<File> ||
          value is Map ||
          value is List) {
        return false;
      }
    }
    return true;
  }

  /// Safely add field to FormData
  void _addFieldToFormData(FormData formData, String key, dynamic value) {
    final stringValue = value?.toString() ?? '';
    logger("Adding field: $key = $stringValue");
    formData.fields.add(MapEntry(key, stringValue));
  }

  /// Handle generic lists that might contain mixed types
  Future<void> _handleGenericList(
    FormData formData,
    String key,
    List<dynamic> list, {
    String parentKey = '',
  }) async {
    final fullKey = parentKey.isEmpty ? key : '$parentKey[$key]';
    final arrayKey = fullKey;
    // final arrayKey = fullKey.endsWith("[]") ? fullKey : "$fullKey[]";

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      final itemKey = "$arrayKey[$i]"; // Creates: items[0], items[1], etc.

      if (item is Uint8List) {
        final multipart = await _createMultipartFileFromBytes(itemKey, item);
        formData.files.add(MapEntry(arrayKey, multipart));
      } else if (item is File) {
        final multipart = await _createMultipartFileFromFile(itemKey, item);
        formData.files.add(MapEntry(arrayKey, multipart));
      } else if (item is Map<String, dynamic>) {
        // For maps in lists, flatten them properly
        if (_isSimpleMap(item)) {
          item.forEach((nestedKey, nestedValue) {
            final nestedItemKey = "$arrayKey[$i][$nestedKey]";
            _addFieldToFormData(formData, nestedItemKey, nestedValue);
          });
        } else {
          // Complex nested structure
          item.forEach((nestedKey, nestedValue) {
            final complexKey = "$arrayKey[$i][$nestedKey]";
            // Recursively process complex values
            _processComplexValue(formData, complexKey, nestedValue);
          });
        }
      } else if (item is List<Map<String, dynamic>>) {
        // Handle list of maps in generic list
        await _handleMapList(formData, "$arrayKey[$i]", item);
      } else {
        // Primitive types in lists
        _addFieldToFormData(formData, itemKey, item);
      }

      // Yield control every 2 items to prevent freezing
      if (i % 2 == 0) await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Process complex values (Uint8List, File, etc.)
  void _processComplexValue(FormData formData, String key, dynamic value) {
    if (value is Uint8List) {
      _addBytesToFormData(formData, key, value);
    } else if (value is File) {
      _addFileToFormData(formData, key, value);
    } else if (value is List<Uint8List>) {
      _addBytesListToFormData(formData, key, value);
    } else if (value is List<File>) {
      _addFileListToFormData(formData, key, value);
    } else if (value is List<Map<String, dynamic>>) {
      _handleMapList(formData, key, value);
    } else {
      _addFieldToFormData(formData, key, value);
    }
  }

  /// Process tasks in batches with delays to prevent UI freezing
  Future<void> _processInBatches(
    List<Future> tasks, {
    int batchSize = 3,
  }) async {
    for (int i = 0; i < tasks.length; i += batchSize) {
      final batch = tasks.sublist(
        i,
        i + batchSize > tasks.length ? tasks.length : i + batchSize,
      );

      await Future.wait(batch);

      // Yield control to UI thread between batches
      if (i + batchSize < tasks.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  /// Add single Uint8List to FormData
  Future<void> _addBytesToFormData(
    FormData formData,
    String key,
    Uint8List bytes,
  ) async {
    final multipart = await _createMultipartFileFromBytes(key, bytes);
    formData.files.add(MapEntry(key, multipart));
  }

  /// Add single File to FormData
  Future<void> _addFileToFormData(
    FormData formData,
    String key,
    File file,
  ) async {
    final multipart = await _createMultipartFileFromFile(key, file);
    formData.files.add(MapEntry(key, multipart));
  }

  /// Add list of Uint8List to FormData
  Future<void> _addBytesListToFormData(
    FormData formData,
    String key,
    List<Uint8List> bytesList,
  ) async {
    // final arrayKey = key.endsWith("[]") ? key : "$key[]";
    final arrayKey = key;

    for (int i = 0; i < bytesList.length; i++) {
      final bytes = bytesList[i];
      final multipart = await _createMultipartFileFromBytes("$key-$i", bytes);
      formData.files.add(MapEntry(arrayKey, multipart));

      // Yield control every 2 files to prevent freezing
      if (i % 2 == 0) await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Add list of Files to FormData
  Future<void> _addFileListToFormData(
    FormData formData,
    String key,
    List<File> fileList,
  ) async {
    // final arrayKey = key.endsWith("[]") ? key : "$key[]";
    final arrayKey = key;

    for (int i = 0; i < fileList.length; i++) {
      final file = fileList[i];
      final multipart = await _createMultipartFileFromFile("$key-$i", file);
      formData.files.add(MapEntry(arrayKey, multipart));

      // Yield control every 2 files to prevent freezing
      if (i % 2 == 0) await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Create MultipartFile from bytes asynchronously
  Future<MultipartFile> _createMultipartFileFromBytes(
    String key,
    Uint8List bytes,
  ) {
    return Future(() {
      // Log file size for debugging
      final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
      logger(
        "Processing bytes: $key | Size: ${sizeInMB.toStringAsFixed(2)} MB",
      );

      return MultipartFile.fromBytes(
        bytes,
        filename: "file-${DateTime.now().millisecondsSinceEpoch}-$key.png",
        contentType: DioMediaType('image', 'png'),
      );
    });
  }

  /// Create MultipartFile from File asynchronously
  Future<MultipartFile> _createMultipartFileFromFile(String key, File file) {
    return Future(() {
      final filename = file.path.split('/').last;
      logger("Processing file: $key | Filename: $filename");

      return MultipartFile.fromFileSync(
        file.path,
        filename: filename,
        contentType: DioMediaType('image', 'png'),
      );
    });
  }
}
