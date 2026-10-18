enum AccountType { cash, bankCard, alipay, wechat, creditCard, other }

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final String icon;
  final int color;
  final int initialBalanceCents;
  final int sortOrder;

  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.initialBalanceCents = 0,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'color': color,
        'initial_balance_cents': initialBalanceCents,
        'sort_order': sortOrder,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: AccountType.values.byName(m['type'] as String),
        icon: m['icon'] as String,
        color: m['color'] as int,
        initialBalanceCents: m['initial_balance_cents'] as int? ?? 0,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}

List<Account> defaultAccounts() => const [
      Account(name: '现金', type: AccountType.cash, icon: 'payments', color: 0xFF8D6E63, sortOrder: 1),
      Account(name: '支付宝', type: AccountType.alipay, icon: 'account_balance_wallet', color: 0xFF1E88E5, sortOrder: 2),
      Account(name: '微信', type: AccountType.wechat, icon: 'chat', color: 0xFF43A047, sortOrder: 3),
      Account(name: '银行卡', type: AccountType.bankCard, icon: 'credit_card', color: 0xFFF4511E, sortOrder: 4),
    ];
