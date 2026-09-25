/// 차단한 친구 — 계약서 BlockedUser
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.name,
    required this.blockedAt,
  });

  final String id;
  final String name;
  final DateTime blockedAt;
}
