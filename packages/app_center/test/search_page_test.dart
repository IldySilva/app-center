import 'package:app_center/search/search.dart';
import 'package:app_center/snapd/multisnap_model.dart';
import 'package:app_center/snapd/snapd.dart';
import 'package:app_center/widgets/widgets.dart';
import 'package:app_center_ratings_client/app_center_ratings_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:ubuntu_widgets/ubuntu_widgets.dart';

import 'test_utils.dart';
import 'test_utils.mocks.dart';

const snapId = 'r4LxMVp7zWramXsJQAKdamxy6TAWlaDD';
const snapName = 'signal-desktop';
const snapRating = Rating(
  snapId: snapId,
  totalVotes: 123,
  ratingsBand: RatingsBand.good,
  snapName: snapName,
);

void main() {
  setUp(() => registerMockRatingsService(rating: snapRating));
  tearDown(resetAllServices);

  final mockSearchProvider = createMockSnapSearchProvider({
    const SnapSearchParameters(query: 'testsn'): [
      createSnap(name: 'testsnap', title: 'Test Snap', downloadSize: 3),
      createSnap(
        name: 'testsnap2',
        title: 'Another Test Snap',
        downloadSize: 1,
      ),
      createSnap(
        name: 'testsnap3',
        title: 'Yet Another Test Snap',
        downloadSize: 2,
      ),
    ],
    const SnapSearchParameters(
      query: 'testsn',
      category: SnapCategoryEnum.development,
    ): [
      createSnap(
        name: 'testsnap3',
        title: 'Yet Another Test Snap',
        downloadSize: 2,
      ),
    ],
    const SnapSearchParameters(category: SnapCategoryEnum.education): [
      createSnap(name: 'educational-snap', title: 'Educational Snap'),
    ],
    const SnapSearchParameters(category: SnapCategoryEnum.gameDev): [
      createSnap(name: 'game-engine', title: 'Game Engine'),
      createSnap(name: 'image-processor', title: 'Image Processor'),
    ],
  });
  final multiSnapModel = MockMultiSnapModel();

  testWidgets('query', (tester) async {
    await tester.pumpApp(
      (_) => ProviderScope(
        overrides: [
          snapSearchProvider
              .overrideWith((ref, query) => mockSearchProvider(query)),
        ],
        child: const SearchPage(query: 'testsn'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(tester.l10n.searchPageTitle('testsn')), findsOneWidget);
    expect(
      find.widgetWithText(
        MenuButtonBuilder<SnapCategoryEnum?>,
        tester.l10n.snapCategoryAll,
      ),
      findsOneWidget,
    );
    expect(find.text('Test Snap'), findsOneWidget);
    expect(find.text('Another Test Snap'), findsOneWidget);
    expect(find.text('Yet Another Test Snap'), findsOneWidget);
  });

  testWidgets('query + category', (tester) async {
    await tester.pumpApp(
      (_) => ProviderScope(
        overrides: [
          snapSearchProvider
              .overrideWith((ref, query) => mockSearchProvider(query)),
        ],
        child: const SearchPage(
          query: 'testsn',
          category: 'development',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(tester.l10n.searchPageTitle('testsn')), findsOneWidget);
    expect(
      find.widgetWithText(
        MenuButtonBuilder<SnapCategoryEnum?>,
        tester.l10n.snapCategoryDevelopment,
      ),
      findsOneWidget,
    );
    expect(find.text('Test Snap'), findsNothing);
    expect(find.text('Another Test Snap'), findsNothing);
    expect(find.text('Yet Another Test Snap'), findsOneWidget);
  });

  testWidgets('category', (tester) async {
    await tester.pumpApp(
      (_) => ProviderScope(
        overrides: [
          snapSearchProvider
              .overrideWith((ref, query) => mockSearchProvider(query)),
        ],
        child: const SearchPage(
          category: 'education',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(tester.l10n.snapCategoryEducation), findsOneWidget);
    expect(find.byType(MenuButtonBuilder<SnapCategoryEnum?>), findsNothing);
    expect(find.text('Test Snap'), findsNothing);
    expect(find.text('Another Test Snap'), findsNothing);
    expect(find.text('Yet Another Test Snap'), findsNothing);
    expect(find.text('Educational Snap'), findsOneWidget);
  });

  testWidgets('games-bundle', (tester) async {
    await tester.pumpApp(
      (_) => ProviderScope(
        overrides: [
          snapSearchProvider
              .overrideWith((ref, query) => mockSearchProvider(query)),
          multiSnapModelProvider.overrideWith((ref, arg) => multiSnapModel),
        ],
        child: const SearchPage(
          category: 'gameDev',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(tester.l10n.snapCategoryGameDev), findsOneWidget);
    expect(find.byType(MenuButtonBuilder<SnapCategoryEnum?>), findsNothing);
    expect(find.text(tester.l10n.installAll), findsOneWidget);
    expect(find.text('Game Engine'), findsOneWidget);
    expect(find.text('Image Processor'), findsOneWidget);
    expect(find.text('Test Snap'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    verify(multiSnapModel.installAll()).called(1);
  });

  group('sort results', () {
    testWidgets('Relevance', (tester) async {
      await tester.pumpApp(
        (_) => ProviderScope(
          overrides: [
            snapSearchProvider
                .overrideWith((ref, query) => mockSearchProvider(query)),
          ],
          child: const SearchPage(query: 'testsn'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(tester.l10n.searchPageSortByLabel), findsOneWidget);
      expect(find.text(tester.l10n.searchPageRelevanceLabel), findsOneWidget);

      final resultCards =
          tester.widget<AppCardGrid>(find.byType(AppCardGrid)).appCards;
      expect(
        resultCards.map((card) => card.title.title).toList(),
        equals([
          'Test Snap',
          'Another Test Snap',
          'Yet Another Test Snap',
        ]),
      );
    });
    testWidgets('Download Size', (tester) async {
      await tester.pumpApp(
        (_) => ProviderScope(
          overrides: [
            snapSearchProvider
                .overrideWith((ref, query) => mockSearchProvider(query)),
          ],
          child: const SearchPage(query: 'testsn'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(tester.l10n.searchPageSortByLabel), findsOneWidget);
      await tester.tap(find.text(tester.l10n.searchPageRelevanceLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tester.l10n.snapSortOrderDownloadSizeAsc));
      await tester.pumpAndSettle();

      final resultCards =
          tester.widget<AppCardGrid>(find.byType(AppCardGrid)).appCards;
      expect(
        resultCards.map((card) => card.title.title).toList(),
        equals([
          'Another Test Snap',
          'Yet Another Test Snap',
          'Test Snap',
        ]),
      );
    });
    testWidgets('Alphabetical', (tester) async {
      await tester.pumpApp(
        (_) => ProviderScope(
          overrides: [
            snapSearchProvider
                .overrideWith((ref, query) => mockSearchProvider(query)),
          ],
          child: const SearchPage(query: 'testsn'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(tester.l10n.searchPageSortByLabel), findsOneWidget);
      await tester.tap(find.text(tester.l10n.searchPageRelevanceLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tester.l10n.snapSortOrderAlphabeticalAsc));
      await tester.pumpAndSettle();

      final resultCards =
          tester.widget<AppCardGrid>(find.byType(AppCardGrid)).appCards;
      expect(
        resultCards.map((card) => card.title.title).toList(),
        equals([
          'Another Test Snap',
          'Test Snap',
          'Yet Another Test Snap',
        ]),
      );
    });
  });

  group('no results', () {
    testWidgets('query', (tester) async {
      await tester.pumpApp(
        (_) => ProviderScope(
          overrides: [
            snapSearchProvider
                .overrideWith((ref, query) => mockSearchProvider(query)),
          ],
          child: const SearchPage(query: 'foo'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(tester.l10n.searchPageNoResults('foo')), findsOneWidget);
      expect(find.text(tester.l10n.searchPageNoResultsHint), findsOneWidget);
      expect(find.byType(AppCardGrid), findsNothing);
    });

    testWidgets('empty category', (tester) async {
      await tester.pumpApp(
        (_) => ProviderScope(
          overrides: [
            snapSearchProvider
                .overrideWith((ref, query) => mockSearchProvider(query)),
          ],
          child: const SearchPage(query: 'foo', category: 'social'),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text(tester.l10n.searchPageNoResultsCategory),
        findsOneWidget,
      );
      expect(
        find.text(tester.l10n.searchPageNoResultsCategoryHint),
        findsOneWidget,
      );
      expect(find.byType(AppCardGrid), findsNothing);
    });
  });
}
