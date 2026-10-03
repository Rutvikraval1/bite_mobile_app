import 'dart:async';

import 'package:bite/core/router/flow_cubit.dart';
import 'package:bite/core/state/app_state_cubit.dart';
import 'package:bite/features/auth/domain/entities/auth_result.dart';
import 'package:bite/features/auth/domain/entities/profile.dart';
import 'package:bite/features/auth/domain/repositories/auth_repository.dart';
import 'package:bite/features/auth/presentation/blocs/auth_cubit.dart';
import 'package:bite/features/content/domain/entities/bite_card.dart';
import 'package:bite/features/content/domain/entities/cook_entry.dart';
import 'package:bite/features/content/domain/entities/meal_plan.dart';
import 'package:bite/features/content/domain/entities/recipe_draft.dart';
import 'package:bite/features/content/domain/entities/saved_item.dart';
import 'package:bite/features/content/domain/repositories/content_repository.dart';
import 'package:bite/features/content/presentation/blocs/content_cubit.dart';
import 'package:bite/features/home/presentation/screens/swipe_deck_screen.dart';
import 'package:bite/features/social/data/follow_repository.dart';
import 'package:bite/features/social/presentation/blocs/follow_cubit.dart';
import 'package:bite/features/home/presentation/widgets/deck_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> streamAuthUser() => Stream.value(null);

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async =>
      const AuthResult();

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name = '',
    String username = '',
  }) async =>
      const AuthResult();

  @override
  Future<AuthResult> signInWithProvider(AuthProviderType provider) async =>
      const AuthResult();

  @override
  Future<AuthResult> resetPassword(String email) async => const AuthResult();

  @override
  Future<AuthResult> markOnboarded() async => const AuthResult();

  @override
  Future<AuthResult> updateEmail(String newEmail) async => const AuthResult();

  @override
  Future<AuthResult> updatePassword(String newPassword) async =>
      const AuthResult();

  @override
  Future<AuthResult> deleteAccount() async => const AuthResult();

  @override
  Future<AuthResult> signOut() async => const AuthResult();

  @override
  Future<ProfileResult> fetchProfile(String userId) async =>
      const ProfileResult.success(Profile(id: 'u1', avatarEmoji: '🧑‍🍳'));

  @override
  Future<ProfileWriteResult> createProfile(
    String userId, {
    String displayName = '',
    String username = '',
  }) async =>
      ProfileWriteResult.ok;

  @override
  Future<ProfileWriteResult> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async =>
      ProfileWriteResult.ok;
}

class _FakeContentRepo implements ContentRepository {
  @override
  Future<List<BiteCard>> fetchMyRecipes(String userId) async => const [];

  @override
  Future<ContentWriteResult<BiteCard>> createRecipe(
    String userId,
    String creator,
    RecipeDraft draft,
  ) async =>
      const ContentWriteResult.ok();

  @override
  Future<ContentWriteResult> deleteRecipe(String userId, int recipeId) async =>
      const ContentWriteResult.ok();

  @override
  Future<List<CookEntry>> fetchCookHistory(String userId) async => const [];

  @override
  Future<ContentWriteResult> logCook(
    String userId, {
    required String title,
    required String emoji,
    int? recipeId,
    String? imageUrl,
    int? rating,
  }) async =>
      const ContentWriteResult.ok();

  static final recipes = [
    const BiteCard(
      id: 1,
      title: 'Pesto Pasta',
      creator: 'Chef Ana',
      time: '25 min',
      diff: 'Easy',
      serves: 2,
      heat: 1,
      saved: '1.2K',
      hearts: '4.5K',
      comments: 120,
      emoji: '🍝',
      cuisine: 'Italian',
      gradient: 'linear-gradient(135deg,#ff7e5f,#feb47b)',
      tags: ['quick', 'dinner'],
    ),
    const BiteCard(
      id: 2,
      title: 'Spicy Ramen',
      creator: 'Chef Ken',
      time: '40 min',
      diff: 'Medium',
      serves: 2,
      heat: 4,
      saved: '3K',
      hearts: '9K',
      comments: 300,
      emoji: '🍜',
      cuisine: 'Japanese',
      gradient: 'linear-gradient(135deg,#ff5f6d,#ffc371)',
    ),
  ];

  static final drinks = [
    const BiteCard(
      id: 11,
      title: 'Mango Mule',
      creator: 'Bar Lou',
      time: '5 min',
      diff: 'Easy',
      serves: 1,
      heat: 0,
      saved: '800',
      hearts: '2K',
      comments: 40,
      emoji: '🥭',
      cuisine: 'Cocktail',
      gradient: 'linear-gradient(135deg,#f7971e,#ffd200)',
    ),
  ];

  static final places = [
    const BiteCard(
      id: 21,
      title: 'The Golden Fork',
      creator: 'Golden Fork',
      time: 'Open',
      diff: r'$$',
      serves: 4,
      heat: 2,
      saved: '500',
      hearts: '1K',
      comments: 25,
      emoji: '🍽',
      cuisine: 'Modern',
      gradient: 'linear-gradient(135deg,#7F00FF,#E100FF)',
      address: '123 Main St',
      status: 'Open',
      distance: '0.4 mi',
      menuHighlights: [MenuHighlight(name: 'Truffle Fries', price: '\$12')],
    ),
  ];

  @override
  Future<ContentCatalog> fetchContent() async => ContentCatalog(
        recipes: _FakeContentRepo.recipes,
        drinks: _FakeContentRepo.drinks,
        places: _FakeContentRepo.places,
      );

  @override
  List<BiteCard> deckFor(String subTab, ContentCatalog catalog) =>
      switch (subTab) {
        'drinks' => catalog.drinks,
        'places' => catalog.places,
        _ => catalog.recipes,
      };

  @override
  Future<List<SavedItem>> fetchSavedItems(String userId) async => const [];

  @override
  Future<ContentWriteResult> saveItem(
    String userId,
    BiteCard card,
    String itemType,
  ) async =>
      ContentWriteResult.ok();

  @override
  Future<ContentWriteResult> removeSavedItem(String userId, String id) async =>
      ContentWriteResult.ok();

  @override
  Future<MealCalendar> fetchMealPlans(String userId) async => const {};

  @override
  Future<ContentWriteResult<MealPlan>> addMealPlan(
    String userId, {
    required String planDate,
    required String mealSlot,
    required String title,
    required String emoji,
    required String color,
  }) async =>
      ContentWriteResult.ok(MealPlan(
        id: 'm1',
        planDate: planDate,
        mealSlot: mealSlot,
        title: title,
        emoji: emoji,
      ));

  @override
  Future<ContentWriteResult> removeMealPlan(String userId, String mealId) async =>
      ContentWriteResult.ok();

  @override
  Future<void> recordSwipe(
    String userId, {
    required String itemType,
    required int itemId,
    required String action,
    String? cuisine,
  }) async {}
}

Widget _wrap() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>(create: (_) => AuthCubit(_FakeAuthRepo())),
      BlocProvider<ContentCubit>(
          create: (_) => ContentCubit(_FakeContentRepo())),
      BlocProvider<AppStateCubit>(create: (_) => AppStateCubit()),
      BlocProvider<FlowCubit>(create: (_) => FlowCubit()),
      // Never bound to a user in tests, so it makes no network calls.
      BlocProvider<FollowCubit>(create: (_) => FollowCubit(FollowRepository())),
    ],
    child: const MaterialApp(home: SwipeDeckScreen()),
  );
}

Future<void> _pumpDeck(WidgetTester tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _flushPendingTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  testWidgets('swipe deck renders food card and saves on swipe-up',
      (tester) async {
    await _pumpDeck(tester);

    final ctx = tester.element(find.byType(SwipeDeckScreen));
    final app = BlocProvider.of<AppStateCubit>(ctx);
    final before = app.state.xp;

    final first = tester.widget<DeckCard>(find.byType(DeckCard));
    expect(first.card.title, 'Pesto Pasta');

    await tester.drag(
        find.byType(SwipeDeckScreen), const Offset(0, -130));
    await tester.pump();

    expect(app.state.xp, before + 8, reason: 'save awards +8 XP');

    await tester.pump(const Duration(milliseconds: 600));
    final second = tester.widget<DeckCard>(find.byType(DeckCard));
    expect(second.card.title, 'Spicy Ramen');

    await _flushPendingTimers(tester);
  });

  testWidgets('swipe deck passes on swipe-down and awards +4 XP',
      (tester) async {
    await _pumpDeck(tester);

    final ctx = tester.element(find.byType(SwipeDeckScreen));
    final app = BlocProvider.of<AppStateCubit>(ctx);
    final before = app.state.xp;

    await tester.drag(
        find.byType(SwipeDeckScreen), const Offset(0, 130));
    await tester.pump();

    expect(app.state.xp, before + 4, reason: 'pass awards +4 XP');

    await tester.pump(const Duration(milliseconds: 600));
    final second = tester.widget<DeckCard>(find.byType(DeckCard));
    expect(second.card.title, 'Spicy Ramen');

    await _flushPendingTimers(tester);
  });

  testWidgets('switching sub-tabs shows drinks and places', (tester) async {
    await _pumpDeck(tester);

    final ctx = tester.element(find.byType(SwipeDeckScreen));
    final app = BlocProvider.of<AppStateCubit>(ctx);
    app.setAgeVerified(true);
    app.setLocationGranted(true);
    await tester.pump();

    await tester.tap(find.text('Drinks'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester.widget<DeckCard>(find.byType(DeckCard)).card.title,
      'Mango Mule',
    );

    await tester.tap(find.text('Places'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester.widget<DeckCard>(find.byType(DeckCard)).card.title,
      'The Golden Fork',
    );

    await _flushPendingTimers(tester);
  });
}
