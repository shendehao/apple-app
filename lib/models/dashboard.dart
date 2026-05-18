class DashboardStats {
  final int totalCards;
  final int unusedCards;
  final int usedCards;
  final int expiredCards;
  final int bannedCards;
  final int totalSoftware;
  final int todayEvents;

  DashboardStats({
    this.totalCards = 0,
    this.unusedCards = 0,
    this.usedCards = 0,
    this.expiredCards = 0,
    this.bannedCards = 0,
    this.totalSoftware = 0,
    this.todayEvents = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalCards: json['total_cards'] ?? 0,
    unusedCards: json['unused_cards'] ?? 0,
    usedCards: json['used_cards'] ?? 0,
    expiredCards: json['expired_cards'] ?? 0,
    bannedCards: json['banned_cards'] ?? 0,
    totalSoftware: json['total_software'] ?? 0,
    todayEvents: json['today_events'] ?? 0,
  );
}
