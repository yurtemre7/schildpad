import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schildpad/home/home_screen.dart';
import 'package:schildpad/installed_app_widgets/app_widgets_screen.dart';
import 'package:schildpad/installed_app_widgets/installed_app_widgets.dart';
import 'package:schildpad/installed_app_widgets/installed_app_widgets_view.dart';
import 'package:schildpad/main.dart' as app;
import 'package:schildpad/overview/overview.dart';
import 'package:schildpad/overview/overview_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('navigate to InstalledAppWidgetsView tests', () {
    testWidgets('Button on OverviewScreen should open InstalledAppWidgetsView',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Given:
      // I am on the OverviewScreen
      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.longPress(homeScreenFinder);
      await tester.pumpAndSettle();
      expect(find.byType(OverviewScreen), findsOneWidget);

      // When:
      // I press the app widgets button
      final appWidgetsButtonFinder = find.byType(ShowAppWidgetsButton);
      expect(appWidgetsButtonFinder, findsOneWidget);
      await tester.tap(appWidgetsButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then:
      // AppWidgetsScreen is opened
      expect(find.byType(AppWidgetsScreen), findsOneWidget);
    });
  });
  group('add app widgets to home view', () {
    testWidgets(
        'Long pressing an app widget from installed app widgets view should enable drag and drop to home view',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
      await tester.longPress(homeScreenFinder);
      await tester.pumpAndSettle();
      expect(find.byType(OverviewScreen), findsOneWidget);
      final showAppWidgetsButtonFinder = find.byType(ShowAppWidgetsButton);
      expect(showAppWidgetsButtonFinder, findsOneWidget);
      await tester.tap(showAppWidgetsButtonFinder);
      await tester.pumpAndSettle();

      // Given:
      // I am on the AppWidgetsScreen
      final appWidgetsScreenFinder = find.byType(AppWidgetsScreen);
      expect(appWidgetsScreenFinder, findsOneWidget);

      // wait to load widgets
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // When:
      // I long press and drag an app widget
      final appWidgetGroupFinder = find.byType(AppWidgetGroupHeader);
      expect(appWidgetGroupFinder, findsWidgets);
      await tester.tap(appWidgetGroupFinder.first);
      await tester.pumpAndSettle();
      final installedAppWidgetFinder =
          find.byType(AppWidgetListTile).hitTestable();
      expect(installedAppWidgetFinder, findsWidgets);

      final longPressDragGesture = await tester
          .startGesture(tester.getCenter(installedAppWidgetFinder.first));
      await tester.pumpAndSettle();

      await longPressDragGesture.moveBy(const Offset(0, 150));
      await tester.pumpAndSettle();

      // Then:
      // I can drop it on the HomeScreen and it is added
      await longPressDragGesture.up();
      await tester.pumpAndSettle();

      expect(homeScreenFinder, findsOneWidget);
      expect(find.byType(AppWidget), findsOneWidget);
    });
  });
}
