/// Tahmini ücret aralığı (TL). Kesin fiyat trafik ve beklemeye göre değişir.
class FareEstimate {
  final int low;
  final int high;

  const FareEstimate({required this.low, required this.high});

  /// Yolculuk sonunda gösterilen tutar (demo): aralığın ortası.
  int get typical => ((low + high) / 2).round();
}
