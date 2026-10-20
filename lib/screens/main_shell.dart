import 'package:flutter/material.dart';
import '../data/plan_repository.dart';
import 'account_screen.dart';
import 'add_transaction_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshTick = 0;

  static const _pages = [
    HomeScreen(),
    AccountScreen(),
    PlanScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _runDuePlans();
  }

  /// 启动时把到期的周期账自动记入流水。
  Future<void> _runDuePlans() async {
    final n = await PlanRepository().runDuePlans();
    if (n > 0 && mounted) setState(() => _refreshTick++);
  }

  Future<void> _addTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    // 记账返回后重建当前页，刷新流水与余额
    if (mounted) setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey('$_index-$_refreshTick'),
        child: _pages[_index],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        child: Row(
          children: [
            Expanded(child: _navItem(0, Icons.home_outlined, Icons.home, '首页')),
            Expanded(child: _navItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, '账户')),
            const Expanded(child: SizedBox()),
            Expanded(child: _navItem(2, Icons.event_note_outlined, Icons.event_note, '计划')),
            Expanded(child: _navItem(3, Icons.person_outline, Icons.person, '我的')),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _index == index;
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
