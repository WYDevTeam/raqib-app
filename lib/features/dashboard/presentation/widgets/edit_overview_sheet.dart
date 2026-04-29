import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class EditOverviewSheet extends StatefulWidget {
  final Map<String, bool> initialItems;
  const EditOverviewSheet({super.key, required this.initialItems});

  @override
  State<EditOverviewSheet> createState() => _EditOverviewSheetState();
}

class _EditOverviewSheetState extends State<EditOverviewSheet> {
  late Map<String, bool> _overviewItems;

  @override
  void initState() {
    super.initState();
    _overviewItems = Map.from(widget.initialItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تخصيص نظرة عامة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _overviewItems.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: _overviewItems[key],
                  activeColor: AppTheme.primary,
                  onChanged: (bool? value) {
                    setState(() {
                      _overviewItems[key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _overviewItems),
                child: const Text('حفظ التغييرات'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
