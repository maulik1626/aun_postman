import 'dart:async';

import 'package:aun_reqstudio/core/legal/legal_webview_allowlist.dart';
import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cupertino-only in-app WebView for legal/support URLs (iOS settings path).
Future<void> showLegalDocumentSheetCupertino(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!LegalWebViewAllowlist.isAllowedInAppNavigation(uri)) return;
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (popupContext) => _LegalDocumentSheetCupertino(
      initialUri: uri,
      title: title,
    ),
  );
}

class _LegalDocumentSheetCupertino extends StatefulWidget {
  const _LegalDocumentSheetCupertino({
    required this.initialUri,
    required this.title,
  });

  final Uri initialUri;
  final String title;

  @override
  State<_LegalDocumentSheetCupertino> createState() =>
      _LegalDocumentSheetCupertinoState();
}

class _LegalDocumentSheetCupertinoState
    extends State<_LegalDocumentSheetCupertino> {
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
    // final height = MediaQuery.sizeOf(context).height * 0.85;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        // height: height,
        width: MediaQuery.sizeOf(context).width,
        child: CupertinoPopupSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoNavigationBar(
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                middle: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_loading)
                      ColoredBox(
                        color: CupertinoColors.systemBackground.resolveFrom(
                          context,
                        ),
                        child: const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
