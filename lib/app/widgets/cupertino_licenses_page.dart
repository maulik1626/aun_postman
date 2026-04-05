import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Cupertino equivalent of Material [showLicensePage] — no `material.dart`.
void showCupertinoLicensePage(BuildContext context) {
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (context) => const CupertinoLicensesPage(),
    ),
  );
}

class CupertinoLicensesPage extends StatefulWidget {
  const CupertinoLicensesPage({super.key});

  @override
  State<CupertinoLicensesPage> createState() => _CupertinoLicensesPageState();
}

class _CupertinoLicensesPageState extends State<CupertinoLicensesPage> {
  final List<LicenseEntry> _entries = [];
  bool _loaded = false;
  StreamSubscription<LicenseEntry>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = LicenseRegistry.licenses.listen(
      (entry) {
        if (mounted) {
          setState(() => _entries.add(entry));
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _loaded = true);
        }
      },
      onError: (_, __) {
        if (mounted) {
          setState(() => _loaded = true);
        }
      },
    );
  }

  @override
  void dispose() {
    final sub = _sub;
    _sub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Open Source Licenses'),
          ),
          if (!_loaded && _entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _LicenseEntryTile(
                          entry: entry,
                          labelColor: labelColor,
                          secondary: secondary,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: bottomInset + 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LicenseEntryTile extends StatelessWidget {
  const _LicenseEntryTile({
    required this.entry,
    required this.labelColor,
    required this.secondary,
  });

  final LicenseEntry entry;
  final Color labelColor;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final packages = entry.packages.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            packages,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          ...entry.paragraphs.map(
            (p) => _LicenseParagraphLine(
              paragraph: p,
              baseColor: secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseParagraphLine extends StatelessWidget {
  const _LicenseParagraphLine({
    required this.paragraph,
    required this.baseColor,
  });

  final LicenseParagraph paragraph;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    const unit = 12.0;
    final indent = paragraph.indent;

    if (indent == LicenseParagraph.centeredIndent) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          paragraph.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: baseColor, height: 1.35),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: unit * indent, top: 2, bottom: 2),
      child: Text(
        paragraph.text,
        style: TextStyle(fontSize: 13, color: baseColor, height: 1.35),
      ),
    );
  }
}
