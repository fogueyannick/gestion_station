Map<String, int> calcVentes(
    Map<String, int> current, Map<String, int> previous) {
  return current.map((k, v) => MapEntry(k, v - previous[k]!));
}

int totalFromMap(Map<String, int> m) {
  return m.values.fold(0, (sum, v) => sum + v);
}
