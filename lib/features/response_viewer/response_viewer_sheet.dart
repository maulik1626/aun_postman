import 'dart:convert';
import 'dart:io';

import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/domain/models/http_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

class ResponseViewerSheet extends StatefulWidget {
  const ResponseViewerSheet({
    super.key,
    required this.response,
  });

  final HttpResponse response;

  @override
  State<ResponseViewerSheet> createState() => _ResponseViewerSheetState();
}

class _ResponseViewerSheetState extends State<ResponseViewerSheet> {
  int _selectedTab = 0;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareResponse(
      BuildContext context, HttpResponse response) async {
    try {
      final ext = _detectContentType(response) == 'JSON' ? 'json' : 'txt';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/response.$ext');
      await file.writeAsString(response.body);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: ext == 'json' ? 'application/json' : 'text/plain')],
        subject: 'Response ${response.statusCode}',
      );
    } catch (e) {
      if (context.mounted) _showToast(context, 'Share failed: $e');
    }
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 60,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    final isDark =
        CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final statusColor = AppColors.statusColor(response.statusCode);

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.separator.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatusChip(
                label: '${response.statusCode} ${response.statusMessage}',
                color: statusColor,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: response.durationMs < 1000
                    ? '${response.durationMs}ms'
                    : '${(response.durationMs / 1000).toStringAsFixed(2)}s',
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: _formatSize(response.sizeBytes),
                color: CupertinoColors.systemIndigo,
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: response.body));
                  _showToast(context, 'Response copied');
                },
                child: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44,
                onPressed: () => _shareResponse(context, response),
                child: const Icon(CupertinoIcons.share, size: 18),
              ),
            ],
          ),
        ),

        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedTab,
            onValueChanged: (v) => setState(() => _selectedTab = v ?? 0),
            children: {
              0: Text('Pretty · ${_detectContentType(response)}'),
              1: const Text('Raw'),
              2: Text('Headers (${response.headers.length})'),
              3: Text('Cookies (${response.cookies.length})'),
            },
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _PrettyTab(
                body: response.body,
                isDark: isDark,
                scrollController: _scrollController,
              ),
              _RawTab(
                body: response.body,
                scrollController: _scrollController,
              ),
              _HeadersTab(
                headers: response.headers,
                scrollController: _scrollController,
              ),
              _CookiesTab(
                cookies: response.cookies,
                scrollController: _scrollController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _detectContentType(HttpResponse response) {
    final ct = response.headers['content-type'] ??
        response.headers['Content-Type'] ??
        '';
    if (ct.contains('json')) return 'JSON';
    if (ct.contains('xml')) return 'XML';
    if (ct.contains('html')) return 'HTML';
    return 'TEXT';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PrettyTab extends StatelessWidget {
  const _PrettyTab({
    required this.body,
    required this.isDark,
    required this.scrollController,
  });
  final String body;
  final bool isDark;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final (prettyBody, language) = _prettify(body);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: HighlightView(
            prettyBody,
            language: language,
            theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
            textStyle: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  (String, String) _prettify(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return (
        const JsonEncoder.withIndent('  ').convert(decoded),
        'json',
      );
    } catch (_) {}

    try {
      final doc = XmlDocument.parse(raw);
      return (doc.toXmlString(pretty: true, indent: '  '), 'xml');
    } catch (_) {}

    return (raw, 'plaintext');
  }
}

class _RawTab extends StatelessWidget {
  const _RawTab({required this.body, required this.scrollController});
  final String body;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        body,
        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
      ),
    );
  }
}

class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.headers, required this.scrollController});
  final Map<String, String> headers;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final entries = headers.entries.toList();
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value,
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookiesTab extends StatelessWidget {
  const _CookiesTab({required this.cookies, required this.scrollController});
  final List cookies;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (cookies.isEmpty) {
      return Center(
        child: Text(
          'No cookies',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: cookies.length,
      itemBuilder: (context, index) {
        final cookie = cookies[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cookie.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(cookie.value),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}
