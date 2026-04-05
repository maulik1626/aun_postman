import 'package:aun_postman/app/widgets/auth_config_editor.dart';
import 'package:aun_postman/features/request_builder/providers/request_builder_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthTab extends ConsumerWidget {
  const AuthTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(requestBuilderProvider.select((s) => s.auth));

    return SingleChildScrollView(
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: AuthConfigEditor(
        auth: auth,
        onChanged: (a) =>
            ref.read(requestBuilderProvider.notifier).setAuth(a),
      ),
    );
  }
}
