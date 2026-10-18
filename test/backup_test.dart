import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/account.dart';
import 'package:jucai/models/budget.dart';
import 'package:jucai/models/models.dart';
import 'package:jucai/models/transfer.dart';
import 'package:jucai/services/backup.dart';

void main() {
  test('备份 JSON 编解码往返一致', () {
    final data = BackupData(
      categories: const [
        Category(name: '餐饮', type: TxType.expense, icon: 'restaurant', color: 0xFFE57373, sortOrder: 1),
      ],
      transactions: [
        Transaction(
          type: TxType.expense,
          amountCents: 1250,
          categoryId: 1,
          accountId: 2,
          date: '2022-05-17',
          note: '午饭',
          createdAt: 1,
          updatedAt: 1,
        ),
      ],
      accounts: const [
        Account(name: '现金', type: AccountType.cash, icon: 'payments', color: 0xFF8D6E63, sortOrder: 1),
      ],
      transfers: const [
        Transfer(fromAccountId: 1, toAccountId: 2, amountCents: 5000, date: '2022-05-17'),
      ],
      budgets: const [
        Budget(amountCents: 300000),
      ],
    );

    final json = encodeBackup(data);
    final decoded = decodeBackup(json);

    expect(decoded.categories.length, 1);
    expect(decoded.categories.first.name, '餐饮');
    expect(decoded.transactions.first.accountId, 2);
    expect(decoded.accounts.length, 1);
    expect(decoded.transfers.length, 1);
    expect(decoded.budgets.first.amountCents, 300000);
  });
}
