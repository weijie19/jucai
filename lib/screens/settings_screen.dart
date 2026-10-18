import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../data/budget_repository.dart';
import '../data/category_repository.dart';
import '../data/transaction_repository.dart';
import '../data/transfer_repository.dart';
import '../services/backup.dart';
import '../services/webdav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrl = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await loadWebDavConfig();
    if (cfg != null) {
      _baseUrl.text = cfg.baseUrl;
      _user.text = cfg.username;
      _password.text = cfg.password;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final cfg = WebDavConfig(
      baseUrl: _baseUrl.text.trim(),
      username: _user.text.trim(),
      password: _password.text.trim(),
    );
    await saveWebDavConfig(cfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
  }

  Future<void> _backup() async {
    final cfg = await loadWebDavConfig();
    if (cfg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写并保存 NAS 配置')));
      return;
    }
    setState(() => _busy = true);
    try {
      final txRepo = TransactionRepository();
      final catRepo = CategoryRepository();
      final data = BackupData(
        categories: await catRepo.getAll(),
        transactions: await txRepo.getAll(),
        accounts: await AccountRepository().getAll(),
        transfers: await TransferRepository().getAll(),
        budgets: await BudgetRepository().getAll(),
      );
      await uploadBackup(cfg, encodeBackup(data));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('备份成功')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final cfg = await loadWebDavConfig();
    if (cfg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写并保存 NAS 配置')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从 NAS 恢复？'),
        content: const Text('将覆盖当前所有数据（会先做一次本地备份）。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('恢复')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final json = await downloadBackup(cfg);
      final data = decodeBackup(json);
      await _importData(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恢复成功')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importData(BackupData data) async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final accountRepo = AccountRepository();
    final transferRepo = TransferRepository();
    final budgetRepo = BudgetRepository();

    await txRepo.deleteAll();
    await transferRepo.deleteAll();
    await budgetRepo.deleteAll();
    await catRepo.deleteAll();
    await accountRepo.deleteAll();

    for (final c in data.categories) {
      await catRepo.insert(c);
    }
    for (final a in data.accounts) {
      await accountRepo.insert(a);
    }
    for (final t in data.transactions) {
      await txRepo.insert(t);
    }
    for (final t in data.transfers) {
      await transferRepo.insert(t);
    }
    for (final b in data.budgets) {
      await budgetRepo.upsert(b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置与备份')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('飞牛 NAS WebDAV 配置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(labelText: 'WebDAV 地址', hintText: 'https://nas.example.com:5006'),
          ),
          TextField(
            controller: _user,
            decoration: const InputDecoration(labelText: '用户名'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _saveConfig, child: const Text('保存配置')),
          const Divider(height: 32),
          FilledButton.icon(
            onPressed: _busy ? null : _backup,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('立即备份到 NAS'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('从 NAS 恢复'),
          ),
        ],
      ),
    );
  }
}
