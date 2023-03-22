import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:schildpad/home/home.dart';
import 'package:schildpad/home/model/layout_settings.dart';
import 'package:schildpad/main.dart';
import 'package:toggle_switch/toggle_switch.dart';

final layoutSettingsProvider = Provider<LayoutSettings>((ref) {
  ref.watch(isarLayoutSettingsUpdateProvider);
  final layoutSettings = ref
      .watch(layoutSettingsIsarProvider)
      .whenOrNull(data: (layout) => layout);
  return layoutSettings?.getSync(0) ?? LayoutSettings();
});

final layoutSettingsIsarProvider =
    FutureProvider<IsarCollection<LayoutSettings>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.layoutSettings;
});

final isarLayoutSettingsUpdateProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.layoutSettings.watchLazy();
});

final layoutSettingsManagerProvider = Provider<LayoutSettingsManager>((ref) {
  final isarCollection = ref
      .watch(layoutSettingsIsarProvider)
      .whenOrNull(data: (collection) => collection);
  return LayoutSettingsManager(isarCollection);
});

class LayoutSettingsManager {
  LayoutSettingsManager(this.isarCollection);

  final IsarCollection<LayoutSettings>? isarCollection;

  Future<void> setColumns(int columns) async {
    final layoutCollection = isarCollection;

    await layoutCollection?.isar.writeTxn(() async {
      final gridLayout = await layoutCollection.get(0);
      final newLayout = gridLayout?.copyWith(appGridColumns: columns) ??
          LayoutSettings(appGridColumns: columns);
      await layoutCollection.put(newLayout);
    });
  }

  Future<void> setRows(int rows) async {
    final layoutCollection = isarCollection;

    await layoutCollection?.isar.writeTxn(() async {
      final gridLayout = await layoutCollection.get(0);
      final newLayout = gridLayout?.copyWith(appGridRows: rows) ??
          LayoutSettings(appGridColumns: rows);
      await layoutCollection.put(newLayout);
    });
  }
}

class AppGridHeadingListTile extends StatelessWidget {
  const AppGridHeadingListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context)!.appGridListTile,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class AppGridColumnsListTile extends ConsumerWidget {
  const AppGridColumnsListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutManager = ref.watch(layoutSettingsManagerProvider);
    final columns = ref.watch(homeColumnCountProvider);
    return ListTile(
        title: Text(AppLocalizations.of(context)!.columns),
        trailing: ToggleSwitch(
          initialLabelIndex: columns - 3,
          totalSwitches: 3,
          labels: const ['3', '4', '5'],
          onToggle: (index) async {
            if (index != null) {
              await layoutManager.setColumns(index + 3);
            }
          },
        ));
  }
}

class AppGridRowsListTile extends ConsumerWidget {
  const AppGridRowsListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutManager = ref.watch(layoutSettingsManagerProvider);
    final rows = ref.watch(homeRowCountProvider);
    return ListTile(
        title: Text(AppLocalizations.of(context)!.rows),
        trailing: ToggleSwitch(
          initialLabelIndex: rows - 3,
          totalSwitches: 3,
          labels: const ['3', '4', '5'],
          onToggle: (index) async {
            if (index != null) {
              await layoutManager.setRows(index + 3);
            }
          },
        ));
  }
}

class AppDrawerHeadingListTile extends StatelessWidget {
  const AppDrawerHeadingListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context)!.appDrawer,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class AppDrawerColumnsListTile extends StatelessWidget {
  const AppDrawerColumnsListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(AppLocalizations.of(context)!.columns),
        trailing: ToggleSwitch(
          initialLabelIndex: 0,
          totalSwitches: 3,
          labels: const ['3', '4', '5'],
          onToggle: (index) {},
        ));
  }
}

class DockHeadingListTile extends StatelessWidget {
  const DockHeadingListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context)!.dock,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class DockColumnsListTile extends StatelessWidget {
  const DockColumnsListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(AppLocalizations.of(context)!.columns),
        trailing: ToggleSwitch(
          initialLabelIndex: 0,
          totalSwitches: 3,
          labels: const ['3', '4', '5'],
          onToggle: (index) {},
        ));
  }
}

class DockAdditionalRowListTile extends StatelessWidget {
  const DockAdditionalRowListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: Text(AppLocalizations.of(context)!.additionalRow),
        value: false,
        onChanged: (_) {});
  }
}

class DockTopListTile extends StatelessWidget {
  const DockTopListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: Text(AppLocalizations.of(context)!.topDock),
        value: false,
        onChanged: (_) {});
  }
}
