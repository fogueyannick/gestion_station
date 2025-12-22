class DailyReport {
  final int id;
  final int stationId;
  final int userId;
  final String rapporteur;
  final DateTime date;

  final double super1;
  final double super2;
  final double super3;
  final double gaz1;
  final double gaz2;
  final double gaz3;

  final double stockSup9000;
  final double stockSup10000;
  final double stockSup14000;
  final double stockGaz10000;
  final double stockGaz6000;

  final double versement;
  final double depenses;

  // Photos (optionnelles)
  final String? super1Photo;
  final String? super2Photo;
  final String? super3Photo;
  final String? gaz1Photo;
  final String? gaz2Photo;
  final String? gaz3Photo;

  DailyReport({
    required this.id,
    required this.stationId,
    required this.userId,
    required this.rapporteur,
    required this.date,
    required this.super1,
    required this.super2,
    required this.super3,
    required this.gaz1,
    required this.gaz2,
    required this.gaz3,
    required this.stockSup9000,
    required this.stockSup10000,
    required this.stockSup14000,
    required this.stockGaz10000,
    required this.stockGaz6000,
    required this.versement,
    required this.depenses,
    this.super1Photo,
    this.super2Photo,
    this.super3Photo,
    this.gaz1Photo,
    this.gaz2Photo,
    this.gaz3Photo,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json["id"],
      stationId: json["station_id"],
      userId: json["user_id"],

      // Rapporteur depuis la relation user
      rapporteur: json["user"]?["name"] ?? "Pompiste",

      date: DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),

      super1: (json["super1_index"] ?? 0).toDouble(),
      super2: (json["super2_index"] ?? 0).toDouble(),
      super3: (json["super3_index"] ?? 0).toDouble(),
      gaz1: (json["gazoil1_index"] ?? 0).toDouble(),
      gaz2: (json["gazoil2_index"] ?? 0).toDouble(),
      gaz3: (json["gazoil3_index"] ?? 0).toDouble(),

      stockSup9000: (json["stock_sup_9000"] ?? 0).toDouble(),
      stockSup10000: (json["stock_sup_10000"] ?? 0).toDouble(),
      stockSup14000: (json["stock_sup_14000"] ?? 0).toDouble(),
      stockGaz10000: (json["stock_gaz_10000"] ?? 0).toDouble(),
      stockGaz6000: (json["stock_gaz_6000"] ?? 0).toDouble(),

      versement: (json["versement"] ?? 0).toDouble(),
      depenses: (json["depenses"] ?? 0).toDouble(),

      // Photos
      super1Photo: json["super1_photo"],
      super2Photo: json["super2_photo"],
      super3Photo: json["super3_photo"],
      gaz1Photo: json["gaz1_photo"],
      gaz2Photo: json["gaz2_photo"],
      gaz3Photo: json["gaz3_photo"],
    );
  }
}
