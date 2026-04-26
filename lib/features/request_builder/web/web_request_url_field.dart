import 'package:aun_reqstudio/app/web/web_chrome_layout.dart';
import 'package:aun_reqstudio/features/request_builder/web/url_template_range.dart';
import 'package:flutter/material.dart';

/// Right gutter on the highlight layer so spans do not paint under the clear
/// control. Do **not** mirror this as [InputDecoration.contentPadding].right when
/// [suffixIcon] is set — [InputDecorator] already excludes the suffix slot, and an
/// extra right inset leaves empty scroll width so the caret sits past the glyphs.
const double kWebRequestUrlFieldTrailingClearGutter = 44;
const double _kWebRequestUrlFieldClearSlotWidth = 32;
const double _kWebRequestUrlFieldTextSlotHeight = 22;

/// Base text metrics for the editable and overlay (must stay in sync for caret).
TextStyle webRequestUrlFieldBaseTextStyle(Color onSurface) => TextStyle(
  color: onSurface,
  fontFamily: 'JetBrainsMono',
  fontSize: 12.5,
  height: 1.2,
);

StrutStyle webRequestUrlFieldStrutStyle() => const StrutStyle(
  fontSize: 12.5,
  fontFamily: 'JetBrainsMono',
  height: 1.2,
  forceStrutHeight: true,
);

@visibleForTesting
TextSpan buildWebRequestUrlFieldOverlaySpanForTest({
  required String text,
  required ColorScheme scheme,
  required Set<String> definedEnvKeys,
}) {
  return _buildUrlSpan(
    text: text,
    baseStyle: webRequestUrlFieldBaseTextStyle(scheme.onSurface),
    scheme: scheme,
    definedKeys: definedEnvKeys,
  );
}

/// Single-line URL field with `{{variable}}` highlighting for the web workspace.
class WebRequestUrlField extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  WebRequestUrlField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.definedEnvKeys,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.fillColor,
    this.fieldHeight,
    this.embeddedInComposite = false,
    this.hintText,
    this.showClearButton = false,
    this.onClear,
    this.onClosedTemplateDoubleTap,
  }) : assert(
         (embeddedInComposite && fieldHeight == null) ||
             (!embeddedInComposite && fieldHeight != null),
       );

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Set<String> definedEnvKeys;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color fillColor;
  final double? fieldHeight;
  final bool embeddedInComposite;
  final String? hintText;
  final bool showClearButton;
  final VoidCallback? onClear;
  final ValueChanged<UrlVariableTemplateSpan>? onClosedTemplateDoubleTap;

  @override
  State<WebRequestUrlField> createState() => _WebRequestUrlFieldState();
}

class _WebRequestUrlFieldState extends State<WebRequestUrlField> {
  final GlobalKey _fieldBoxKey = GlobalKey(debugLabel: 'web_request_url_field');
  late final ScrollController _scrollController;
  late final _WebUrlHighlightingTextEditingController _fieldController;
  bool _syncingControllers = false;
  DateTime? _prevTapTime;
  Offset? _prevTapGlobal;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fieldController = _WebUrlHighlightingTextEditingController(
      value: widget.controller.value,
      definedEnvKeys: widget.definedEnvKeys,
    )..addListener(_onFieldControllerChanged);
    widget.controller.addListener(_onTextOrSelection);
    widget.focusNode.addListener(_onFocus);
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _onTextOrSelection() {
    if (!_syncingControllers &&
        _fieldController.value != widget.controller.value) {
      _syncingControllers = true;
      _fieldController.value = widget.controller.value;
      _syncingControllers = false;
    }
    if (mounted) setState(() {});
  }

  void _onFieldControllerChanged() {
    if (!_syncingControllers &&
        widget.controller.value != _fieldController.value) {
      _syncingControllers = true;
      widget.controller.value = _fieldController.value;
      _syncingControllers = false;
    }
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _handlePointerDown(PointerDownEvent e) {
    final cb = widget.onClosedTemplateDoubleTap;
    if (cb == null) return;

    final now = DateTime.now();
    final pos = e.position;
    if (_prevTapTime != null &&
        _prevTapGlobal != null &&
        now.difference(_prevTapTime!) < const Duration(milliseconds: 450) &&
        (pos - _prevTapGlobal!).distance < 24) {
      _prevTapTime = null;
      _prevTapGlobal = null;
      _emitClosedTemplateDoubleTap(pos, cb);
    } else {
      _prevTapTime = now;
      _prevTapGlobal = pos;
    }
  }

  void _emitClosedTemplateDoubleTap(
    Offset global,
    void Function(UrlVariableTemplateSpan span) cb,
  ) {
    final text = widget.controller.text;
    if (text.isEmpty || !mounted) return;

    final boxContext = _fieldBoxKey.currentContext;
    final ro = boxContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;

    final local = ro.globalToLocal(global);
    final rightGutter = widget.showClearButton
        ? kWebRequestUrlFieldTrailingClearGutter
        : 10.0;
    const leftPad = 10.0;
    if (local.dx < leftPad || local.dx > ro.size.width - rightGutter) return;

    final innerW = (ro.size.width - leftPad - rightGutter).clamp(1.0, 1e9);
    final scrollDx = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final dx = (local.dx - leftPad + scrollDx).clamp(0.0, double.infinity);

    final scheme = Theme.of(context).colorScheme;
    final baseStyle = webRequestUrlFieldBaseTextStyle(scheme.onSurface);
    final tp = TextPainter(
      text: TextSpan(text: text, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerW);
    final yMid = ro.size.height / 2;
    var charOffset = tp.getPositionForOffset(Offset(dx, yMid)).offset;
    charOffset = charOffset.clamp(0, text.length);
    final span = closedTemplateSpanAtTextOffset(text, charOffset);
    if (span == null) return;
    cb(span);
  }

  Widget _wrapPointerListener(Widget child) {
    if (widget.onClosedTemplateDoubleTap == null) return child;
    return Listener(
      key: _fieldBoxKey,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }

  @override
  void didUpdateWidget(covariant WebRequestUrlField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextOrSelection);
      widget.controller.addListener(_onTextOrSelection);
      if (_fieldController.value != widget.controller.value) {
        _fieldController.value = widget.controller.value;
      }
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
    if (oldWidget.definedEnvKeys != widget.definedEnvKeys) {
      _fieldController.definedEnvKeys = widget.definedEnvKeys;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextOrSelection);
    widget.focusNode.removeListener(_onFocus);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fieldController
      ..removeListener(_onFieldControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInComposite) {
      return LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight.isFinite && c.maxHeight > 0
              ? c.maxHeight
              : kWebChromeSingleLineFieldHeight;
          return SizedBox(
            height: h,
            width: c.maxWidth.isFinite ? c.maxWidth : null,
            child: _wrapPointerListener(_buildFieldStack(context)),
          );
        },
      );
    }
    return SizedBox(
      height: widget.fieldHeight!,
      child: _buildStandaloneChrome(context),
    );
  }

  Widget _buildStandaloneChrome(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fieldFill =
        Color.lerp(
          widget.fillColor,
          scheme.outlineVariant,
          scheme.brightness == Brightness.dark ? 0.22 : 0.12,
        ) ??
        widget.fillColor;
    final unfocusedBorder =
        Color.lerp(
          scheme.outline,
          fieldFill,
          scheme.brightness == Brightness.dark ? 0.15 : 0.35,
        ) ??
        scheme.outline;
    final focused = widget.focusNode.hasFocus;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fieldFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? widget.focusedBorderColor : unfocusedBorder,
          width: focused ? 1.5 : 1.25,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _wrapPointerListener(_buildFieldStack(context)),
      ),
    );
  }

  Widget _buildFieldStack(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;
    final baseStyle = webRequestUrlFieldBaseTextStyle(scheme.onSurface);
    final rightContentPad = widget.showClearButton
        ? _kWebRequestUrlFieldClearSlotWidth + 4
        : 10.0;
    final hint = widget.hintText;
    final showHint = hint != null && text.isEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showHint)
          IgnorePointer(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 0, rightContentPad, 0),
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: double.infinity,
            height: _kWebRequestUrlFieldTextSlotHeight,
            child: TextField(
              controller: _fieldController,
              focusNode: widget.focusNode,
              scrollController: _scrollController,
              scrollPhysics: const ClampingScrollPhysics(),
              style: baseStyle,
              cursorColor: scheme.primary,
              strutStyle: webRequestUrlFieldStrutStyle(),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: true,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(10, 0, rightContentPad, 0),
              ),
              maxLines: 1,
              onChanged: widget.onChanged,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
        if (widget.showClearButton)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: _kWebRequestUrlFieldClearSlotWidth,
              height: _kWebRequestUrlFieldClearSlotWidth,
              child: IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: widget.onClear,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ),
          ),
      ],
    );
  }
}

class _WebUrlHighlightingTextEditingController extends TextEditingController {
  _WebUrlHighlightingTextEditingController({
    required TextEditingValue value,
    required Set<String> definedEnvKeys,
  }) : _definedEnvKeys = definedEnvKeys,
       super.fromValue(value);

  Set<String> _definedEnvKeys;

  set definedEnvKeys(Set<String> value) {
    if (_definedEnvKeys == value) return;
    _definedEnvKeys = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle =
        (style ?? webRequestUrlFieldBaseTextStyle(scheme.onSurface)).copyWith(
          color: scheme.onSurface,
        );
    return _buildUrlSpan(
      text: text,
      baseStyle: baseStyle,
      scheme: scheme,
      definedKeys: _definedEnvKeys,
    );
  }
}

TextSpan _buildUrlSpan({
  required String text,
  required TextStyle baseStyle,
  required ColorScheme scheme,
  required Set<String> definedKeys,
}) {
  final braceStyle = baseStyle.copyWith(
    color: scheme.primary.withValues(alpha: 0.55),
  );
  TextStyle nameStyle(String rawName) {
    final name = rawName.trim();
    final defined = name.isNotEmpty && definedKeys.contains(name);
    return baseStyle.copyWith(
      color: defined ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
    );
  }

  final children = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final open = text.indexOf('{{', i);
    if (open == -1) {
      children.add(TextSpan(text: text.substring(i), style: baseStyle));
      break;
    }
    if (open > i) {
      children.add(TextSpan(text: text.substring(i, open), style: baseStyle));
    }
    final innerStart = open + 2;
    final close = text.indexOf('}}', innerStart);
    children.add(TextSpan(text: '{{', style: braceStyle));
    if (close == -1) {
      children.add(
        TextSpan(
          text: text.substring(innerStart),
          style: nameStyle(text.substring(innerStart)),
        ),
      );
      break;
    }
    final inner = text.substring(innerStart, close);
    children.add(TextSpan(text: inner, style: nameStyle(inner)));
    children.add(TextSpan(text: '}}', style: braceStyle));
    i = close + 2;
  }

  return TextSpan(style: baseStyle, children: children);
}
