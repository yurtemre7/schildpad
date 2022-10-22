import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:schildpad/home/flexible_grid.dart';
import 'package:schildpad/home/model/home_tile.dart';
import 'package:schildpad/home/pages.dart';
import 'package:schildpad/home/trash.dart';
import 'package:schildpad/installed_app_widgets/installed_app_widgets.dart';
import 'package:schildpad/installed_app_widgets/installed_application_widgets.dart';
import 'package:schildpad/installed_apps/installed_apps.dart';
import 'package:schildpad/main.dart';

final homeColumnCountProvider = Provider<int>((ref) {
  return 4;
});
final homeRowCountProvider = Provider<int>((ref) {
  return 5;
});

double approxHomeViewAspectRatio(
    BuildContext context, int homeRowCount, int totalRows) {
  final homeViewWidth = MediaQuery.of(context).size.width;
  final displayHeight = MediaQuery.of(context).size.height;
  final homeViewHeight = displayHeight * homeRowCount / totalRows;
  return homeViewWidth / homeViewHeight;
}

double homeGridColumnWidth(BuildContext context, int columnCount) {
  final homeViewWidth = MediaQuery.of(context).size.width;
  return homeViewWidth / columnCount;
}

double homeGridRowHeight(BuildContext context, int rowCount) {
  final homeViewWidth = MediaQuery.of(context).size.width;
  return homeViewWidth / rowCount;
}

final homeIsarProvider = FutureProvider<IsarCollection<HomeTile>>((ref) async {
  final isarFuture = ref.watch(isarProvider.future);
  return await isarFuture.then((isar) => isar.homeTiles);
});

final isarUpdateProvider = StreamProvider<void>((ref) async* {
  final isarFuture = ref.watch(isarProvider.future);
  yield* await isarFuture.then((isar) => isar.homeTiles.watchLazy());
});

final homeGridTilesProvider =
    Provider.family<List<FlexibleGridTile>, int>((ref, pageIndex) {
  ref.watch(isarUpdateProvider);
  final tiles = ref.watch(homeIsarProvider).whenOrNull(data: (tiles) => tiles);
  final columnCount = ref.watch(homeColumnCountProvider);
  final rowCount = ref.watch(homeRowCountProvider);
  final gridTiles = tiles
      ?.filter()
      .coordinates(
          (q) => q.locationEqualTo(Location.home).pageEqualTo(pageIndex))
      .findAllSync();
  final flexibleGridTiles = gridTiles?.map((e) => FlexibleGridTile(
      column: e.coordinates?.column ?? 0,
      row: e.coordinates?.row ?? 0,
      columnSpan: e.columnSpan!,
      rowSpan: e.rowSpan!,
      child: GridCell(
        coordinates: e.coordinates!,
        columnCount: columnCount,
        rowCount: rowCount,
      )));
  return flexibleGridTiles?.toList() ?? List.empty();
});

class GridCell extends ConsumerWidget {
  const GridCell(
      {Key? key,
      required this.coordinates,
      required this.columnCount,
      required this.rowCount})
      : super(key: key);
  final GlobalElementCoordinates coordinates;
  final int columnCount;
  final int rowCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = ref.watch(tileProvider(coordinates));
    final tileManager = ref.watch(tileManagerProvider);

    return DragTarget<ElementData>(onWillAccept: (draggedData) {
      final data = draggedData;
      if (data != null) {
        return tileManager.canAddElement(
            columnCount, rowCount, coordinates, data);
      }
      return false;
    }, onAccept: (data) async {
      await tileManager.addElement(columnCount, rowCount, coordinates, data);
      await tileManager.removeElement(data.origin);
      ref.read(showTrashProvider.notifier).state = false;
    }, builder: (_, accepted, rejected) {
      BoxDecoration? boxDecoration;
      if (rejected.isNotEmpty) {
        boxDecoration =
            BoxDecoration(border: Border.all(color: Colors.red, width: 3));
      } else if (accepted.isNotEmpty) {
        boxDecoration = BoxDecoration(
            border: Border.all(color: Colors.greenAccent, width: 3));
      }
      final appData = tile.appData;
      final appWidgetData = tile.appWidgetData;

      final Widget child;
      if (appData?.packageName != null) {
        final appPackage = appData?.packageName ?? '';
        child = InstalledAppDraggable(
          app: AppData(packageName: appPackage),
          appIcon: AppIcon(
            packageName: appPackage,
          ),
          origin: coordinates,
        );
      } else if (appWidgetData != null) {
        final componentName = appWidgetData.componentName!;
        final widgetId = appWidgetData.appWidgetId!;
        child = HomeGridWidget(
            appWidgetData: AppWidgetData(
                componentName: componentName, appWidgetId: widgetId),
            columnSpan: tile.columnSpan!,
            rowSpan: tile.rowSpan!,
            origin: coordinates);
      } else {
        child = const SizedBox.expand();
      }

      return OverflowBox(
        child: Container(
          foregroundDecoration: boxDecoration,
          child: child,
        ),
      );
    });
  }
}

final tileProvider = Provider.family<HomeTile, GlobalElementCoordinates>(
    (ref, globalCoordinates) {
  ref.watch(isarUpdateProvider);
  final tiles = ref.watch(homeIsarProvider).whenOrNull(data: (tiles) => tiles);

  final tile = tiles
      ?.filter()
      .coordinates((q) => q
          .locationEqualTo(globalCoordinates.location)
          .pageEqualTo(globalCoordinates.page)
          .columnEqualTo(globalCoordinates.column)
          .rowEqualTo(globalCoordinates.row))
      .findFirstSync();

  return tile ?? HomeTile(coordinates: globalCoordinates);
});

class HomePageViewScrollPhysics extends ScrollPhysics {
  const HomePageViewScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  HomePageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HomePageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 0.7,
      );
}

final currentHomePageProvider = StateProvider<int>((ref) {
  final initialPage = ref.read(initialPageProvider);
  return initialPage;
});

int pageViewToSchildpadIndex(int pageViewIndex, int leftPages) =>
    pageViewIndex - leftPages;

int schildpadToPageViewIndex(int schildpadIndex, int leftPages) =>
    schildpadIndex + leftPages;

final homePageControllerProvider = Provider<PageController>((ref) {
  final leftPagesCount = ref.watch(leftPagesProvider);
  final currentPage = ref.watch(currentHomePageProvider);

  final pageController = PageController(
      initialPage: schildpadToPageViewIndex(currentPage, leftPagesCount));
  return pageController;
});

class HomeView extends ConsumerWidget {
  const HomeView({Key? key, required this.pageController}) : super(key: key);

  final PageController pageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCount = ref.watch(pageCountProvider);
    final leftPagesCount = ref.watch(leftPagesProvider);
    final columnCount = ref.watch(homeColumnCountProvider);
    final rowCount = ref.watch(homeRowCountProvider);

    return PageView(
        controller: pageController,
        onPageChanged: (page) {
          final schildpadPage = pageViewToSchildpadIndex(page, leftPagesCount);
          ref.read(currentHomePageProvider.notifier).state = schildpadPage;
        },
        physics: const HomePageViewScrollPhysics(),
        children: List.generate(
            pageCount,
            (index) => HomePage(pageViewToSchildpadIndex(index, leftPagesCount),
                columnCount, rowCount)));
  }
}

class HomePage extends ConsumerWidget {
  const HomePage(
    this.pageIndex,
    this.columnCount,
    this.rowCount, {
    Key? key,
  }) : super(key: key);

  final int pageIndex;
  final int columnCount;
  final int rowCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeGridTiles = ref.watch(homeGridTilesProvider(pageIndex));
    final columnCount = ref.watch(homeColumnCountProvider);
    final rowCount = ref.watch(homeRowCountProvider);
    return Grid(
        location: Location.home,
        page: pageIndex,
        columnCount: columnCount,
        rowCount: rowCount,
        tiles: homeGridTiles);
  }
}

class Grid extends StatelessWidget {
  const Grid(
      {Key? key,
      required this.location,
      this.page,
      required this.columnCount,
      required this.rowCount,
      required this.tiles})
      : super(key: key);
  final Location location;
  final int? page;
  final int columnCount;
  final int rowCount;
  final List<FlexibleGridTile> tiles;

  @override
  Widget build(BuildContext context) {
    final defaultTiles = [];
    for (var col = 0; col < columnCount; col++) {
      for (var row = 0; row < rowCount; row++) {
        if (!tiles.any((tile) => isInsideTile(col, row, tile))) {
          defaultTiles.add(FlexibleGridTile(
              column: col,
              row: row,
              child: GridCell(
                coordinates: GlobalElementCoordinates(
                    location: location, page: page, column: col, row: row),
                columnCount: columnCount,
                rowCount: rowCount,
              )));
        }
      }
    }

    return FlexibleGrid(
        columnCount: columnCount,
        rowCount: rowCount,
        gridTiles: [...tiles, ...defaultTiles]);
  }
}

class AppWidgetError extends StatelessWidget {
  const AppWidgetError({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
        child: Card(
      color: Colors.amber,
      child: Column(
        children: const [
          Icon(
            Icons.bubble_chart,
            color: Colors.white,
          ),
          Icon(
            Icons.adb_outlined,
            color: Colors.white,
          )
        ],
      ),
    ));
  }
}

class HomeGridWidget extends StatelessWidget {
  const HomeGridWidget({
    Key? key,
    required this.appWidgetData,
    required this.columnSpan,
    required this.rowSpan,
    required this.origin,
  }) : super(key: key);

  final AppWidgetData appWidgetData;
  final GlobalElementCoordinates origin;
  final int columnSpan;
  final int rowSpan;

  @override
  Widget build(BuildContext context) {
    final widgetId = appWidgetData.appWidgetId;
    assert(widgetId != null);

    if (widgetId != null) {
      return LongPressDraggable(
          data: ElementData(
            appWidgetData: appWidgetData,
            columnSpan: columnSpan,
            rowSpan: rowSpan,
            origin: origin,
          ),
          maxSimultaneousDrags: 1,
          feedback:
              Container(color: Colors.cyanAccent, width: 200, height: 100),
          child: AppWidget(
            appWidgetData: appWidgetData,
          ));
    } else {
      return const AppWidgetError();
    }
  }
}

class ElementData {
  ElementData(
      {this.appData,
      this.appWidgetData,
      required this.columnSpan,
      required this.rowSpan,
      required this.origin});

  ElementData.fromAppData(
      {required AppData this.appData,
      required this.columnSpan,
      required this.rowSpan,
      required this.origin})
      : appWidgetData = null;

  ElementData.fromAppWidgetData(
      {required AppWidgetData this.appWidgetData,
      required this.columnSpan,
      required this.rowSpan,
      required this.origin})
      : appData = null;

  final AppData? appData;
  final AppWidgetData? appWidgetData;
  final int columnSpan;
  final int rowSpan;
  final GlobalElementCoordinates origin;

  ElementData copyWithAppWidgetData(String componentName, int appWidgetId) =>
      ElementData.fromAppWidgetData(
          appWidgetData: AppWidgetData(
              componentName: componentName, appWidgetId: appWidgetId),
          columnSpan: columnSpan,
          rowSpan: rowSpan,
          origin: origin);

  bool get isAppData => appData != null;

  bool get isAppWidgetData => !isAppData && appWidgetData != null;

  bool get isEmpty => !isAppData && !isAppWidgetData;
}

final tileManagerProvider = Provider<TileManager>((ref) {
  final isarCollection =
      ref.watch(homeIsarProvider).whenOrNull(data: (collection) => collection);
  return TileManager(isarCollection);
});

class TileManager {
  TileManager(this.isarCollection);

  final IsarCollection<HomeTile>? isarCollection;

  bool canAddElement(int columnCount, int rowCount,
      GlobalElementCoordinates coordinates, ElementData data) {
    final homeTileCollection = isarCollection;
    if (homeTileCollection != null) {
      final gridTiles = homeTileCollection
          .filter()
          .coordinates((c) => c
              .locationEqualTo(coordinates.location)
              .pageEqualTo(coordinates.page)
              .columnEqualTo(coordinates.column)
              .rowEqualTo(coordinates.row))
          .findAllSync();
      final flexibleGridTiles = gridTiles
          .map((e) => FlexibleGridTile(
                column: e.coordinates?.column ?? 0,
                row: e.coordinates?.row ?? 0,
                columnSpan: e.columnSpan!,
                rowSpan: e.rowSpan!,
              ))
          .toList();
      return canAdd(
          flexibleGridTiles,
          columnCount,
          rowCount,
          coordinates.column ?? 0,
          coordinates.row ?? 0,
          data.columnSpan,
          data.rowSpan);
    }
    return false;
  }

  Future<void> addElement(int columnCount, int rowCount,
      GlobalElementCoordinates coordinates, ElementData data) async {
    if (!canAddElement(columnCount, rowCount, coordinates, data)) {
      return;
    }
    final homeTileCollection = isarCollection;
    if (homeTileCollection != null) {
      // delete current elements at same position
      await removeElement(coordinates);

      // add new element
      final app = data.appData;
      final appWidget = data.appWidgetData;
      final int? widgetId;
      if (app == null && appWidget != null) {
        widgetId = await createApplicationWidget(appWidget.componentName);
      } else {
        widgetId = null;
      }
      final tileToAdd = HomeTile(
          coordinates: coordinates,
          columnSpan: data.columnSpan,
          rowSpan: data.rowSpan,
          appData: HomeTileAppData(packageName: app?.packageName),
          appWidgetData: HomeTileAppWidgetData(
              componentName: appWidget?.componentName, appWidgetId: widgetId));
      await homeTileCollection.isar
          .writeTxn(() async => await homeTileCollection.put(tileToAdd));
    }
  }

  Future<void> removeElement(GlobalElementCoordinates coordinates) async {
    final homeTileCollection = isarCollection;
    if (homeTileCollection != null) {
      await homeTileCollection.isar.writeTxn(() async =>
          await homeTileCollection
              .filter()
              .coordinates((q) => q
                  .locationEqualTo(coordinates.location)
                  .pageEqualTo(coordinates.page)
                  .columnEqualTo(coordinates.column)
                  .rowEqualTo(coordinates.row))
              .deleteAll());
    }
  }

  Future<void> removeAll() async {
    final homeTileCollection = isarCollection;
    if (homeTileCollection != null) {
      await homeTileCollection.isar
          .writeTxn(() async => await homeTileCollection.clear());
    }
  }
}
