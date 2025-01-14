// @dart=2.9
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rotary_nl_rye/core/error/exceptions.dart';
import 'package:rotary_nl_rye/core/error/failures.dart';
import 'package:rotary_nl_rye/core/network/network_info.dart';
import 'package:rotary_nl_rye/features/stories/data/datasources/different.dart';
import 'package:rotary_nl_rye/features/stories/data/datasources/stories_local_data_source.dart';
import 'package:rotary_nl_rye/features/stories/data/datasources/update_local_data_source.dart';
import 'package:rotary_nl_rye/features/stories/data/models/story_model.dart';
import 'package:rotary_nl_rye/features/stories/data/repositories/stories_respository_impl.dart';
import 'package:rotary_nl_rye/features/stories/domain/entities/story.dart';

class MockStoriesRemoteDataSource extends Mock implements StoriesRemoteDataSource {}

class MockStoriesLocalDataSource extends Mock implements StoriesLocalDataSource {}

class MockUpdateLocalDataSource extends Mock implements UpdateLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  StoriesRepositoryImpl repository;
  MockStoriesRemoteDataSource mockStoriesRemoteDataSource;
  MockStoriesLocalDataSource mockStoriesLocalDataSource;
  MockUpdateLocalDataSource mockUpdateLocalDataSource;
  MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockStoriesRemoteDataSource = MockStoriesRemoteDataSource();
    mockStoriesLocalDataSource = MockStoriesLocalDataSource();
    mockUpdateLocalDataSource = MockUpdateLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = StoriesRepositoryImpl(
        storiesRemoteDataSource: mockStoriesRemoteDataSource,
        storiesLocalDataSource: mockStoriesLocalDataSource,
        updateLocalDataSource: mockUpdateLocalDataSource,
        networkInfo: mockNetworkInfo);
  });

  group('getStories', () {
    final List<StoryModel> tStoriesModel = [
      new StoryModel(
          country: "Bali",
          arrivalDate: 1632261600000,
          departureDate: 1632261600000,
          imagePath: "assets/image/3.PNG",
          studentName: "Ruben",
          text1: "Hi",
          text2: "test"),
      new StoryModel(
          country: "Bali",
          arrivalDate: 1632261600000,
          departureDate: 1632261600000,
          imagePath: "assets/image/3.PNG",
          studentName: "Ruben",
          text1: "Hi",
          text2: "test")
    ];

    final List<Story> tStories = tStoriesModel;

    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      // act
      repository.getStories();
      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockUpdateLocalDataSource.timeSpanIsGreaterThen24h).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source was successful', () async {
        // arrange
        when(mockStoriesRemoteDataSource.getStories()).thenAnswer((_) async => tStoriesModel);
        // act
        final result = await repository.getStories();
        // assert
        expect(result, equals(Right(tStories)));
      });

      test('should cache the data locally when the call to remote data source was successful', () async {
        // arrange
        when(mockStoriesRemoteDataSource.getStories()).thenAnswer((_) async => tStoriesModel);
        // act
        await repository.getStories();
        // assert
        verify(mockStoriesLocalDataSource.cacheStories(tStoriesModel));
      });

      test('should cache the update data locally when the call to remote data source was successful', () async {
        // act
        await repository.getStories();
        // assert
        verify(mockUpdateLocalDataSource.cacheUpdate());
      });

      test('should return server failure when the call to remote data source was unsuccessful', () async {
        // arrange
        when(mockStoriesRemoteDataSource.getStories()).thenThrow(ServerException());
        // act
        final result = await repository.getStories();
        // assert
        verifyZeroInteractions(mockStoriesLocalDataSource);
        expect(result, equals(Left(ServerFailure())));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return a last locally cashed data when cached data is present', () async {
        // arrange
        when(mockStoriesLocalDataSource.getStories()).thenAnswer((_) async => tStoriesModel);
        // act
        final result = await repository.getStories();
        // assert
        verifyZeroInteractions(mockStoriesRemoteDataSource);
        verify(mockStoriesLocalDataSource.getStories());
        expect(result, equals(Right(tStories)));
      });

      test('should return ChacheFailure when there is no cached data is present', () async {
        // arrange
        when(mockStoriesLocalDataSource.getStories()).thenThrow(CacheException());
        // act
        final result = await repository.getStories();
        // assert
        verifyZeroInteractions(mockStoriesRemoteDataSource);
        verify(mockStoriesLocalDataSource.getStories());
        expect(result, equals(Left(CacheFailure())));
      });
    });
  });
}
