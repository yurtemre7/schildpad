import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schildpad/home/home_screen.dart';
import 'package:schildpad/home/trash.dart';
import 'package:schildpad/installed_apps/installed_apps_view.dart';
import 'package:schildpad/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {});
  setUp(() async {});
  tearDown(() async {
    await Hive.deleteFromDisk();
  });
  group('move apps on HomeScreen tests', () {
    testWidgets('Moving an app on the home screen to an empty spot should work',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);
      final firstPosition = tester.getCenter(testAppFinder);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to somewhere else
      await longPressDragGesture.moveBy(const Offset(0, 200));
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // it is moved to this place
      final newTestAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(newTestAppFinder, findsOneWidget);
      final newPosition = tester.getCenter(newTestAppFinder);
      expect(newPosition, isNot(firstPosition));
    });
    testWidgets(
        'After moving an app on the home screen to an empty spot it should be possible to move it back',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);
      final firstPosition = tester.getCenter(testAppFinder);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to somewhere else
      await longPressDragGesture.moveBy(const Offset(0, 200));
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // it is moved to this place
      final newTestAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(newTestAppFinder, findsOneWidget);
      final newPosition = tester.getCenter(newTestAppFinder);
      expect(newPosition, isNot(firstPosition));

      // And:
      // When I drag it back to its place inside the grid
      final moveBackGesture = await tester.startGesture(newPosition);
      await tester.pumpAndSettle();
      await moveBackGesture.moveTo(firstPosition);
      await tester.pumpAndSettle();
      await moveBackGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // it is moved back
      final movedBackTestAppFinder =
          find.byType(InstalledAppDraggable).hitTestable();
      expect(movedBackTestAppFinder, findsOneWidget);
      final movedBackPosition = tester.getCenter(movedBackTestAppFinder);
      expect(movedBackPosition, firstPosition);
    });
    testWidgets(
        'Moving an app on the home screen to an occupied spot should not work',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder =
          find.byType(InstalledAppDraggable).hitTestable();
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();

      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(installedAppsViewFinder, findsOneWidget);
      expect(installedAppFinder, findsWidgets);
      final setup2LongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setup2LongPressDragGesture.moveBy(const Offset(100, 200));
      await tester.pumpAndSettle();
      await setup2LongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there are two apps
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsNWidgets(2));

      final firstTestAppPosition = tester.getCenter(testAppFinder.first);

      // When:
      // I long press the first app
      final longPressDragGesture =
          await tester.startGesture(firstTestAppPosition);
      await tester.pumpAndSettle();

      // and drag it on the other app
      final secondTestAppPosition = tester.getCenter(testAppFinder.at(1));
      await longPressDragGesture.moveTo(secondTestAppPosition);
      await tester.pumpAndSettle();

      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // it is not moved to this place and everything is still the same
      final newTestAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(newTestAppFinder, findsNWidgets(2));
      final newFirstTestAppPosition = tester.getCenter(newTestAppFinder.first);
      final newSecondTestAppPosition = tester.getCenter(newTestAppFinder.at(1));

      expect(newFirstTestAppPosition, firstTestAppPosition);
      expect(newSecondTestAppPosition, secondTestAppPosition);
    });
  });
  group('trash area', () {
    testWidgets(
        'Moving an app on the home screen should cause the trash area to show up',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to somewhere else
      await longPressDragGesture.moveBy(const Offset(0, 200));
      await tester.pumpAndSettle();

      // Then:
      // the trash area shows up
      final trashFinder = find.byType(TrashArea);
      expect(trashFinder, findsOneWidget);
    });
    testWidgets(
        'Dragging an app from the installed apps view to the home screen should cause the trash area to show up',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Given:
      // I am on the InstalledAppsView
      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);

      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle();

      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);

      // wait to load apps
      await Future.delayed(const Duration(seconds: 5), () {});
      await tester.pumpAndSettle();

      // When:
      // I long press and drag an InstalledAppButton
      final installedAppFinder = find.byType(InstalledAppDraggable).first;
      expect(installedAppFinder, findsOneWidget);

      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder));
      await tester.pumpAndSettle();

      await longPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Then:
      // the trash area shows up
      final trashFinder = find.byType(TrashArea);
      expect(trashFinder, findsOneWidget);
    });
    testWidgets(
        'After dropping a dragged app on an empty spot on the home screen the trash area should not be shown',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to somewhere else
      await longPressDragGesture.moveBy(const Offset(0, 200));
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // the trash area is not shown
      final trashFinder = find.byType(TrashArea).hitTestable();
      expect(trashFinder, findsNothing);
    });
    testWidgets(
        'After dropping a dragged app on an occupied spot on the home screen the trash area should not be shown',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder =
          find.byType(InstalledAppDraggable).hitTestable();
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();

      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(installedAppsViewFinder, findsOneWidget);
      expect(installedAppFinder, findsWidgets);
      final setup2LongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setup2LongPressDragGesture.moveBy(const Offset(100, 200));
      await tester.pumpAndSettle();
      await setup2LongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there are two apps
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsNWidgets(2));

      final firstTestAppPosition = tester.getCenter(testAppFinder.first);
      final secondTestAppPosition = tester.getCenter(testAppFinder.at(1));

      // When:
      // I long press the first app
      final longPressDragGesture =
          await tester.startGesture(firstTestAppPosition);
      await tester.pumpAndSettle();
      // and drag it on the other app
      await longPressDragGesture.moveTo(secondTestAppPosition);
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // the trash area is not shown
      final trashFinder = find.byType(TrashArea).hitTestable();
      expect(trashFinder, findsNothing);
    }, skip: true);
    testWidgets(
        'After dropping a dragged app in the trash area the trash area should not be shown',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to to the trash area
      final trashAreaFinder = find.byType(TrashArea);
      expect(trashAreaFinder, findsOneWidget);
      await longPressDragGesture.moveTo(tester.getCenter(trashAreaFinder));
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // the trash area is not shown
      final trashFinder = find.byType(TrashArea).hitTestable();
      expect(trashFinder, findsNothing);
    });
    testWidgets(
        'After dropping an app dragged from the installed apps view to the home screen on an occupied spot the trash area should not be shown',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);

      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle();
// Given:
      // I am on the InstalledAppsView
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);

      // wait to load apps
      await tester.pumpAndSettle();

      // When:
      // I long press and drag an app
      final installedAppFinder = find.byType(InstalledAppDraggable).first;
      expect(installedAppFinder, findsOneWidget);

      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder));
      await tester.pumpAndSettle();

      await longPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();

      final appFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(appFinder, findsOneWidget);
      // And:
      // I drop it on a spot occupied by an app
      await longPressDragGesture.moveTo(tester.getCenter(appFinder));
      await tester.pumpAndSettle();
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // the trash area is not shown
      final trashFinder = find.byType(TrashArea).hitTestable();
      expect(trashFinder, findsNothing);
    }, skip: true);
    testWidgets(
        'Moving an app on the home screen to the trash area should remove the app',
        (WidgetTester tester) async {
      // setup
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.fling(homeScreenFinder, const Offset(0, -100), 500,
          warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final installedAppsViewFinder = find.byType(InstalledAppsView);
      expect(installedAppsViewFinder, findsOneWidget);
      final installedAppFinder = find.byType(InstalledAppDraggable);
      expect(installedAppFinder, findsWidgets);
      final setupLongPressDragGesture =
          await tester.startGesture(tester.getCenter(installedAppFinder.first));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.moveBy(const Offset(100, 100));
      await tester.pumpAndSettle();
      await setupLongPressDragGesture.up();
      await tester.pumpAndSettle();
      // end setup

      // Given:
      // I am on the HomeScreen
      expect(homeScreenFinder, findsOneWidget);
      // and there is exactly one app
      final testAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(testAppFinder, findsOneWidget);

      // When:
      // I long press
      final longPressDragGesture =
          await tester.startGesture(tester.getCenter(testAppFinder));
      await tester.pumpAndSettle();
      // and drag it to to the trash area
      final trashAreaFinder = find.byType(TrashArea);
      expect(trashAreaFinder, findsOneWidget);
      await longPressDragGesture.moveTo(tester.getCenter(trashAreaFinder));
      await tester.pumpAndSettle();
      // and drop it there
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      // Then:
      // it is removed from the home screen
      final newTestAppFinder = find.byType(InstalledAppDraggable).hitTestable();
      expect(newTestAppFinder, findsNothing);
    });
  });
}
