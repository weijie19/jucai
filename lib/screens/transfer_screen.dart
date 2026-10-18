import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/account_repository.dart';
import '../data/transfer_repository.dart';
import '../models/account.dart';
import '../models/transfer.dart';
import '../services/amount.dart';
import '../widgets/category_icons.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _accountRepo = AccountRepository();
  final _transferRepo = TransferRepository();

  List<Account> _accounts = [];
  int? _fromId;
  int? _toId;
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _accountRepo.getAll();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      if (accounts.length >= 2) {
        _fromId = accounts[0].id;
        _toId = accounts[1].id;
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先创建至少两个账户')));
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('转出和转入账户不能相同')));
      return;
    }
    final cents = parseAmountToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    final fee = parseAmountToCents(_feeController.text) ?? 0;
    final t = Transfer(
      fromAccountId: _fromId!,
      toAccountId: _toId!,
      amountCents: cents,
      feeCents: fee,
      date: DateFormat('yyyy-MM-dd').format(_date),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    await _transferRepo.insert(t);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('转账')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.length < 2
              ? const Center(child: Text('需要至少两个账户才能转账，请先在「账户」里添加。'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('转出账户', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _accountPicker(_fromId, (id) => setState(() => _fromId = id)),
                    const SizedBox(height: 24),
                    Text('转入账户', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _accountPicker(_toId, (id) => setState(() => _toId = id)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28),
                      decoration: const InputDecoration(prefixText: '¥ ', hintText: '0.00'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '手续费（可选）'),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text(DateFormat('yyyy-MM-dd').format(_date)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: '备注（可选）'),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('确认转账'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _accountPicker(int? selectedId, ValueChanged<int?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _accounts.map((a) {
        final selected = a.id == selectedId;
        return ChoiceChip(
          avatar: Icon(iconFor(a.icon), size: 18, color: selected ? Colors.white : Color(a.color)),
          label: Text(a.name),
          selected: selected,
          onSelected: (_) => onChanged(a.id),
        );
      }).toList(),
    );
  }
}
