import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import 'add_transaction_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final _txRepo = TransactionRepository();
  final _accountRepo = AccountRepository();
  final _catRepo = CategoryRepository();

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  int _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final txs = await _txRepo.getByAccount(widget.account.id!);
    final cats = await _catRepo.getAll();
    final balance = await _accountRepo.balance(widget.account.id!);
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _categories = cats;
      _balance = balance;
      _loading = false;
    });
  }

  String _catName(int id) {
    for (final c in _categories) {
      if (c.id == id) return c.name;
    }
    return '未分类';
  }

  Category? _catOf(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    for (final t in _transactions) {
      groups.putIfAbsent(t.date, () => []).add(t);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(widget.account.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('该账户暂无流水'))
                      : ListView.builder(
                          itemCount: dates.length,
                          itemBuilder: (context, i) {
                            final date = dates[i];
                            return _buildDayGroup(date, groups[date]!);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('当前余额'),
              Text('¥${formatCents(_balance)}', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayGroup(String date, List<Transaction> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(date, style: Theme.of(context).textTheme.labelLarge),
        ),
        ...list.map((t) {
          final cat = _catOf(t.categoryId);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cat != null ? Color(cat.color) : Colors.grey,
              child: Icon(iconFor(cat?.icon ?? 'more_horiz'), color: Colors.white, size: 20),
            ),
            title: Text(_catName(t.categoryId)),
            subtitle: Text([t.time, t.note].where((s) => s != null && s.isNotEmpty).join(' · ')),
            trailing: Text(
              '${t.type == TxType.income ? '+' : '-'}${formatCents(t.amountCents)}',
              style: TextStyle(
                color: t.type == TxType.income ? Colors.green : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: t)),
              );
              _reload();
            },
            onLongPress: () => _confirmDelete(t),
          );
        }),
      ],
    );
  }

  Future<void> _confirmDelete(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _txRepo.delete(t.id!);
      _reload();
    }
  }
}
