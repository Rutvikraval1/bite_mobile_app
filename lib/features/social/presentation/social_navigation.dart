import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_screen.dart';
import '../../../core/router/flow_cubit.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/state/app_state_cubit.dart';
import '../../content/presentation/blocs/content_cubit.dart';
import '../data/chat_selection.dart';
import 'blocs/chat_cubit.dart';

/// Opens [CreatorProfileScreen] for [handle].
void openCreator(BuildContext context, String handle) {
  CreatorSelection.instance.select(handle);
  context.read<FlowCubit>().setScreen(AppScreen.creatorProfile);
}

/// Opens [ChatThreadScreen] for [ref].
void openThread(BuildContext context, ChatThreadRef ref) {
  ChatSelection.instance.select(ref);
  context.read<FlowCubit>().setScreen(AppScreen.chatThread);
}

/// Opens Recipe Detail for a catalog recipe. Returns false if it isn't loaded.
bool openRecipe(BuildContext context, int? recipeId) {
  if (recipeId == null) return false;
  final card = context.read<ContentCubit>().state.findCard(recipeId);
  if (card == null) return false;
  context.read<AppStateCubit>().viewRecipe(card);
  context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
  return true;
}

/// Starts (or reuses) a DM with [handle] and opens it.
Future<void> messageCreator(BuildContext context, String handle, {required String name}) async {
  final id = await context.read<ChatCubit>().startDm(handle);
  if (!context.mounted) return;
  if (id == null) {
    ToastService.instance.show("⚠️ Couldn't start a conversation. Try again.");
    return;
  }
  openThread(
    context,
    ChatThreadRef(
      conversationId: id,
      name: name,
      avatarLabel: name.isEmpty ? '?' : name[0].toUpperCase(),
      peerHandle: handle,
    ),
  );
}

/// Routes a notification / push payload that points at social content.
/// Returns true if it navigated.
bool openSocialTarget(BuildContext context, Map<String, dynamic> data) {
  final conversationId = data['conversation_id'] as String?;
  if (conversationId != null) {
    openThread(context, ChatThreadRef(conversationId: conversationId, name: '', avatarLabel: '💬'));
    return true;
  }
  final handle = data['handle'] as String?;
  if (handle != null) {
    openCreator(context, handle);
    return true;
  }
  if (data['post_id'] != null) {
    context.read<FlowCubit>().setScreen(AppScreen.socialFeed);
    return true;
  }
  return false;
}
