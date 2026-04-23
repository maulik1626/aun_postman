import 'dart:async';

import 'package:aun_reqstudio/core/notifications/user_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app HTML preview for API responses (Cupertino / iOS path).
Future<void> showResponseHtmlPreviewSheetCupertino(
  BuildContext context, {
  required String html,
  String title = 'Preview',
}) async {
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (popupContext) => _ResponseHtmlPreviewSheetCupertino(
      html: html,
      title: title,
    ),
  );
}

class _ResponseHtmlPreviewSheetCupertino extends StatefulWidget {
  const _ResponseHtmlPreviewSheetCupertino({
    required this.html,
    required this.title,
  });

  final String html;
  final String title;

  @override
  State<_ResponseHtmlPreviewSheetCupertino> createState() =>
      _ResponseHtmlPreviewSheetCupertinoState();
}

class _ResponseHtmlPreviewSheetCupertinoState
    extends State<_ResponseHtmlPreviewSheetCupertino> {
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
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
                          child: CupertinoActivityIndicator(radius: 14),
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
