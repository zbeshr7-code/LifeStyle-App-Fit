/// App Store / Google Play product IDs (create matching products in each console).
abstract final class StoreProductCatalog {
  static const sub30d = 'lifestyle_fit_sub_30d';
  static const sub90d = 'lifestyle_fit_sub_90d';
  static const sub180d = 'lifestyle_fit_sub_180d';

  static const all = {sub30d, sub90d, sub180d};

  static String forDurationDays(int days) => switch (days) {
        30 => sub30d,
        90 => sub90d,
        _ => sub180d,
      };
}
