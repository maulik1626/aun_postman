import 'package:aun_reqstudio/app/theme/app_colors.dart';
import 'package:aun_reqstudio/app/router/app_routes.dart';
import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/core/widgets/banner_ad_tile.dart';
import 'package:aun_reqstudio/domain/models/history_entry.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/ad_session_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

NativeListAdTile _nativeAdTileMaterial(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final chrome = scheme.surfaceContainerLow;
  final border = scheme.outlineVariant;
  final label = scheme.onSurface.withValues(alpha: 0.62);

  return NativeListAdTile(
    appearanceKey: scheme.brightness,
    chromeColor: chrome,
    borderColor: border,
    labelColor: label,
    height: 340,
    templateStyle: NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: chrome,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface,
        size: 15,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.72),
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface.withValues(alpha: 0.56),
        size: 11,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        size: 13,
        style: NativeTemplateFontStyle.bold,
      ),
    ),
  );
}

class HistoryScreenMaterial extends ConsumerStatefulWidget {
  const HistoryScreenMaterial({super.key});

  @override
  ConsumerState<HistoryScreenMaterial> createState() =>
      _HistoryScreenMaterialState();
}

class _HistoryScreenMaterialState extends ConsumerState<HistoryScreenMaterial> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final settings = ref.watch(appSettingsProvider);
    final adSession = ref.watch(adSessionProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    final filtered = _query.isEmpty
        ? history
        : history.where((e) {
            final q = _query.toLowerCase();
            return e.request.url.toLowerCase().contains(q) ||
                e.request.method.value.toLowerCase().contains(q) ||
                e.response.statusCode.toString().contains(q);
          }).toList();

    final groups = _groupByDate(filtered);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.collections);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          automaticallyImplyLeading: false,
          actions: [
            if (history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear All',
                onPressed: () => _confirmClearAll(context),
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
          if (history.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by URL, method, status',
                    prefixIcon: Icon(Icons.search_outlined, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
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
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.history_outlined,
                              size: 40,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No History',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send requests to see them here',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (AppConstants.enableAds &&
                      !adSession.browseAdsDisabledByReward &&
                      AdConfig.emptyStateBottomBanners.history)
                    const BottomBannerAdSection(),
                ],
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.search_outlined,
                        size: 40,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No results for "$_query"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different URL, method, or status code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: secondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
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
                        color: secondary,
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
                      Divider(
                        height: 0.5,
                        indent: 16,
                        color: Theme.of(context).dividerColor,
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
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline,
                            spacing: 2,
                            label: 'Delete',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          final colUid =
                              entry.request.collectionUid ?? 'history';
                          context.push(
                            '/collections/$colUid/request/${entry.request.uid}',
                            extra: entry,
                          );
                        },
                        child: Padding(
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
                                  color: methodColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                      color: secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (AppConstants.enableAds &&
                        !adSession.browseAdsDisabledByReward &&
                        AdConfig.history.shouldInsertAfterOrdinal(
                          entryOrdinal,
                          overrideEvery: settings.historyAdInterval,
                        ))
                      _nativeAdTileMaterial(context),
                  ],
                );
              }, childCount: _flatHistoryCount(groups)),
            ),
          ],
        ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will delete all request history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
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
