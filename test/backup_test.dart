import 'package:flutter_test/flutter_test.dart';
import 'package:jucai/models/models.dart';
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
          date: '2022-05-17',
          note: '午饭',
          createdAt: 1,
          updatedAt: 1,
        ),
      ],
    );

    final json = encodeBackup(data);
    final decoded = decodeBackup(json);

    expect(decoded.categories.length, 1);
    expect(decoded.categories.first.name, '餐饮');
    expect(decoded.transactions.length, 1);
    expect(decoded.transactions.first.amountCents, 1250);
    expect(decoded.transactions.first.note, '午饭');
  });
}
