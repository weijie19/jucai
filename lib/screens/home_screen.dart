import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import '../models/account.dart';
import '../models/models.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';
import 'account_screen.dart';
import 'add_transaction_screen.dart';
import 'category_screen.dart';
import 'import_screen.dart';
import 'settings_screen.dart';
import 'transfer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _txRepo = TransactionRepository();
  final _catRepo = CategoryRepository();
  final _accountRepo = AccountRepository();

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  int _expense = 0;
  int _income = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final now = DateTime.now();
    final txs = await _txRepo.getByMonth(now.year, now.month);
    final cats = await _catRepo.getAll();
    final accounts = await _accountRepo.getAll();
    final expense = await _txRepo.sumByMonth(TxType.expense, now.year, now.month);
    final income = await _txRepo.sumByMonth(TxType.income, now.year, now.month);
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _categories = cats;
      _accounts = accounts;
      _expense = expense;
      _income = income;
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

  String _accountName(int? id) {
    if (id == null) return '';
    for (final a in _accounts) {
      if (a.id == id) return a.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    for (final t in _transactions) {
      groups.putIfAbsent(t.date, () => []).add(t);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('聚财'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()));
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummary(),
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('还没有记录，点右下角 + 开始记账'))
                      : ListView.builder(
                          itemCount: dates.length,
                          itemBuilder: (context, i) {
                            final date = dates[i];
                            final list = groups[date]!;
                            return _buildDayGroup(date, list);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          _reload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('本月支出'),
                const SizedBox(height: 4),
                Text('¥${formatCents(_expense)}', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('本月收入'),
                const SizedBox(height: 4),
                Text('¥${formatCents(_income)}', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGroup(String date, List<Transaction> list) {
    var dayExpense = 0;
    for (final t in list) {
      if (t.type == TxType.expense) dayExpense += t.amountCents;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: Theme.of(context).textTheme.labelLarge),
              Text('支出 ¥${formatCents(dayExpense)}', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
        ...list.map((t) {
          final cat = _catOf(t.categoryId);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cat != null ? Color(cat.color) : Colors.grey,
              child: Icon(iconFor(cat?.icon ?? 'more_horiz'), color: Colors.white, size: 20),
            ),
            title: Text(_catName(t.categoryId)),
            subtitle: Text([t.note, _accountName(t.accountId)].where((s) => s != null && s.isNotEmpty).join(' · ')),
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
