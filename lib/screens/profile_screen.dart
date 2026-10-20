import 'package:flutter/material.dart';
import 'budget_screen.dart';
import 'category_screen.dart';
import 'debt_screen.dart';
import 'import_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'tag_screen.dart';
import 'transfer_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          _section('记账工具'),
          _tile(context, Icons.swap_horiz, '转账', () => _push(context, const TransferScreen())),
          _tile(context, Icons.savings_outlined, '预算', () => _push(context, const BudgetScreen())),
          _tile(context, Icons.handshake_outlined, '借贷', () => _push(context, const DebtScreen())),
          _tile(context, Icons.sell_outlined, '标签', () => _push(context, const TagScreen())),
          _tile(context, Icons.category_outlined, '分类管理', () => _push(context, const CategoryScreen())),
          _section('统计与数据'),
          _tile(context, Icons.pie_chart_outline, '报表', () => _push(context, const ReportScreen())),
          _tile(context, Icons.file_upload_outlined, '账单导入', () => _push(context, const ImportScreen())),
          _tile(context, Icons.settings_outlined, '设置与备份', () => _push(context, const SettingsScreen())),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
