import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

class JsonDropImportListenerImpl extends StatefulWidget {
  const JsonDropImportListenerImpl({
    super.key,
    required this.child,
    required this.onJsonDropped,
    this.onDropError,
  });

  final Widget child;
  final Future<void> Function(String content, String fileName) onJsonDropped;
  final void Function(String message)? onDropError;

  @override
  State<JsonDropImportListenerImpl> createState() =>
      _JsonDropImportListenerImplState();
}

class _JsonDropImportListenerImplState
    extends State<JsonDropImportListenerImpl> {
  static const int _maxDropFileSizeBytes = 5 * 1024 * 1024;
  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dragEnterSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;
  StreamSubscription<html.MouseEvent>? _dropSub;
  int _dragDepth = 0;
  bool _isDragging = false;

  bool _hasFilesInDragPayload(html.DataTransfer? transfer) {
    if (transfer == null) return false;
    final files = transfer.files ?? const <html.File>[];
    if (files.isNotEmpty) return true;
    final types = transfer.types;
    if (types == null) return false;
    for (final type in types) {
      if (type.toLowerCase() == 'files') return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _dragOverSub = html.window.onDragOver.listen((event) {
      event.preventDefault();
      if (!_hasFilesInDragPayload(event.dataTransfer)) return;
      if (!_isDragging) {
        _dragDepth = 1;
        setState(() => _isDragging = true);
      }
    });
    _dragEnterSub = html.window.onDragEnter.listen((event) {
      event.preventDefault();
      if (!_hasFilesInDragPayload(event.dataTransfer)) return;
      _dragDepth += 1;
      if (!_isDragging) {
        setState(() => _isDragging = true);
      }
    });
    _dragLeaveSub = html.window.onDragLeave.listen((event) {
      event.preventDefault();
      _dragDepth = (_dragDepth - 1).clamp(0, 9999);
      if (_dragDepth == 0 && _isDragging) {
        setState(() => _isDragging = false);
      }
    });
    _dropSub = html.window.onDrop.listen(_handleDropEvent);
  }

  @override
  void dispose() {
    _dragOverSub?.cancel();
    _dragEnterSub?.cancel();
    _dragLeaveSub?.cancel();
    _dropSub?.cancel();
    super.dispose();
  }

  Future<void> _handleDropEvent(html.MouseEvent event) async {
    event.preventDefault();
    _dragDepth = 0;
    if (_isDragging && mounted) {
      setState(() => _isDragging = false);
    }

    final files = event.dataTransfer.files ?? const <html.File>[];
    if (files.isEmpty) {
      return;
    }

    html.File? picked;
    for (final file in files) {
      if (file.name.toLowerCase().endsWith('.json')) {
        picked = file;
        break;
      }
    }
    if (picked == null) {
      widget.onDropError?.call('Drop a .json file to import.');
      return;
    }

    if (picked.size > _maxDropFileSizeBytes) {
      widget.onDropError?.call(
        'File is too large. Maximum supported JSON size is 5 MB.',
      );
      return;
    }

    try {
      final reader = html.FileReader();
      final completer = Completer<String>();
      reader.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.completeError('Unable to read dropped file.');
        }
      });
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is String) {
          completer.complete(result);
          return;
        }
        completer.completeError('Dropped file content is not valid text JSON.');
      });
      reader.readAsText(picked);
      final content = await completer.future;
      await widget.onJsonDropped(content, picked.name);
    } catch (error) {
      widget.onDropError?.call(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !_isDragging,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: _isDragging ? 1 : 0,
            child: Container(
              color: const Color(0x9E0C111A),
              alignment: Alignment.center,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xED111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFDB952C),
                    width: 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3B000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Drop it like it's hot",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Release to import your JSON into the workspace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFD6DEEA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
