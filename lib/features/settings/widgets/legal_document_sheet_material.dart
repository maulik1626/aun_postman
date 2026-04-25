import 'dart:async';

import 'package:aun_reqstudio/core/legal/legal_webview_allowlist.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Material-only in-app WebView for legal/support URLs (Android settings path).
Future<void> showLegalDocumentSheetMaterial(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!LegalWebViewAllowlist.isAllowedInAppNavigation(uri)) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (sheetContext) {
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height,
        child: _LegalDocumentSheetMaterial(initialUri: uri, title: title),
      );
    },
  );
}

class _LegalDocumentSheetMaterial extends StatefulWidget {
  const _LegalDocumentSheetMaterial({
    required this.initialUri,
    required this.title,
  });

  final Uri initialUri;
  final String title;

  @override
  State<_LegalDocumentSheetMaterial> createState() =>
      _LegalDocumentSheetMaterialState();
}

class _LegalDocumentSheetMaterialState
    extends State<_LegalDocumentSheetMaterial> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final next = Uri.tryParse(request.url);
            if (next != null &&
                LegalWebViewAllowlist.isAllowedInAppNavigation(next)) {
              return NavigationDecision.navigate;
            }
            if (next != null) {
              unawaited(launchUrl(next, mode: LaunchMode.externalApplication));
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
              title: 'Could not load page',
              body: error.description.isEmpty
                  ? 'Please check your connection and try again.'
                  : error.description,
            );
          },
        ),
      )
      ..loadRequest(widget.initialUri);
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
