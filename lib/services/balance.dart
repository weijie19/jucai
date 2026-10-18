int computeBalance({
  required int initial,
  required int income,
  required int expense,
  required int transferOut,
  required int transferIn,
}) {
  return initial + income - expense - transferOut + transferIn;
}

/// 借贷对账户余额的净影响 = 借入总额 - 借出总额 + 收回的借出还款 - 还掉的借入欠款。
int debtNetEffect({
  required int borrowTotal,
  required int lendTotal,
  required int lendRepaid,
  required int borrowRepaid,
}) {
  return borrowTotal - lendTotal + lendRepaid - borrowRepaid;
}
