import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../../features/investments/data/models/asset_model.dart';

class ApiService {
  // In-memory cache: cacheKey → (prices, fetchedAt)
  final Map<String, ({Map<String, double> prices, DateTime fetchedAt})>
      _metalsCache = {};
  final Map<String, ({double price, DateTime fetchedAt})> _cryptoCache = {};

  static const _cacheDuration = Duration(hours: 1);

  // ── Metals (api.metals.dev) ───────────────────────────────────────────────

  Future<Map<String, double>> getMetalsPrices() async {
    const key = 'metals';
    final cached = _metalsCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
      return cached.prices;
    }

    try {
      final uri = Uri.parse(
        'https://api.metals.dev/v1/latest'
        '?api_key=${AppConfig.metalsDevApiKey}'
        '&currency=USD&unit=toz',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // api.metals.dev returns USD per troy ounce directly under 'metals'
      final metals = data['metals'] as Map<String, dynamic>;
      final goldPerOunce = (metals['XAU'] as num).toDouble();
      final silverPerOunce = (metals['XAG'] as num).toDouble();

      const gramsPerOunce = 31.1035;
      final prices = {
        'gold_per_ounce': goldPerOunce,
        'gold_per_gram': goldPerOunce / gramsPerOunce,
        'silver_per_ounce': silverPerOunce,
        'silver_per_gram': silverPerOunce / gramsPerOunce,
      };

      _metalsCache[key] = (prices: prices, fetchedAt: DateTime.now());
      return prices;
    } catch (_) {
      // Return cached even if stale, or zeros if nothing cached yet
      return _metalsCache[key]?.prices ?? {};
    }
  }

  // ── Crypto (Binance) ──────────────────────────────────────────────────────

  Future<double> getCryptoPrice(String symbol) async {
    if (symbol == 'USDT') return 1.0;

    final cached = _cryptoCache[symbol];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
      return cached.price;
    }

    try {
      final uri = Uri.parse(
        '${AppConfig.binanceBaseUrl}/ticker/price?symbol=$symbol',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final price = double.parse(data['price'] as String);

      _cryptoCache[symbol] = (price: price, fetchedAt: DateTime.now());
      return price;
    } catch (_) {
      return _cryptoCache[symbol]?.price ?? 0;
    }
  }

  // ── Unified ───────────────────────────────────────────────────────────────

  /// Returns live price per unit for the given asset.
  /// Falls back to asset.currentValuePerUnit (persisted in Hive) on failure.
  Future<double> getAssetPrice(AssetModel asset) async {
    try {
      switch (asset.type) {
        case 'gold':
          final prices = await getMetalsPrices();
          return asset.unit == 'غرام'
              ? (prices['gold_per_gram'] ?? asset.currentValuePerUnit)
              : (prices['gold_per_ounce'] ?? asset.currentValuePerUnit);

        case 'silver':
          final prices = await getMetalsPrices();
          return asset.unit == 'غرام'
              ? (prices['silver_per_gram'] ?? asset.currentValuePerUnit)
              : (prices['silver_per_ounce'] ?? asset.currentValuePerUnit);

        case 'crypto':
          final symbol =
              asset.symbol.isNotEmpty ? asset.symbol : 'BTCUSDT';
          return await getCryptoPrice(symbol);

        default:
          return asset.currentValuePerUnit;
      }
    } catch (_) {
      return asset.currentValuePerUnit;
    }
  }

  /// Fetches latest prices for all assets and updates their currentValuePerUnit.
  /// Writes back to Hive so values persist across restarts.
  Future<void> refreshAssetPrices(List<AssetModel> assets) async {
    for (final asset in assets) {
      if (asset.type == 'other') continue;
      final price = await getAssetPrice(asset);
      if (price <= 0) continue;
      asset.currentValuePerUnit = price;
      asset.lastPriceUpdateMs = DateTime.now().millisecondsSinceEpoch;
      if (asset.isInBox) await asset.save();
    }
  }
}
