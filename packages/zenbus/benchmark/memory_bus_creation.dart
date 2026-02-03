// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:zenbus/src/bus.dart';
import 'package:vm_service/vm_service.dart' hide Isolate;
import 'package:vm_service/vm_service_io.dart';

/// Implementation definition
class ZenBusImplementation<T> {
  final String name;
  final ZenBus<T> Function() create;

  ZenBusImplementation(this.name, this.create);
}

/// Define implementations
final List<ZenBusImplementation<int>> implementations = [
  ZenBusImplementation('Stream', ZenBus.stream),
  ZenBusImplementation('Alien Signal', ZenBus.alienSignals),
];

/// Memory helper
class MemoryHelper {
  VmService? _vmService;
  String? _isolateId;

  Future<bool> initialize() async {
    try {
      final info = await Service.getInfo();
      final serverUri = info.serverUri;
      if (serverUri == null) {
        print('⚠️  VM Service not available. Run with --observe flag.');
        return false;
      }

      final wsUri = serverUri.replace(scheme: 'ws').resolve('ws');
      _vmService = await vmServiceConnectUri(wsUri.toString());

      final vm = await _vmService!.getVM();
      _isolateId = vm.isolates?.firstOrNull?.id;

      if (_isolateId == null) {
        print('⚠️  Could not find main isolate');
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️  Could not connect to VM Service: $e');
      return false;
    }
  }

  Future<void> forceGC() async {
    if (_vmService == null || _isolateId == null) return;
    try {
      await _vmService!.getAllocationProfile(_isolateId!, gc: true);
    } catch (_) {}
  }

  Future<int> getHeapUsage() async {
    if (_vmService == null || _isolateId == null) return 0;
    try {
      final profile = await _vmService!.getAllocationProfile(_isolateId!);
      return profile.memoryUsage?.heapUsage ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> dispose() async {
    await _vmService?.dispose();
    _vmService = null;
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}

Future<void> main() async {
  print('=' * 70);
  print('Memory Benchmark: Bus Creation (1000 instances)');
  print('=' * 70);

  final helper = MemoryHelper();
  if (!await helper.initialize()) {
    print('Failed to initialize VM Service');
    return;
  }

  print('');
  print('Testing each implementation in isolation...');
  print('');

  for (final impl in implementations) {
    // Force GC and wait
    await helper.forceGC();
    await Future.delayed(const Duration(milliseconds: 200));
    
    final heapBefore = await helper.getHeapUsage();
    
    // Create 1000 bus instances
    final buses = <ZenBus<int>>[];
    for (int i = 0; i < 1000; i++) {
      buses.add(impl.create());
    }
    
    // Measure after allocation
    final heapAfter = await helper.getHeapUsage();
    final delta = heapAfter - heapBefore;
    
    print('${impl.name}:');
    print('  Before: ${_formatBytes(heapBefore)}');
    print('  After:  ${_formatBytes(heapAfter)}');
    print('  Delta:  ${_formatBytes(delta)}');
    print('  Per instance: ${_formatBytes(delta ~/ 1000)}');
    print('');
    
    // Keep objects alive
    buses.hashCode;
  }

  await helper.dispose();
  print('✅ Complete!');
  
  // Exit explicitly when using --observe
  exit(0);
}
