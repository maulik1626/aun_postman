import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/widgets/banner_ad_tile.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

NativeListAdTile _nativeAdTileCupertino(BuildContext context) {
  final chrome = CupertinoDynamicColor.resolve(
    CupertinoColors.secondarySystemBackground,
    context,
  );
  final border = CupertinoDynamicColor.resolve(
    CupertinoColors.separator,
    context,
  );
  final label = CupertinoDynamicColor.resolve(
    CupertinoColors.secondaryLabel,
    context,
  );
  final text = CupertinoDynamicColor.resolve(CupertinoColors.label, context);
  final muted = CupertinoDynamicColor.resolve(
    CupertinoColors.secondaryLabel,
    context,
  );
  final tertiary = CupertinoDynamicColor.resolve(
    CupertinoColors.tertiaryLabel,
    context,
  );
  final cta = CupertinoTheme.of(context).primaryColor;

  return NativeListAdTile(
    appearanceKey: CupertinoTheme.brightnessOf(context),
    chromeColor: chrome,
    borderColor: border,
    labelColor: label,
    height: 340,
    templateStyle: NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: chrome,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: text,
        size: 15,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(textColor: muted, size: 13),
      tertiaryTextStyle: NativeTemplateTextStyle(textColor: tertiary, size: 11),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: CupertinoColors.white,
        backgroundColor: cta,
        size: 13,
        style: NativeTemplateFontStyle.bold,
      ),
    ),
  );
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);

    // Filter by search query
    final filtered = _query.isEmpty
        ? history
        : history.where((e) {
            final q = _query.toLowerCase();
            return e.request.url.toLowerCase().contains(q) ||
                e.request.method.value.toLowerCase().contains(q) ||
                e.response.statusCode.toString().contains(q);
          }).toList();

    // Group into date buckets
    final groups = _groupByDate(filtered);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('History'),
            trailing: history.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _confirmClearAll(context),
                    minimumSize: Size(44, 44),
                    child: const Icon(CupertinoIcons.trash),
                  )
                : null,
          ),

          if (history.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: CupertinoSearchTextField(
                  placeholder: 'Search by URL, method, status',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: CupertinoTheme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              CupertinoIcons.clock,
                              size: 40,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No History',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send requests to see them here',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!adSession.browseAdsDisabledByReward &&
                      AdConfig.emptyStateBottomBanners.history)
                    const BottomBannerAdSection(),
                  SizedBox(height: bottomInset + 8),
                ],
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: CupertinoTheme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              CupertinoIcons.search,
                              size: 40,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No results for "$_query"',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different URL, method, or status code',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset + 8),
                ],
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _flatHistoryCount(groups),
                      itemBuilder: (context, index) {
                        final row = _flatHistoryRow(groups, index);
                        if (row.isHeader) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              index == 0 ? 8 : 16,
                              16,
                              6,
                            ),
                            child: Text(
                              row.sectionLabel!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          );
                        }
                        final entry = row.entry!;
                        final statusColor = AppColors.statusColor(
                          entry.response.statusCode,
                        );
                        final methodColor = AppColors.methodColor(
                          entry.request.method.value,
                        );
                        final isFirstInSection = _isFirstEntryAfterHeader(
                          groups,
                          index,
                        );
                        final entryOrdinal = _entryOrdinalAt(groups, index);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isFirstInSection)
                              Container(
                                height: 0.5,
                                margin: const EdgeInsets.only(left: 16),
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                              ),
                            Slidable(
                              key: ValueKey(entry.uid),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.28,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => ref
                                        .read(historyProvider.notifier)
                                        .delete(entry.uid),
                                    backgroundColor:
                                        CupertinoColors.destructiveRed,
                                    foregroundColor: CupertinoColors.white,
                                    icon: CupertinoIcons.trash,
                                    spacing: 2,
                                    label: 'Delete',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  final colUid =
                                      entry.request.collectionUid ?? 'history';
                                  context.push(
                                    '/collections/$colUid/request/${entry.request.uid}',
                                    extra: entry,
                                  );
                                },
                                child: Container(
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: methodColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          entry.request.method.value,
                                          style: TextStyle(
                                            color: methodColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.request.url,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'JetBrainsMono',
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat(
                                                'HH:mm',
                                              ).format(entry.executedAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: CupertinoColors
                                                    .secondaryLabel
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${entry.response.statusCode}',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'JetBrainsMono',
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${entry.response.durationMs}ms',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: CupertinoColors
                                                  .secondaryLabel
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!adSession.browseAdsDisabledByReward &&
                                AdConfig.history.shouldInsertAfterOrdinal(
                                  entryOrdinal,
                                  overrideEvery: settings.historyAdInterval,
                                ))
                              _nativeAdTileCupertino(context),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: bottomInset + 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _flatHistoryCount(List<_HistoryGroup> groups) {
    var n = 0;
    for (final g in groups) {
      n += 1 + g.entries.length;
    }
    return n;
  }

  ({bool isHeader, String? sectionLabel, HistoryEntry? entry}) _flatHistoryRow(
    List<_HistoryGroup> groups,
    int index,
  ) {
    var i = 0;
    for (final g in groups) {
      if (i == index) {
        return (isHeader: true, sectionLabel: g.label, entry: null);
      }
      i++;
      for (final e in g.entries) {
        if (i == index) {
          return (isHeader: false, sectionLabel: null, entry: e);
        }
        i++;
      }
    }
    throw StateError('history flat index out of range');
  }

  bool _isFirstEntryAfterHeader(List<_HistoryGroup> groups, int index) {
    if (index == 0) return true;
    final prev = _flatHistoryRow(groups, index - 1);
    return prev.isHeader;
  }

  int _entryOrdinalAt(List<_HistoryGroup> groups, int index) {
    var ordinal = 0;
    for (var i = 0; i <= index; i++) {
      final row = _flatHistoryRow(groups, i);
      if (!row.isHeader) {
        ordinal++;
      }
    }
    return ordinal;
  }

  List<_HistoryGroup> _groupByDate(List<HistoryEntry> entries) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month);

    final todayList = <HistoryEntry>[];
    final yesterdayList = <HistoryEntry>[];
    final thisWeekList = <HistoryEntry>[];
    final thisMonthList = <HistoryEntry>[];
    final olderList = <HistoryEntry>[];

    for (final e in entries) {
      final d = DateTime(
        e.executedAt.year,
        e.executedAt.month,
        e.executedAt.day,
      );
      if (d == today) {
        todayList.add(e);
      } else if (d == yesterday) {
        yesterdayList.add(e);
      } else if (!d.isBefore(thisWeekStart)) {
        thisWeekList.add(e);
      } else if (!d.isBefore(thisMonthStart)) {
        thisMonthList.add(e);
      } else {
        olderList.add(e);
      }
    }

    return [
      if (todayList.isNotEmpty) _HistoryGroup('TODAY', todayList),
      if (yesterdayList.isNotEmpty) _HistoryGroup('YESTERDAY', yesterdayList),
      if (thisWeekList.isNotEmpty) _HistoryGroup('THIS WEEK', thisWeekList),
      if (thisMonthList.isNotEmpty) _HistoryGroup('THIS MONTH', thisMonthList),
      if (olderList.isNotEmpty) _HistoryGroup('OLDER', olderList),
    ];
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will delete all request history.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAll();
    }
  }
}

class _HistoryGroup {
  const _HistoryGroup(this.label, this.entries);
  final String label;
  final List<HistoryEntry> entries;
}
