Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
  final sanitized = Map<String, dynamic>.from(data);

  // Champs array obligatoires
  sanitized["depenses"] = (data["depenses"] is List)
      ? (data["depenses"] as List)
          .map((d) => {
                "nom": d["nom"] ?? "",
                "montant": d["montant"] is num
                    ? d["montant"]
                    : double.tryParse("${d["montant"]}") ?? 0.0,
              })
          .toList()
      : [];

  sanitized["autres_ventes"] = (data["autres_ventes"] is List)
      ? (data["autres_ventes"] as List)
          .map((v) => {
                "nom": v["nom"] ?? "",
                "montant": v["montant"] is num
                    ? v["montant"]
                    : double.tryParse("${v["montant"]}") ?? 0.0,
              })
          .toList()
      : [];

  sanitized["commandes"] = (data["commandes"] is List)
      ? (data["commandes"] as List)
          .map((c) => {
                "produit": c["produit"] ?? "",
                "quantite": c["quantite"] is num
                    ? c["quantite"]
                    : int.tryParse("${c["quantite"]}") ?? 0,
                "livraison": c["livraison"] ?? "",
              })
          .toList()
      : [];

  // Tous les champs stock ou index : forcer en int
  for (final key in data.keys) {
    if (key.startsWith("stock_") ||
        key.startsWith("super") ||
        key.startsWith("gaz") ||
        key == "depot_banque") {
      sanitized[key] = int.tryParse("${data[key]}") ?? 0;
    }
  }

  return sanitized;
}
