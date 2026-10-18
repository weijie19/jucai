/// 返回 0.0 ~ 1.0 的预算使用比例；预算为 0 或负数时返回 0。
double budgetRatio(int budgetCents, int spentCents) {
  if (budgetCents <= 0) return 0;
  return (spentCents / budgetCents).clamp(0.0, 1.0);
}
