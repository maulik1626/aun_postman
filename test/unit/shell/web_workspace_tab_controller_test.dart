import 'package:aun_reqstudio/features/shell/web_workspace_tab_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebWorkspaceTabController', () {
    test(
      'opens saved request once and focuses existing tab on repeated open',
      () {
        final controller = WebWorkspaceTabController();
        addTearDown(controller.dispose);

        controller.openSavedRequest(
          collectionUid: 'collection-1',
          requestUid: 'request-1',
          title: 'Get Users',
        );
        controller.openSavedRequest(
          collectionUid: 'collection-1',
          requestUid: 'request-1',
          title: 'Get Users',
        );

        expect(controller.tabs, hasLength(1));
        expect(controller.activeTabId, 'collection-1:request-1');
        expect(controller.activeTab?.title, 'Get Users');
      },
    );

    test('opens multiple new request tabs independently', () {
      final controller = WebWorkspaceTabController();
      addTearDown(controller.dispose);

      controller.openNewRequest(collectionUid: 'collection-1', timestamp: 1);
      controller.openNewRequest(collectionUid: 'collection-1', timestamp: 2);

      expect(controller.tabs, hasLength(2));
      expect(controller.tabs[0].id, isNot(controller.tabs[1].id));
      expect(controller.activeTabId, controller.tabs[1].id);
      expect(controller.tabs.every((tab) => tab.isNewUnsaved), isTrue);
    });

    test('closes active tab and selects neighbor predictably', () {
      final controller = WebWorkspaceTabController();
      addTearDown(controller.dispose);

      controller.openSavedRequest(
        collectionUid: 'collection-1',
        requestUid: 'request-1',
        title: 'One',
      );
      controller.openSavedRequest(
        collectionUid: 'collection-1',
        requestUid: 'request-2',
        title: 'Two',
      );
      controller.openSavedRequest(
        collectionUid: 'collection-1',
        requestUid: 'request-3',
        title: 'Three',
      );

      controller.closeTab('collection-1:request-2');

      expect(controller.tabs.map((tab) => tab.id), [
        'collection-1:request-1',
        'collection-1:request-3',
      ]);
      expect(controller.activeTabId, 'collection-1:request-3');
    });

    test('blocks risky close until confirmation path is accepted', () {
      final controller = WebWorkspaceTabController();
      addTearDown(controller.dispose);

      controller.openSavedRequest(
        collectionUid: 'collection-1',
        requestUid: 'request-1',
        title: 'Get Users',
      );
      final tabId = controller.activeTabId!;

      expect(controller.requestCloseTab(tabId), isTrue);

      controller.reportTabStatus(
        tabId: tabId,
        title: 'Get Users',
        isDirty: true,
        isSending: false,
        hasResponse: false,
        requestUid: 'request-1',
      );

      expect(controller.requestCloseTab(tabId), isFalse);

      controller.closeTab(tabId);

      expect(controller.tabs, isEmpty);
      expect(controller.activeTabId, isNull);
    });

    test('focuses a saved request that originated as a new tab after save', () {
      final controller = WebWorkspaceTabController();
      addTearDown(controller.dispose);

      controller.openNewRequest(collectionUid: 'collection-1', timestamp: 1);
      final newTabId = controller.activeTabId!;
      controller.reportTabStatus(
        tabId: newTabId,
        title: 'Saved Later',
        isDirty: false,
        isSending: false,
        hasResponse: false,
        requestUid: 'request-1',
      );

      controller.openSavedRequest(
        collectionUid: 'collection-1',
        requestUid: 'request-1',
        title: 'Saved Later',
      );

      expect(controller.tabs, hasLength(1));
      expect(controller.activeTabId, newTabId);
      expect(controller.activeTab?.requestUid, 'request-1');
    });
  });
}
