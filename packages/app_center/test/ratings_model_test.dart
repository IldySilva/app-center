import 'package:app_center/ratings/ratings.dart';
import 'package:app_center_ratings_client/app_center_ratings_client.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

import 'test_utils.dart';

void main() {
  final snap = createSnap(
    name: 'firefox',
    id: '1234',
    revision: 42,
  );

  setUp(() {
    registerMockSnapdService(storeSnap: snap);
    registerMockRatingsService(
      rating: const Rating(
        snapId: '1234',
        totalVotes: 1337,
        ratingsBand: RatingsBand.veryGood,
        snapName: 'firefox',
      ),
      snapVotes: [
        Vote(
          snapId: '1234',
          snapRevision: 42,
          voteUp: true,
          dateTime: DateTime(1970),
          snapName: 'firefox',
        ),
      ],
    );
  });

  tearDown(resetAllServices);

  test('init', () async {
    final container = createContainer();
    final ratingsData =
        await container.read(ratingsModelProvider(snap.name).future);
    expect(
      ratingsData.rating,
      equals(
        const Rating(
          snapId: '1234',
          totalVotes: 1337,
          ratingsBand: RatingsBand.veryGood,
          snapName: 'firefox',
        ),
      ),
    );
    expect(ratingsData.voteStatus, equals(VoteStatus.up));
  });

  test('cast vote', () async {
    final container = createContainer();
    final mockService = getService<RatingsService>();
    final model = container.read(ratingsModelProvider(snap.name).notifier);
    container.listen(ratingsModelProvider(snap.name), (_, __) {});
    await container.read(ratingsModelProvider(snap.name).future);
    await withClock(
      Clock.fixed(DateTime(1984)),
      () => model.castVote(VoteStatus.down),
    );
    verify(
      mockService.vote(
        Vote(
          dateTime: DateTime(1984),
          snapId: '1234',
          snapRevision: 42,
          voteUp: false,
          snapName: 'firefox',
        ),
      ),
    ).called(1);
  });
}
