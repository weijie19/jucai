import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../models/account.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import 'account_detail_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _repo = AccountRepository();
  List<Account> _accounts = [];
  Map<int, int> _balances = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final accounts = await _repo.getAll();
    final balances = <int, int>{};
    for (final a in accounts) {
      balances[a.id!] = await _repo.balance(a.id!);
    }
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _loading = false;
    });
  }

  Future<void> _edit([Account? existing]) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (_) => _AccountDialog(account: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _repo.insert(result);
    } else {
      await _repo.update(result);
    }
    _reload();
  }

  Future<void> _confirmDelete(Account a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除账户「${a.name}」？'),
        content: const Text('该账户下的流水不会删除，但会失去账户关联。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(a.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAssets = _balances.values.fold<int>(0, (sum, v) => sum + v);
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _edit()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('总资产'),
                        const SizedBox(height: 8),
                        Text('¥${formatCents(totalAssets)}',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._accounts.map((a) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(a.color),
                          child: Icon(iconFor(a.icon), color: Colors.white, size: 20),
                        ),
                        title: Text(a.name),
                        subtitle: Text('余额 ¥${formatCents(_balances[a.id] ?? 0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(a),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AccountDetailScreen(account: a)),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

class _AccountDialog extends StatefulWidget {
  final Account? account;
  const _AccountDialog({this.account});

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _name = TextEditingController(text: a?.name ?? '');
    _balance = TextEditingController(text: a == null ? '0.00' : formatCents(a.initialBalanceCents));
    _type = a?.type ?? AccountType.other;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? '新增账户' : '编辑账户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '账户名'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _balance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '初始余额（可选）'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AccountType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: '类型'),
            items: const [
              DropdownMenuItem(value: AccountType.cash, child: Text('现金')),
              DropdownMenuItem(value: AccountType.bankCard, child: Text('银行卡')),
              DropdownMenuItem(value: AccountType.alipay, child: Text('支付宝')),
              DropdownMenuItem(value: AccountType.wechat, child: Text('微信')),
              DropdownMenuItem(value: AccountType.creditCard, child: Text('信用卡')),
              DropdownMenuItem(value: AccountType.other, child: Text('其他')),
            ],
            onChanged: (v) => setState(() => _type = v ?? AccountType.other),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            final cents = parseAmountToCents(_balance.text) ?? 0;
            final a = Account(
              id: widget.account?.id,
              name: name,
              type: _type,
              icon: _iconFor(_type),
              color: _colorFor(_type),
              initialBalanceCents: cents,
              sortOrder: widget.account?.sortOrder ?? 100,
            );
            Navigator.pop(context, a);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _iconFor(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'payments';
      case AccountType.bankCard:
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.alipay:
        return 'account_balance_wallet';
      case AccountType.wechat:
        return 'chat';
      case AccountType.other:
        return 'account_balance';
    }
  }

  int _colorFor(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 0xFF8D6E63;
      case AccountType.bankCard:
        return 0xFFF4511E;
      case AccountType.creditCard:
        return 0xFFD81B60;
      case AccountType.alipay:
        return 0xFF1E88E5;
      case AccountType.wechat:
        return 0xFF43A047;
      case AccountType.other:
        return 0xFF90A4AE;
    }
  }
}
