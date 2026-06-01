import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

final _amountRe = RegExp(r"(?:INR|Rs\.?|₹)\s?([0-9,]+(?:\\.[0-9]{1,2})?)", caseSensitive: false);
final _txnKeywordRe = RegExp(r"\b(debited|credited|transferred|sent|received|paid)\b", caseSensitive: false);
final _bankRefRe = RegExp(r"\b(UPI|IMPS|NEFT|A/c|Acc|Bank Account)\b", caseSensitive: false);
final _otpRe = RegExp(r"\b(OTP|one\s*time\s*password|verification\s*code|passcode)\b", caseSensitive: false);
final _promoRe = RegExp(
  r"\b(offer|cashback|discount|save\b|coupon|promo|sale|deal|limited\s*time|explore\s*now|recharge\s*now|apply\s*now|win\b|free\b)\b",
  caseSensitive: false,
);
final _reminderRe = RegExp(
  r"\b(reminder|due\b|overdue|minimum\s*due|statement|bill\b|alert\b)\b",
  caseSensitive: false,
);

bool _isValidTransactionSms(String body) {
  final text = body.replaceAll('\n', ' ').trim();
  if (text.isEmpty) return false;
  if (_otpRe.hasMatch(text)) return false;
  if (_promoRe.hasMatch(text)) return false;
  if (_reminderRe.hasMatch(text) && !_txnKeywordRe.hasMatch(text)) return false;

  // Must contain ALL three signals.
  if (_amountRe.firstMatch(text) == null) return false;
  if (!_txnKeywordRe.hasMatch(text)) return false;
  if (!_bankRefRe.hasMatch(text)) return false;

  return true;
}

bool _isDebitFromBody(String body) {
  final debitRe = RegExp(r"\b(debited|sent|paid|transferred|withdrawn|spent)\b", caseSensitive: false);
  final creditRe = RegExp(r"\b(credited|received|deposit|refunded)\b", caseSensitive: false);
  if (debitRe.hasMatch(body) && !creditRe.hasMatch(body)) return true;
  if (creditRe.hasMatch(body) && !debitRe.hasMatch(body)) return false;
  // Default: treat ambiguous as debit (most UPI spends are debits).
  return true;
}

String _toTitleCase(String input) {
  if (input.isEmpty) return input;
  return input.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String _truncateAt25(String input) {
  if (input.length <= 25) return input;
  return input.substring(0, 25).trim();
}

String _cleanMerchant(String merchant) {
  var m = merchant.replaceAll('\n', ' ').trim();
  m = m.replaceAll(RegExp(r"\s+"), ' ');

  // Remove common boilerplate tails.
  m = m.replaceAll(RegExp(r"\b(via|on|for|txn|txnid|ref|reference|upi|imps|neft)\b.*$", caseSensitive: false), '').trim();

  // If it looks like a UPI handle, keep the prefix (swiggy@...) => swiggy
  if (m.contains('@')) {
    m = m.split('@').first.trim();
  }

  // Strip surrounding punctuation.
  m = m.replaceAll(RegExp(r"^[\W_]+|[\W_]+$"), '').trim();

  // Title case and truncate
  m = _toTitleCase(m);
  m = _truncateAt25(m);

  return m;
}

String _extractMerchant(String body) {
  final text = body.replaceAll('\n', ' ');

  final patterns = <RegExp>[
    // Credits: "... credited ... from <name>"
    RegExp(r"(?:credited|received).*?\bfrom\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false),
    // Debits: "... debited/paid/sent ... to <name>"
    RegExp(r"(?:debited|paid|sent|transferred).*?\bto\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false),
    // "paid to <name>"
    RegExp(r"\bpaid\s+to\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false),
    // "at <merchant>"
    RegExp(r"\bat\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false),
    // "for <merchant>"
    RegExp(r"\bfor\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false),
  ];

  for (final re in patterns) {
    final match = re.firstMatch(text);
    if (match != null) {
      final candidate = _cleanMerchant(match.group(1) ?? '');
      if (candidate.length >= 2) return candidate;
    }
  }

  // Fallback: try to pick a short token sequence near "UPI" if present.
  final upiIdx = text.toLowerCase().indexOf('upi');
  if (upiIdx != -1) {
    final snippet = text.substring(upiIdx, (upiIdx + 80).clamp(upiIdx, text.length));
    final m = RegExp(r"\bto\s+([A-Za-z][A-Za-z0-9 &.'\-]{2,60})", caseSensitive: false).firstMatch(snippet);
    if (m != null) {
      final candidate = _cleanMerchant(m.group(1) ?? '');
      if (candidate.length >= 2) return candidate;
    }
  }

  return '';
}

bool _isP2PTransfer(String body) {
  // Detect P2P by looking for person name patterns: "paid to <name>", "transferred to <name>", "sent to <name>"
  // typically person names are shorter and don't have merchant keywords
  final p2pPatterns = <RegExp>[
    RegExp(r"\b(?:paid|transferred|sent)\s+to\s+(?!the\b)([A-Za-z][A-Za-z0-9 &.'\-]{2,40})\b", caseSensitive: false),
  ];
  
  for (final re in p2pPatterns) {
    if (re.hasMatch(body)) {
      return true;
    }
  }
  
  return false;
}

TransactionCategory _categoryFor(String merchant, String body) {
  final m = merchant.toLowerCase();
  final b = body.toLowerCase();

  bool hasAny(List<String> keys) => keys.any((k) => m.contains(k) || b.contains(k));

  // Check for P2P transfer first
  if (_isP2PTransfer(body)) {
    return TransactionCategory.transfer;
  }

  if (hasAny([
    'swiggy',
    'zomato',
    'domino',
    'mcdonald',
    'kfc',
    'burger king',
    'pizza hut',
    'starbucks',
    'cafe coffee day',
    'blinkit',
    'zepto',
    'instamart',
  ])) {
    return TransactionCategory.food;
  }

  if (hasAny([
    'zara',
    'h&m',
    'hm',
    'myntra',
    'amazon',
    'flipkart',
    'meesho',
    'ajio',
    'reliance trends',
    'westside',
    'lifestyle',
    'nykaa',
    'decathlon',
  ])) {
    return TransactionCategory.shopping;
  }

  if (hasAny([
    'pvr',
    'inox',
    'cinepolis',
    'bookmyshow',
    'netflix',
    'spotify',
    'youtube',
    'hotstar',
    'jiosaavn',
  ])) {
    return TransactionCategory.entertainment;
  }

  if (hasAny([
    'ola',
    'uber',
    'rapido',
    'redbus',
    'irctc',
    'makemytrip',
    'goibibo',
    'indigo',
    'air india',
    'yatra',
  ])) {
    return TransactionCategory.travel;
  }

  if (hasAny([
    'airtel',
    'jio',
    'bsnl',
    'vi',
    'bescom',
    'tata power',
    'adani',
    'lpg',
    'indane',
    'hp gas',
    'electricity',
    'gas',
    'broadband',
    'dth',
  ])) {
    return TransactionCategory.bills;
  }

  if (hasAny([
    'practo',
    'pharmeasy',
    '1mg',
    'apollo',
    'medplus',
    'netmeds',
  ])) {
    return TransactionCategory.health;
  }

  // Finance/investment/education -> keep as Other unless your app has dedicated categories.
  if (hasAny([
    'groww',
    'zerodha',
    'upstox',
    'kuvera',
    'coin',
    'phonepe',
    'gpay',
    'google pay',
    'paytm',
    'unacademy',
    'byju',
    'coursera',
    'udemy',
    'vedantu',
  ])) {
    return TransactionCategory.other;
  }

  // Keyword fallback categorization.
  if (b.contains('restaurant') || b.contains('food') || b.contains('cafe')) return TransactionCategory.food;
  if (b.contains('movie') || b.contains('cinema') || b.contains('ott')) return TransactionCategory.entertainment;
  if (b.contains('electricity') || b.contains('bill')) return TransactionCategory.bills;
  if (b.contains('hospital') || b.contains('pharmacy')) return TransactionCategory.health;
  if (b.contains('flight') || b.contains('cab') || b.contains('train')) return TransactionCategory.travel;

  return TransactionCategory.other;
}

// Lightweight SMS -> Transaction parser used in background isolate
List<TransactionModel> _parseSmsBatch(List<Map<String, dynamic>> items) {
  final List<TransactionModel> out = [];
  final uuid = Uuid();

  for (final m in items) {
    final body = (m['body'] ?? '') as String;
    final dateMs = (m['date'] ?? 0) as int;
    if (!_isValidTransactionSms(body)) continue;

    final amountMatch = _amountRe.firstMatch(body);
    if (amountMatch == null) continue;

    final rawAmount = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmount) ?? 0.0;
    if (amount <= 0) continue;

    final isDebit = _isDebitFromBody(body);

    final merchantRaw = _extractMerchant(body);
    final merchant = merchantRaw.isEmpty ? 'UPI' : merchantRaw;

    final category = _categoryFor(merchant, body);

    final idVal = (m['id'] ?? uuid.v4()).toString();
    final id = 'sms_${idVal}_$dateMs';

    out.add(
      TransactionModel(
        id: id,
        amount: amount,
        merchant: merchant,
        categoryIndex: category.index,
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        isDebit: isDebit,
        rawSmsText: body,
      ),
    );
  }

  return out;
}

class SmsImporter {
  static const MethodChannel _chan = MethodChannel('purze/sms');

  SmsImporter();

  /// Import entire inbox (Android only). Returns number imported.
  Future<int> importEntireInbox(TransactionRepository repo, {int? sinceMillis}) async {
    try {
      final args = <String, dynamic>{};
      if (sinceMillis != null) args['since'] = sinceMillis;
      final List<dynamic>? raw = await _chan.invokeMethod('getSmsInbox', args);
      if (raw == null || raw.isEmpty) return 0;

      // Convert to List<Map<String,dynamic>> for compute
      final filtered = <Map<String, dynamic>>[];
      for (final r in raw) {
        if (r is Map) {
          filtered.add(Map<String, dynamic>.from(r));
        }
      }

      if (filtered.isEmpty) return 0;

      final parsed = await compute(_parseSmsBatch, filtered);

      final existing = repo.getAllTransactions();
      int added = 0;
      for (final tx in parsed) {
        final dup = existing.any((e) => e.rawSmsText == tx.rawSmsText && e.date.millisecondsSinceEpoch == tx.date.millisecondsSinceEpoch);
        if (dup) continue;
        await repo.addTransaction(tx);
        added++;
      }

      return added;
    } on PlatformException catch (_) {
      return 0;
    }
  }
}
