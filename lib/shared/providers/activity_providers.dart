import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';

/// One row of the chat list.
class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.otherId,
    required this.name,
    required this.role,
    required this.company,
    required this.context,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  final String id;
  final String otherId;
  final String name;

  /// The other person's role: jobSeeker / freelancer / student / employer
  /// (user app) or recruiter / client / both (recruiter app).
  final String role;
  final String company;
  final String context;
  final String lastMessage;
  final DateTime? lastAt;
  final int unread;

  factory ChatSummary.fromJson(Map<String, dynamic> j) {
    final o = jMap(j['other']);
    return ChatSummary(
      id: jStr(j['id']),
      otherId: jStr(o['id']),
      name: jStr(o['name'], 'User'),
      role: jStr(o['role']),
      company: jStr(o['company']),
      context: jStr(j['context']),
      lastMessage: jStr(j['lastMessage']),
      lastAt: jDate(j['lastAt'])?.toLocal(),
      unread: jInt(j['unread']),
    );
  }

  /// "09:41 AM", "Yesterday", "Mon", "12 Oct".
  String get timeLabel {
    final t = lastAt;
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat('hh:mm a').format(t);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(t);
    return DateFormat('d MMM').format(t);
  }
}

final chatListProvider = FutureProvider.autoDispose<List<ChatSummary>>((
  ref,
) async {
  ref.watch(sessionUserIdProvider);
  return jMapList(await api.get('/chats')).map(ChatSummary.fromJson).toList();
});

/// Someone you can start a conversation with.
class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.headline,
  });

  final String id;
  final String name;
  final String role;
  final String company;
  final String headline;
}

final chatContactsProvider = FutureProvider.autoDispose<List<ChatContact>>((
  ref,
) async {
  ref.watch(sessionUserIdProvider);
  return [
    for (final c in jMapList(await api.get('/chats/contacts')))
      ChatContact(
        id: jStr(c['id']),
        name: jStr(c['name']),
        role: jStr(c['role']),
        company: jStr(c['company']),
        headline: jStr(c['headline']),
      ),
  ];
});

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.ref,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;

  /// Id of the related document (application, contract, job…).
  final String ref;
  final bool isRead;
  final DateTime? createdAt;

  bool get isToday {
    final t = createdAt;
    if (t == null) return false;
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: jStr(j['id']),
    type: jStr(j['type']),
    title: jStr(j['title']),
    message: jStr(j['message']),
    ref: jStr(j['ref']),
    isRead: jBool(j['isRead']),
    createdAt: jDate(j['createdAt'])?.toLocal(),
  );

  AppNotification read() => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    ref: ref,
    isRead: true,
    createdAt: createdAt,
  );
}

class NotificationsState {
  const NotificationsState({this.items = const [], this.loaded = false});

  final List<AppNotification> items;
  final bool loaded;

  int get unread => items.where((n) => !n.isRead).length;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier({bool autoLoad = true})
    : super(const NotificationsState()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    try {
      final d = jMap(await api.get('/notifications'));
      if (mounted) {
        state = NotificationsState(
          items: jMapList(d['items']).map(AppNotification.fromJson).toList(),
          loaded: true,
        );
      }
    } on ApiException catch (_) {
      if (mounted) state = NotificationsState(items: state.items, loaded: true);
    }
  }

  Future<void> markRead(String id) async {
    state = NotificationsState(
      items: [for (final n in state.items) n.id == id ? n.read() : n],
      loaded: true,
    );
    try {
      await api.patch('/notifications/$id/read');
    } on ApiException catch (_) {}
  }

  Future<void> markAllRead() async {
    await api.patch('/notifications/read-all');
    state = NotificationsState(
      items: [for (final n in state.items) n.read()],
      loaded: true,
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      final userId = ref.watch(sessionUserIdProvider);
      return NotificationsNotifier(autoLoad: userId != null);
    });
