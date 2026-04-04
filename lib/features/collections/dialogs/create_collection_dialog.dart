import 'package:flutter/cupertino.dart';

class CreateCollectionDialog extends StatefulWidget {
  const CreateCollectionDialog({super.key, this.initialName});
  final String? initialName;

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  late final TextEditingController _nameController;
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        widget.initialName != null ? 'Rename Collection' : 'New Collection',
      ),
      content: Column(
        children: [
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Collection name',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          CupertinoTextField(
            controller: _descController,
            placeholder: 'Description (optional)',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final desc = _descController.text.trim();
              Navigator.pop(context, (name, desc.isEmpty ? null : desc));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
