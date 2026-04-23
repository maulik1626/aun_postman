import 'dart:async';

import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app HTML preview for API responses (Material / Android path).
Future<void> showResponseHtmlPreviewSheetMaterial(
  BuildContext context, {
  required String html,
  String title = 'Preview',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return SizedBox(
        height: height,
        child: _ResponseHtmlPreviewSheetMaterial(
          html: html,
          title: title,
        ),
      );
    },
  );
}

class _ResponseHtmlPreviewSheetMaterial extends StatefulWidget {
  const _ResponseHtmlPreviewSheetMaterial({
    required this.html,
    required this.title,
  });

  final String html;
  final String title;

  @override
  State<_ResponseHtmlPreviewSheetMaterial> createState() =>
      _ResponseHtmlPreviewSheetMaterialState();
}

class _ResponseHtmlPreviewSheetMaterialState
    extends State<_ResponseHtmlPreviewSheetMaterial> {
  late final WebViewController _controller;
  var _loading = true;

  static bool _allowInDocumentNavigation(Uri? uri) {
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'file' ||
        scheme == 'blob';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final next = Uri.tryParse(request.url);
            if (_allowInDocumentNavigation(next)) {
              return NavigationDecision.navigate;
            }
            if (next != null &&
                (next.scheme == 'http' || next.scheme == 'https')) {
              unawaited(
                launchUrl(next, mode: LaunchMode.externalApplication),
              );
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() => _loading = false);
            UserNotification.show(
              context: context,
              title: 'Could not load preview',
              body: error.description.isEmpty
                  ? 'Please check your connection and try again.'
                  : error.description,
            );
          },
        ),
      )
      ..loadHtmlString(
        widget.html,
        baseUrl: 'https://reqstudio.preview/',
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
