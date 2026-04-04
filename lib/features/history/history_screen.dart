import 'package:aun_postman/app/theme/app_colors.dart';
import 'package:aun_postman/features/history/providers/history_provider.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('History'),
            trailing: history.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: () => _confirmClearAll(context),
                    child: const Icon(CupertinoIcons.trash),
                  )
                : null,
          ),

          // Search bar
          if (history.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSearchTextField(
                  placeholder: 'Search by URL, method, status',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

          // Empty state
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 56,
                      color: CupertinoTheme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No History',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send requests to see them here',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            )

          // No results from search
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.search,
                        size: 48,
                        color: CupertinoColors.tertiaryLabel
                            .resolveFrom(context)),
                    const SizedBox(height: 12),
                    Text(
                      'No results for "$_query"',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            )

          // Grouped list
          else
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    group.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: group.entries.length,
                separatorBuilder: (_, __) => Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 16),
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                itemBuilder: (context, index) {
                  final entry = group.entries[index];
                  final statusColor =
                      AppColors.statusColor(entry.response.statusCode);
                  final methodColor =
                      AppColors.methodColor(entry.request.method.value);

                  return Slidable(
                    key: ValueKey(entry.uid),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.22,
                      children: [
                        SlidableAction(
                          onPressed: (_) => ref
                              .read(historyProvider.notifier)
                              .delete(entry.uid),
                          backgroundColor: CupertinoColors.destructiveRed,
                          foregroundColor: CupertinoColors.white,
                          icon: CupertinoIcons.trash,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(requestBuilderProvider.notifier)
                            .loadFromRequest(entry.request);
                        final colUid =
                            entry.request.collectionUid ?? 'history';
                        context.push(
                            '/collections/$colUid/request/${entry.request.uid}');
                      },
                      child: Container(
                        color: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Method badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
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
                                    DateFormat('HH:mm')
                                        .format(entry.executedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
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
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<_HistoryGroup> _groupByDate(List<dynamic> entries) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month);

    final todayList = [];
    final yesterdayList = [];
    final thisWeekList = [];
    final thisMonthList = [];
    final olderList = [];

    for (final e in entries) {
      final d = DateTime(
          e.executedAt.year, e.executedAt.month, e.executedAt.day);
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
      if (todayList.isNotEmpty)
        _HistoryGroup('TODAY', todayList.cast()),
      if (yesterdayList.isNotEmpty)
        _HistoryGroup('YESTERDAY', yesterdayList.cast()),
      if (thisWeekList.isNotEmpty)
        _HistoryGroup('THIS WEEK', thisWeekList.cast()),
      if (thisMonthList.isNotEmpty)
        _HistoryGroup('THIS MONTH', thisMonthList.cast()),
      if (olderList.isNotEmpty)
        _HistoryGroup('OLDER', olderList.cast()),
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
  final List entries;
}
