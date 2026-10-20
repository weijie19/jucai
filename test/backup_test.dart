import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/account.dart';
import 'package:jucai/models/budget.dart';
import 'package:jucai/models/debt.dart';
import 'package:jucai/models/debt_repayment.dart';
import 'package:jucai/models/models.dart';
import 'package:jucai/models/tag.dart';
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
          time: '12:30',
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
      debts: [
        Debt(
          id: 1,
          direction: DebtDirection.lend,
          counterparty: '张三',
          totalCents: 10000,
          remainingCents: 4000,
          date: '2022-05-01',
          createdAt: 1,
          updatedAt: 2,
        ),
      ],
      debtRepayments: [
        DebtRepayment(debtId: 1, amountCents: 6000, date: '2022-05-10', createdAt: 3),
      ],
      tags: const [
        Tag(id: 1, name: '旅行', color: 0xFF42A5F5, createdAt: 1),
      ],
      transactionTags: const [
        {'transaction_id': 1, 'tag_id': 1},
      ],
    );

    final json = encodeBackup(data);
    final decoded = decodeBackup(json);

    expect(decoded.categories.length, 1);
    expect(decoded.categories.first.name, '餐饮');
    expect(decoded.transactions.first.accountId, 2);
    expect(decoded.transactions.first.time, '12:30');
    expect(decoded.accounts.length, 1);
    expect(decoded.transfers.length, 1);
    expect(decoded.budgets.first.amountCents, 300000);
    expect(decoded.debts.first.counterparty, '张三');
    expect(decoded.debtRepayments.first.debtId, 1);
    expect(decoded.tags.first.name, '旅行');
    expect(decoded.transactionTags.first['tag_id'], 1);
  });
}
