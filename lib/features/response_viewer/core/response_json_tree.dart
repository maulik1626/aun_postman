import 'package:aun_reqstudio/features/response_viewer/core/response_viewer_models.dart';

enum ResponseJsonValueKind { object, array, string, number, boolean, nil }

class ResponseJsonTreeNode {
  const ResponseJsonTreeNode({
    required this.id,
    required this.depth,
    required this.kind,
    this.key,
    this.valueText,
    this.children = const <ResponseJsonTreeNode>[],
  });

  final String id;
  final int depth;
  final ResponseJsonValueKind kind;
  final String? key;
  final String? valueText;
  final List<ResponseJsonTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
  int get childCount => children.length;

  String get summaryText {
    switch (kind) {
      case ResponseJsonValueKind.object:
        return childCount == 1 ? '{1 item}' : '{$childCount items}';
      case ResponseJsonValueKind.array:
        return childCount == 1 ? '[1 item]' : '[$childCount items]';
      case ResponseJsonValueKind.string:
        return '"${valueText ?? ''}"';
      case ResponseJsonValueKind.number:
      case ResponseJsonValueKind.boolean:
        return valueText ?? '';
      case ResponseJsonValueKind.nil:
        return 'null';
    }
  }
}

class ResponseJsonTreeEntry {
  const ResponseJsonTreeEntry({
    required this.nodeId,
    required this.depth,
    required this.kind,
    required this.label,
    required this.valueText,
    required this.searchText,
    required this.hasChildren,
    required this.isExpanded,
  });

  final String nodeId;
  final int depth;
  final ResponseJsonValueKind kind;
  final String? label;
  final String valueText;
  final String searchText;
  final bool hasChildren;
  final bool isExpanded;
}

class ResponseJsonTreePresentation {
  const ResponseJsonTreePresentation({
    required this.entries,
    required this.matches,
  });

  final List<ResponseJsonTreeEntry> entries;
  final List<SearchMatch> matches;
}

ResponseJsonTreeNode buildResponseJsonTree(
  Object? value, {
  String id = r'$',
  int depth = 0,
  String? key,
}) {
  if (value is Map) {
    final children = <ResponseJsonTreeNode>[];
    value.forEach((entryKey, entryValue) {
      final childKey = entryKey.toString();
      children.add(
        buildResponseJsonTree(
          entryValue,
          id: '$id.$childKey',
          depth: depth + 1,
          key: childKey,
        ),
      );
    });
    return ResponseJsonTreeNode(
      id: id,
      depth: depth,
      key: key,
      kind: ResponseJsonValueKind.object,
      children: List<ResponseJsonTreeNode>.unmodifiable(children),
    );
  }

  if (value is List) {
    final children = <ResponseJsonTreeNode>[];
    for (var i = 0; i < value.length; i++) {
      children.add(
        buildResponseJsonTree(
          value[i],
          id: '$id[$i]',
          depth: depth + 1,
          key: '[$i]',
        ),
      );
    }
    return ResponseJsonTreeNode(
      id: id,
      depth: depth,
      key: key,
      kind: ResponseJsonValueKind.array,
      children: List<ResponseJsonTreeNode>.unmodifiable(children),
    );
  }

  if (value is String) {
    return ResponseJsonTreeNode(
      id: id,
      depth: depth,
      key: key,
      kind: ResponseJsonValueKind.string,
      valueText: value,
    );
  }

  if (value is bool) {
    return ResponseJsonTreeNode(
      id: id,
      depth: depth,
      key: key,
      kind: ResponseJsonValueKind.boolean,
      valueText: value ? 'true' : 'false',
    );
  }

  if (value == null) {
    return ResponseJsonTreeNode(
      id: id,
      depth: depth,
      key: key,
      kind: ResponseJsonValueKind.nil,
      valueText: 'null',
    );
  }

  return ResponseJsonTreeNode(
    id: id,
    depth: depth,
    key: key,
    kind: ResponseJsonValueKind.number,
    valueText: value.toString(),
  );
}

ResponseJsonTreePresentation buildResponseJsonTreePresentation({
  required ResponseJsonTreeNode root,
  required Map<String, bool> expansionOverrides,
  required String query,
  int defaultExpandedDepth = 1,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final forcedExpanded = <String>{};

  bool collectForcedExpansion(ResponseJsonTreeNode node) {
    final selfMatches = _nodeSearchText(node).contains(normalizedQuery);
    var descendantMatches = false;
    for (final child in node.children) {
      if (collectForcedExpansion(child)) {
        descendantMatches = true;
      }
    }
    if (normalizedQuery.isNotEmpty && descendantMatches) {
      forcedExpanded.add(node.id);
    }
    return selfMatches || descendantMatches;
  }

  if (normalizedQuery.isNotEmpty) {
    collectForcedExpansion(root);
  }

  final entries = <ResponseJsonTreeEntry>[];
  final matches = <SearchMatch>[];

  bool isExpanded(ResponseJsonTreeNode node) {
    if (!node.hasChildren) return false;
    if (node.id == root.id) return true;
    if (forcedExpanded.contains(node.id)) return true;
    final override = expansionOverrides[node.id];
    if (override != null) return override;
    return node.depth <= defaultExpandedDepth;
  }

  void walk(ResponseJsonTreeNode node) {
    final expanded = isExpanded(node);
    final entry = ResponseJsonTreeEntry(
      nodeId: node.id,
      depth: node.depth,
      kind: node.kind,
      label: node.key,
      valueText: node.summaryText,
      searchText: _nodeSearchText(node),
      hasChildren: node.hasChildren,
      isExpanded: expanded,
    );
    final lineIndex = entries.length;
    entries.add(entry);

    if (normalizedQuery.isNotEmpty) {
      final matchStart = entry.searchText.toLowerCase().indexOf(
        normalizedQuery,
      );
      if (matchStart >= 0) {
        matches.add(SearchMatch(lineIndex: lineIndex, start: matchStart));
      }
    }

    if (expanded) {
      for (final child in node.children) {
        walk(child);
      }
    }
  }

  walk(root);

  return ResponseJsonTreePresentation(
    entries: List<ResponseJsonTreeEntry>.unmodifiable(entries),
    matches: List<SearchMatch>.unmodifiable(matches),
  );
}

String _nodeSearchText(ResponseJsonTreeNode node) {
  final label = node.key == null ? '' : '${node.key}: ';
  return '$label${node.summaryText}';
}
