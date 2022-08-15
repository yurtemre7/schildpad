import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schildpad/home/flexible_grid.dart';
import 'package:schildpad/home/home.dart';
import 'package:schildpad/home/trash.dart';
import 'package:schildpad/installed_app_widgets/installed_app_widgets.dart';
import 'package:schildpad/installed_apps/apps.dart';
import 'package:schildpad/installed_apps/installed_apps_view.dart';

final dockColumnCountProvider = Provider<int>((ref) {
  return 4;
});
final dockRowCountProvider = Provider<int>((ref) {
  return 1;
});

const _dockDataHiveBoxName = 'dock_data';

String _getDockDataHiveKey(int column, int row) => '${column}_$row';

final dockGridTilesProvider = Provider<List<FlexibleGridTile>>((ref) {
  final tiles = ref.watch(dockGridStateProvider);
  return tiles;
});

final _dockGridHiveBoxProvider = FutureProvider<Box<List<String>>>((ref) async {
  final box = Hive.openBox<List<String>>(_dockDataHiveBoxName);
  return box;
});

final dockGridStateProvider =
    StateNotifierProvider<DockGridStateNotifier, List<FlexibleGridTile>>((ref) {
  final columns = ref.watch(dockColumnCountProvider);
  final rows = ref.watch(dockRowCountProvider);
  final hiveBox = ref.watch(_dockGridHiveBoxProvider).valueOrNull;
  return DockGridStateNotifier(columns, rows, hiveBox: hiveBox);
});

class DockGridStateNotifier extends StateNotifier<List<FlexibleGridTile>> {
  DockGridStateNotifier(this.columnCount, this.rowCount, {this.hiveBox})
      : super([]) {
    final box = hiveBox;
    if (box != null) {
      var tiles = <FlexibleGridTile>[];

      for (String key in box.keys) {
        final colRow = key.split('_');
        final col = int.parse(colRow[0]);
        final row = int.parse(colRow[1]);
        final List elementData = box.get(key) ?? [];

        Widget? tileChild;
        if (elementData.length == 1) {
          final appPackage = elementData.cast<String>().first;
          tileChild = InstalledAppDraggable(
            app: AppData(packageName: appPackage),
            appIcon: AppIcon(packageName: appPackage),
          );
        } else if (elementData.length == 2) {
          final appWidgetData = elementData.cast<String>();
          final componentName = appWidgetData.first;
          final appWidgetId = int.parse(appWidgetData.elementAt(1));
          tileChild = HomeGridWidget(
            appWidget: AppWidgetData(
                componentName: componentName, appWidgetId: appWidgetId),
          );
        }

        final tile = FlexibleGridTile(
            column: col, row: row, child: Center(child: tileChild));

        tiles = addTile(tiles, columnCount, rowCount, tile);
      }
      state = tiles;
    }
  }

  final int columnCount;
  final int rowCount;

  final Box<List<String>>? hiveBox;

  bool canAddElement(int column, int row, ElementData data) {
    return canAdd(state, columnCount, rowCount, column, row, data.columnSpan,
        data.rowSpan);
  }

  void addElement(int column, int row, ElementData data) {
    Widget? widgetToAdd;
    List<String> dataToPersist = [];

    final app = data.appData;
    final appWidget = data.appWidgetData;

    if (app != null) {
      widgetToAdd = InstalledAppDraggable(
        app: app,
        appIcon: AppIcon(packageName: app.packageName),
      );
      dataToPersist.add(app.packageName);
    } else if (appWidget != null) {
      widgetToAdd = HomeGridWidget(
        appWidget: appWidget,
      );
      dataToPersist.add(appWidget.componentName);
      dataToPersist.add('${appWidget.appWidgetId}');
    }

    final tileToAdd = FlexibleGridTile(
        column: column,
        row: row,
        columnSpan: data.columnSpan,
        rowSpan: data.rowSpan,
        child: Center(child: widgetToAdd));

    final stateBefore = state;
    state = addTile(state, columnCount, rowCount, tileToAdd);
    if (state != stateBefore) {
      dev.log('saving element in ($column, $row)');
      hiveBox?.put(_getDockDataHiveKey(column, row), dataToPersist);
    }
  }

  void removeElement(int columnStart, int rowStart) {
    state = [...removeTile(state, columnStart, rowStart)];
    dev.log('deleting element in ($columnStart, $rowStart)');
    hiveBox?.delete(_getDockDataHiveKey(columnStart, rowStart));
  }

  void removeAll() {
    hiveBox?.deleteAll(hiveBox?.keys ?? []);
    state = [];
  }
}

class DockGrid extends ConsumerWidget {
  const DockGrid(
    this.columnCount,
    this.rowCount, {
    Key? key,
  }) : super(key: key);

  final int columnCount;
  final int rowCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    dev.log('rebuilding Dock');
    final dockGridTiles = ref.watch(dockGridTilesProvider);
    final defaultTiles = [];
    for (var col = 0; col < columnCount; col++) {
      for (var row = 0; row < rowCount; row++) {
        if (!dockGridTiles.any((tile) => isInsideTile(col, row, tile))) {
          defaultTiles.add(FlexibleGridTile(
              column: col,
              row: row,
              child: DockGridEmptyCell(column: col, row: row)));
        }
      }
    }

    return FlexibleGrid(
        columnCount: columnCount,
        rowCount: rowCount,
        gridTiles: [...dockGridTiles, ...defaultTiles]);
  }
}

class DockGridEmptyCell extends ConsumerWidget {
  const DockGridEmptyCell({
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);

  final int column;
  final int row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<ElementData>(
      onWillAccept: (draggedData) {
        final data = draggedData;
        if (data != null) {
          final willAccept = ref
              .read(dockGridStateProvider.notifier)
              .canAddElement(column, row, data);
          dev.log('($column, $row) will accept: $willAccept');
          return willAccept;
        }
        return false;
      },
      onAccept: (data) {
        dev.log('dropped in ($column, $row)');
        ref.read(dockGridStateProvider.notifier).addElement(column, row, data);

        ref.read(showTrashProvider.notifier).state = false;
      },
      builder: (_, __, ___) => const SizedBox.expand(),
    );
  }
}

class Dock extends ConsumerWidget {
  const Dock({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dockColumnCount = ref.watch(dockColumnCountProvider);
    final dockRowCount = ref.watch(dockRowCountProvider);
    return DockGrid(dockColumnCount, dockRowCount);
  }
}
