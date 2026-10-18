int computeBalance({
  required int initial,
  required int income,
  required int expense,
  required int transferOut,
  required int transferIn,
}) {
  return initial + income - expense - transferOut + transferIn;
}
