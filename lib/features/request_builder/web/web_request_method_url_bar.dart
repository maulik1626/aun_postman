import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/web/web_chrome_layout.dart';
import 'package:aun_reqstudio/domain/enums/http_method.dart';
import 'package:aun_reqstudio/features/request_builder/web/url_template_range.dart';
import 'package:aun_reqstudio/features/request_builder/web/web_request_url_field.dart';
import 'package:flutter/material.dart';

/// Web request bar: HTTP method as an inline prefix dropdown + URL field in one
/// control (no method dialog), styled like the collections explorer search field.
class WebRequestMethodUrlBar extends StatelessWidget {
  const WebRequestMethodUrlBar({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.urlController,
    required this.urlFocusNode,
    required this.urlFieldFocused,
    required this.definedEnvKeys,
    required this.showClearButton,
    required this.onUrlChanged,
    this.hintText,
    this.onClear,
    this.onClosedTemplateDoubleTap,
  });

  final HttpMethod method;
  final ValueChanged<HttpMethod> onMethodChanged;
  final TextEditingController urlController;
  final FocusNode urlFocusNode;
  final bool urlFieldFocused;
  final Set<String> definedEnvKeys;
  final bool showClearButton;
  final ValueChanged<String> onUrlChanged;
  final String? hintText;
  final VoidCallback? onClear;
  final ValueChanged<UrlVariableTemplateSpan>? onClosedTemplateDoubleTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barFill = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final unfocusedOutline = scheme.outline.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.28,
    );
    final borderColor = urlFieldFocused
        ? scheme.primary.withValues(alpha: 0.85)
        : unfocusedOutline;
    final borderWidth = urlFieldFocused ? 1.25 : 1.0;

    return SizedBox(
      height: kWebChromeSingleLineFieldHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: barFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WebMethodPrefixMenu(
                method: method,
                onChanged: onMethodChanged,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 8,
                endIndent: 8,
                color: scheme.outline.withValues(alpha: 0.32),
              ),
              Expanded(
                child: WebRequestUrlField(
                  controller: urlController,
                  focusNode: urlFocusNode,
                  onChanged: onUrlChanged,
                  definedEnvKeys: definedEnvKeys,
                  embeddedInComposite: true,
                  hintText: hintText,
                  showClearButton: showClearButton,
                  onClear: onClear,
                  borderColor: Colors.transparent,
                  focusedBorderColor: Colors.transparent,
                  fillColor: barFill,
                  onClosedTemplateDoubleTap: onClosedTemplateDoubleTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebMethodPrefixMenu extends StatefulWidget {
  const _WebMethodPrefixMenu({
    required this.method,
    required this.onChanged,
  });

  final HttpMethod method;
  final ValueChanged<HttpMethod> onChanged;

  @override
  State<_WebMethodPrefixMenu> createState() => _WebMethodPrefixMenuState();
}

class _WebMethodPrefixMenuState extends State<_WebMethodPrefixMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  double? _anchorWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureAnchor);
  }

  @override
  void didUpdateWidget(covariant _WebMethodPrefixMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.method != widget.method) {
      WidgetsBinding.instance.addPostFrameCallback(_measureAnchor);
    }
  }

  void _measureAnchor([Duration? _]) {
    final ctx = _anchorKey.currentContext;
    if (ctx == null || !mounted) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final w = box.size.width;
    if (_anchorWidth != w) {
      setState(() => _anchorWidth = w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors.methodColor(widget.method.value);
    final w = _anchorWidth;

    return MenuAnchor(
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        minimumSize: w != null
            ? WidgetStatePropertyAll(Size(w, 0))
            : null,
        maximumSize: w != null
            ? WidgetStatePropertyAll(Size(w, double.infinity))
            : null,
      ),
      menuChildren: [
        for (final m in HttpMethod.values)
          MenuItemButton(
            onPressed: () => widget.onChanged(m),
            style: MenuItemButton.styleFrom(
              minimumSize: w != null ? Size(w, 36) : null,
              padding: EdgeInsets.zero,
            ),
            child: Center(
              child: Text(
                m.value,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: AppColors.methodColor(m.value),
                ),
              ),
            ),
          ),
      ],
      builder: (context, menuController, _) {
        return KeyedSubtree(
          key: _anchorKey,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                  WidgetsBinding.instance.addPostFrameCallback(_measureAnchor);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 52),
                      child: Text(
                        widget.method.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
