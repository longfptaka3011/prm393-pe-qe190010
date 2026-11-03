import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['PHONE_SCREENSHOT_DIR'] ?? 'artifacts/phone',
  );
  await directory.create(recursive: true);
  final metadataFile = File('${directory.path}/device.json');
  if (!metadataFile.existsSync()) {
    throw StateError(
      'Run node tools/phone_evidence.mjs to verify the physical phone before capture.',
    );
  }
  final device =
      jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
  if (device['physicalDevice'] != true) {
    throw StateError('A physical phone is required.');
  }
  await integrationDriver(
    responseDataCallback: (data) async {
      final metadata = Map<String, dynamic>.of(data ?? {})
        ..remove('screenshots');
      await File('${directory.path}/result.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(metadata));
    },
    writeResponseOnFailure: true,
  );
}
