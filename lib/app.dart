import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/network/supabase_client_provider.dart';
import 'core/router/app_screen.dart';
import 'core/router/flow_cubit.dart';
import 'core/router/flow_state.dart';
import 'core/services/first_launch_service.dart';
import 'core/services/push_service.dart';
import 'core/state/app_state.dart';
import 'core/state/app_state_cubit.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/toast_overlay.dart';
import 'core/widgets/xp_float_overlay.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/entities/auth_state.dart';
import 'features/auth/presentation/blocs/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/drinks_age_gate_screen.dart';
import 'features/auth/presentation/screens/email_login_screen.dart';
import 'features/auth/presentation/screens/email_signup_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/gamification_tutorial_screen.dart';
import 'features/auth/presentation/screens/onboarding_cuisine_screen.dart';
import 'features/auth/presentation/screens/onboarding_dietary_screen.dart';
import 'features/auth/presentation/screens/onboarding_skill_screen.dart';
import 'features/auth/presentation/screens/profile_setup_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/welcome_gate_screen.dart';
import 'features/content/data/repositories/content_repository_impl.dart';
import 'features/content/presentation/blocs/content_cubit.dart';
import 'features/content/presentation/screens/place_detail_screen.dart';
import 'features/content/presentation/screens/recipe_detail_screen.dart';
import 'features/cooking/presentation/screens/cook_mode_screen.dart';
import 'features/cooking/presentation/screens/post_cook_screen.dart';
import 'features/gamification/presentation/screens/cooking_level_screen.dart';
import 'features/gamification/presentation/screens/meal_reminder_screen.dart';
import 'features/gamification/presentation/screens/tip_flow_screen.dart';
import 'features/genie/presentation/screens/genie_chat_screen.dart';
import 'features/genie/presentation/screens/genie_filter_screen.dart';
import 'features/genie/presentation/screens/genie_meals_screen.dart';
import 'features/genie/presentation/screens/genie_planner_screen.dart';
import 'features/genie/presentation/screens/genie_scan_screen.dart';
import 'features/genie/presentation/screens/genie_screen.dart';
import 'features/genie/presentation/screens/meal_builder_screen.dart';
import 'features/home/presentation/screens/swipe_deck_screen.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/blocs/notifications_cubit.dart';
import 'features/social/data/follow_repository.dart';
import 'features/social/presentation/blocs/follow_cubit.dart';
import 'features/profile/presentation/screens/community_impact_screen.dart';
import 'features/profile/presentation/screens/competition_screen.dart';
import 'features/profile/presentation/screens/creator_create_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/elo_voting_screen.dart';
import 'features/profile/presentation/screens/premium_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/saved_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/social/presentation/screens/chat_list_screen.dart';
import 'features/social/presentation/screens/chat_thread_screen.dart';
import 'features/social/presentation/screens/creator_profile_screen.dart';
import 'features/social/presentation/screens/notification_center_screen.dart';
import 'features/social/presentation/screens/share_action_sheet_screen.dart';
import 'features/social/presentation/screens/social_feed_screen.dart';

/// Root widget — owns Supabase bootstrapping and app-wide providers.
class BiteApp extends StatefulWidget {
  const BiteApp({super.key});

  @override
  State<BiteApp> createState() => _BiteAppState();
}

class _BiteAppState extends State<BiteApp> {
  /// null = booting, true = ready, false = init failed (config error).
  bool? _ready;

  @override
  void initState() {
    super.initState();
    _ready = null;
    _init();
  }

  Future<void> _init() async {
    try {
      await SupabaseClientProvider.instance.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('[bite] Supabase init failed: $e');
      if (mounted) setState(() => _ready = false);
    }
  }

  Future<void> _retry() async {
    setState(() => _ready = null);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: switch (_ready) {
        null => const _BootScreen(),
        false => ConfigErrorScreen(onRetry: _retry),
        true => const BiteShell(),
      },
    );
  }
}

/// Holds the app's global BlocProviders. Mounted only after Supabase is ready.
class BiteShell extends StatefulWidget {
  const BiteShell({super.key});

  @override
  State<BiteShell> createState() => _BiteShellState();
}

class _BiteShellState extends State<BiteShell> {
  late final AuthRepositoryImpl _authRepository;
  late final ContentRepositoryImpl _contentRepository;
  late final NotificationRepository _notificationRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl();
    _contentRepository = ContentRepositoryImpl();
    _notificationRepository = NotificationRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(_authRepository)),
        BlocProvider<ContentCubit>(
          create: (_) => ContentCubit(_contentRepository),
        ),
        BlocProvider<AppStateCubit>(create: (_) => AppStateCubit()),
        RepositoryProvider<NotificationRepository>.value(
          value: _notificationRepository,
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => NotificationsCubit(_notificationRepository),
        ),
        BlocProvider<FollowCubit>(
          create: (_) => FollowCubit(FollowRepository()),
        ),
        // First launch opens on the welcome gate; later launches on splash.
        BlocProvider<FlowCubit>(
          create: (_) => FlowCubit(
            initial: FirstLaunchService.instance.isFirstLaunch
                ? AppScreen.welcome
                : AppScreen.splash,
          ),
        ),
      ],
      child: const _FlowHost(),
    );
  }
}

/// Routes [FlowState.screen] to its widget and reacts to auth changes
/// (session resume, post-login routing, sign-out).
class _FlowHost extends StatefulWidget {
  const _FlowHost();

  @override
  State<_FlowHost> createState() => _FlowHostState();
}

class _FlowHostState extends State<_FlowHost> {
  bool _wasAuthenticated = false;

  /// Last gamification snapshot written to `profiles`.
  Map<String, dynamic>? _lastSynced;
  Timer? _syncTimer;

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    final flow = context.read<FlowCubit>();
    final userId = state.user?.id;
    context.read<ContentCubit>().bind(userId);
    context.read<NotificationsCubit>().bind(userId);
    context.read<FollowCubit>().bind(userId);
    if (state.authenticated && !state.loading) {
      final profile = state.profile;
      final appState = context.read<AppStateCubit>();
      if (profile != null && !appState.state.hydrated) {
        appState.hydrateFromProfile(profile);
        _lastSynced = _normalize(appState.persistedFields);
      }
      if (userId != null) {
        PushService.instance.attach(
          userId: userId,
          repository: context.read<NotificationRepository>(),
          onOpen: _openFromPush,
          onForegroundMessage: context.read<NotificationsCubit>().refresh,
        );
      }
      final wasAuthed = _wasAuthenticated;
      _wasAuthenticated = true;
      if (!wasAuthed) {
        flow.resetTo(
          state.needsOnboarding ? AppScreen.profileSetup : AppScreen.swipeDeck,
        );
      }
    } else if (!state.authenticated) {
      final wasAuthed = _wasAuthenticated;
      _wasAuthenticated = false;
      if (wasAuthed) {
        _syncTimer?.cancel();
        _lastSynced = null;
        PushService.instance.detach();
        context.read<AppStateCubit>().resetToGuest();
        flow.resetTo(AppScreen.auth);
      }
    }
  }

  /// Persist XP / coins / streak / badges shortly after they change so
  /// progress survives restarts and shows on every screen.
  void _onAppStateChanged(BuildContext context, AppState state) {
    final auth = context.read<AuthCubit>();
    if (!state.hydrated || !auth.state.authenticated) return;
    final fields = context.read<AppStateCubit>().persistedFields;
    if (_lastSynced != null && mapEquals(_lastSynced, _normalize(fields))) {
      return;
    }
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final latest = context.read<AppStateCubit>().persistedFields;
      _lastSynced = _normalize(latest);
      auth.saveFields(latest);
    });
  }

  /// Lists compare by identity in [mapEquals]; join them for comparison.
  static Map<String, dynamic> _normalize(Map<String, dynamic> m) => {
        for (final e in m.entries)
          e.key: e.value is List ? (e.value as List).join('|') : e.value,
      };

  /// Push tapped → open its destination (recipe id when present).
  void _openFromPush(String? actionDest, Map<String, dynamic> data) {
    if (!mounted) return;
    final recipeId = (data['recipe_id'] as num?)?.toInt();
    if (recipeId != null) {
      final card = context.read<ContentCubit>().state.findCard(recipeId);
      if (card != null) {
        context.read<AppStateCubit>().viewRecipe(card);
        context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
        return;
      }
    }
    context.read<FlowCubit>().setScreen(AppScreen.notifications);
  }

  /// Leaving onboarding for the main app (tutorial finished or "skip all")
  /// marks the user onboarded so the next login goes straight to home.
  void _onFlowChanged(BuildContext context, FlowState state) {
    final auth = context.read<AuthCubit>();
    if (auth.state.authenticated) auth.markOnboarded();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(listener: _onAuthChanged),
        BlocListener<AppStateCubit, AppState>(listener: _onAppStateChanged),
        BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (a, b) => a.unreadCount != b.unreadCount,
          listener: (context, s) => context
              .read<AppStateCubit>()
              .setNotificationCount(s.unreadCount),
        ),
        BlocListener<FlowCubit, FlowState>(
          listenWhen: (prev, curr) =>
              prev.screen.isAuthOrOnboarding && !curr.screen.isAuthOrOnboarding,
          listener: _onFlowChanged,
        ),
      ],
      child: BlocBuilder<FlowCubit, FlowState>(
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _screenFor(state.screen),
              const ToastOverlay(),
              const XpFloatOverlay(),
              _TransitionOverlay(visible: state.transitionVisible),
            ],
          );
        },
      ),
    );
  }
}

/// Maps an [AppScreen] to its widget. Screens not yet ported fall back to
/// a "coming soon" placeholder.
Widget _screenFor(AppScreen screen) {
  return switch (screen) {
    AppScreen.splash => const SplashScreen(),
    AppScreen.welcome => const WelcomeGateScreen(),
    AppScreen.auth => const AuthScreen(),
    AppScreen.emailLogin => const EmailLoginScreen(),
    AppScreen.emailSignup => const EmailSignupScreen(),
    AppScreen.forgotPassword => const ForgotPasswordScreen(),
    AppScreen.profileSetup => const ProfileSetupScreen(),
    AppScreen.onboardingCuisine => const OnboardingCuisineScreen(),
    AppScreen.onboardingDietary => const OnboardingDietaryScreen(),
    AppScreen.onboardingSkill => const OnboardingSkillScreen(),
    AppScreen.gamificationTutorial => const GamificationTutorialScreen(),
    AppScreen.drinksAgeGate => const DrinksAgeGateScreen(),
    AppScreen.swipeDeck => const SwipeDeckScreen(),

    AppScreen.recipeDetail => const RecipeDetailScreen(),
    AppScreen.placeDetail => const PlaceDetailScreen(),
    AppScreen.cookMode => const CookModeScreen(),
    AppScreen.postCook => const PostCookScreen(),

    AppScreen.socialFeed => const SocialFeedScreen(),
    AppScreen.chatList => const ChatListScreen(),
    AppScreen.chatThread => const ChatThreadScreen(),
    AppScreen.creatorProfile => const CreatorProfileScreen(),
    AppScreen.shareSheet => const ShareActionSheet(),
    AppScreen.notifications => const NotificationCenterScreen(),

    AppScreen.genie => const GenieScreen(),
    AppScreen.genieChat => const GenieChatScreen(),
    AppScreen.genieFilter => const GenieFilterScreen(),
    AppScreen.mealBuilder => const MealBuilderScreen(),
    AppScreen.geniePlanner => const GeniePlannerScreen(),
    AppScreen.genieMeals => const GenieMealsScreen(),
    AppScreen.genieScan => const GenieScanScreen(),

    AppScreen.saved => const SavedScreen(),
    AppScreen.premium => const PremiumScreen(),
    AppScreen.profile => const ProfileScreen(),
    AppScreen.communityImpact => const CommunityImpactScreen(),
    AppScreen.editProfile => const EditProfileScreen(),
    AppScreen.settings => const SettingsScreen(),
    AppScreen.creatorCreate => const CreatorCreateScreen(),
    AppScreen.competition => const CompetitionScreen(),
    AppScreen.eloVoting => const EloVotingScreen(),

    AppScreen.cookingLevel => const CookingLevelScreen(),
    AppScreen.tipFlow => const TipFlowScreen(),
    AppScreen.mealReminder => const MealReminderScreen(),
  };
}

/// Full-screen fade used during FlowCubit transitions.
/// Fades in (120ms) while the old screen is visible, fades out (140ms)
/// revealing the new screen — mirrors the JS transition timing.
class _TransitionOverlay extends StatefulWidget {
  const _TransitionOverlay({required this.visible});

  final bool visible;

  @override
  State<_TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<_TransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FlowCubit.fadeIn,
      value: widget.visible ? 1 : 0,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(_TransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.duration = FlowCubit.fadeIn;
      _controller.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.duration = FlowCubit.fadeOut;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: FadeTransition(
        opacity: _opacity,
        child: const ColoredBox(color: Color(0xFF0D0D0D)),
      ),
    );
  }
}

/// Shown while Supabase initializes.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(child: Text('🌶', style: TextStyle(fontSize: 56))),
    );
  }
}

/// Shown when Supabase can't be initialized (missing/misconfigured env).
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Supabase isn\'t configured',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set SUPABASE_URL and SUPABASE_ANON_KEY in a .env file and '
                  'run with --dart-define-from-file=.env',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
