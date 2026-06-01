import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

String? _getRejectionReason(String text) {
  if (text.isEmpty) return 'Empty SMS body';
  
  // 1. OTP check
  final otpRe = RegExp(
    r'\b(OTP|one\s*time\s*password|verification\s*code|passcode|secret\s*code|valid\s*for)\b',
    caseSensitive: false,
  );
  if (otpRe.hasMatch(text)) {
    return 'Contains OTP/verification keyword';
  }

  // 2. Promotional/marketing check
  final promoRe = RegExp(
    r'\b(offer|discount|save\b|coupon|promo|sale|deal|win\b|free\b|pre-approved|apply\s*now|recharge\s*now|explore\s*now|cashback\s*of\s*(?:Rs|INR|₹)?\s*\d+\s*on\s*minimum)\b',
    caseSensitive: false,
  );
  // Do not reject if it explicitly states "credited" or "refunded" or "cashback credited"
  if (promoRe.hasMatch(text) && !RegExp(r'\b(credited|refunded|received)\b', caseSensitive: false).hasMatch(text)) {
    return 'Promotional/marketing message';
  }

  // 3. Failed/declined check
  final failedRe = RegExp(
    r'\b(failed|declined|insufficient\s*funds|rejected|undelivered|limit\s*exceeded|cancelled)\b',
    caseSensitive: false,
  );
  if (failedRe.hasMatch(text)) {
    return 'Failed/declined/insufficient-funds transaction';
  }

  // 4. Reminder check
  final reminderRe = RegExp(
    r'\b(reminder|due\s*date|overdue|statement\s*of|bill\s*due)\b',
    caseSensitive: false,
  );
  final txnKeywordRe = RegExp(
    r'\b(debited|credited|transferred|sent|received|paid|spent|withdrawn|deposit|refunded|charged|purchase|auto-debit|payment|txn|transaction|processed|sip)\b',
    caseSensitive: false,
  );
  if (reminderRe.hasMatch(text) && !txnKeywordRe.hasMatch(text)) {
    return 'Reminder/Bill due notice';
  }

  // 5. Amount check
  final amountRe = RegExp(
    r'(?:INR|Rs\.?|₹|inr|rs)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  if (!amountRe.hasMatch(text)) {
    return 'No transaction amount detected';
  }

  // 6. Transaction action check
  if (!txnKeywordRe.hasMatch(text)) {
    return 'No transaction action keywords found';
  }

  return null; // Valid financial SMS!
}

double _extractAmount(String text) {
  final amountRe = RegExp(
    r'(?:INR|Rs\.?|₹|inr|rs)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  
  final matches = amountRe.allMatches(text).toList();
  if (matches.isEmpty) return 0.0;
  
  // If there's only one amount, make sure it's valid
  if (matches.length == 1) {
    final raw = matches.first.group(1)!.replaceAll(',', '');
    return double.tryParse(raw) ?? 0.0;
  }
  
  // If there are multiple amounts, identify which is the transaction amount
  // and which are balances/limits
  double? candidateAmount;
  double highestConfidence = -1.0;
  
  for (final m in matches) {
    final raw = m.group(1)!.replaceAll(',', '');
    final val = double.tryParse(raw) ?? 0.0;
    if (val <= 0.0) continue;
    
    // Check surrounding context (30 characters before and after)
    final start = (m.start - 30).clamp(0, text.length);
    final end = (m.end + 30).clamp(0, text.length);
    final context = text.substring(start, end).toLowerCase();
    
    // Balance / limit detection
    if (RegExp(r'\b(bal|balance|available|avl|limit|outstanding|due|minimum|min\s*due)\b').hasMatch(context)) {
      continue; // Skip balance/limit amount
    }
    
    // Check transaction keyword association
    double confidence = 1.0;
    if (RegExp(r'\b(debited|credited|spent|paid|sent|received|transferred|withdrawn|purchase|txn|payment|sip|auto-debit)\b').hasMatch(context)) {
      confidence += 2.0;
    }
    
    if (confidence > highestConfidence) {
      highestConfidence = confidence;
      candidateAmount = val;
    }
  }
  
  // Fallback: if all were skipped as balances or no confident amount found, pick the first one
  if (candidateAmount == null && matches.isNotEmpty) {
    final raw = matches.first.group(1)!.replaceAll(',', '');
    return double.tryParse(raw) ?? 0.0;
  }
  
  return candidateAmount ?? 0.0;
}

bool _isDebit(String text) {
  final lowerText = text.toLowerCase();
  
  // Check if there are credit-specific keywords
  final hasCredit = RegExp(r'\b(credited|received|deposited|refunded|cashback|added\s+to\s+wallet)\b').hasMatch(lowerText);
  final hasDebit = RegExp(r'\b(debited|spent|paid|sent|withdrawn|transferred|purchase|auto-debit|charged)\b').hasMatch(lowerText);
  
  if (hasCredit && !hasDebit) return false;
  if (hasDebit && !hasCredit) return true;
  
  // If both are present, compare their first positions in the text
  if (hasCredit && hasDebit) {
    final debitIdx = lowerText.indexOf(RegExp(r'\b(debited|spent|paid|sent|withdrawn|transferred|purchase|auto-debit|charged)\b'));
    final creditIdx = lowerText.indexOf(RegExp(r'\b(credited|received|deposited|refunded|cashback)\b'));
    if (creditIdx != -1 && debitIdx != -1) {
      return debitIdx < creditIdx;
    }
  }
  
  return true; // Default to debit
}

String _toTitleCase(String input) {
  if (input.isEmpty) return input;
  return input.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String _cleanCandidateMerchant(String rawCandidate, double txnAmount) {
  var m = rawCandidate.replaceAll('\n', ' ').trim();
  
  // 1. Strip standard A/c, Account, Acc, Card ending prefixes first before slash processing
  m = m.replaceAll(RegExp(r'\b(?:a/c|acc|account|card|ending)\b.*$', caseSensitive: false), '').trim();
  
  // 2. Replace special characters like *, /, _ with spaces
  m = m.replaceAll(RegExp(r'[*_/#]'), ' ').trim();
  m = m.replaceAll(RegExp(r'\s+'), ' '); // normalize whitespace
  
  // If candidate contains a UPI VPA (with @), take the part before @
  if (m.contains('@')) {
    m = m.split('@').first.trim();
  }
  
  // Remove common banking boilerplate endings/tails.
  // We want to stop at words that indicate transaction details.
  final stopWords = RegExp(
    r'\b(via|on|for|at|using|date|time|ref|ref\s*no|reference|txn|txnid|id|transaction|upi|imps|neft|rtgs|card|ending|a/c|account|xx\d+|\*\d+|success|successful|done|processed|completed|bal|balance|avl|limit|from|by|to|in|was|is|has|been)\b.*$',
    caseSensitive: false,
  );
  m = m.replaceAll(stopWords, '').trim();
  
  // Strip surrounding non-word characters except letters, digits, and spaces.
  m = m.replaceAll(RegExp(r'^[\W_]+|[\W_]+$'), '').trim();
  
  // Reject if it is just a number or an amount
  final amountRe = RegExp(r'^(?:rs\.?|inr|₹|usd)?\s*[0-9,]+(?:\.[0-9]{1,2})?$', caseSensitive: false);
  if (amountRe.hasMatch(m) || RegExp(r'^\d+$').hasMatch(m)) {
    return '';
  }
  
  // Strip currency prefixes if they precede a valid name (e.g. "Rs Porter" -> "Porter")
  m = m.replaceAll(RegExp(r'^(?:rs\.?|inr|₹)\s*', caseSensitive: false), '').trim();
  
  // Strip leading vps/upi/vpa bank boilerplate prefixes (e.g., "VPS Zomato" -> "Zomato", "UPI Star Biryani" -> "Star Biryani")
  m = m.replaceAll(RegExp(r'^(?:vps|upi|vpa)\b\s*', caseSensitive: false), '').trim();
  
  final bankBoilerplate = RegExp(r'^(?:a/c|acc|account|card|ending|xxxx|bank|upi\s*ref|ref\s*no|txn|ref)$', caseSensitive: false);
  if (bankBoilerplate.hasMatch(m)) {
    return '';
  }
  
  m = _toTitleCase(m);
  
  // Limit length safely, preserving full names
  if (m.length > 80) {
    m = m.substring(0, 80).trim();
  }
  
  return m.length >= 2 ? m : '';
}

String _extractMerchant(String text, double txnAmount, bool isDebit) {
  final toPatterns = <RegExp>[
    // "debited/paid/sent/transferred ... to <Merchant>"
    RegExp(r'\b(?:debited|paid|sent|transferred|payment|transfer|txn|purc|purchase)\b.*?\bto\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "spent/done/purchase/txn ... at <Merchant>"
    RegExp(r'\b(?:spent\s+at|done\s+at|purchase\s+at|txn\s+at|spent|done|purchase|txn)\b.*?\bat\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "at <Merchant>"
    RegExp(r'\bat\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "to VPA <Merchant>@..." or "to <Merchant>@..."
    RegExp(r'\bto\s+vpa\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})@', caseSensitive: false),
    RegExp(r'\bto\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})@', caseSensitive: false),
  ];

  final fromPatterns = <RegExp>[
    // "credited/received/refunded ... from/by <Merchant>"
    RegExp(r'\b(?:credited|received|refunded|deposit|refund)\b.*?\b(?:from|by)\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
  ];

  final otherPatterns = <RegExp>[
    // "in <Merchant>"
    RegExp(r'\bin\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "for payment to <Merchant>"
    RegExp(r'\bfor\s+payment\s+to\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "beneficiary/payee/recipient: <Merchant>"
    RegExp(r'\b(?:beneficiary|payee|recipient)\s*(?:name|is|:)?\s*([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "Info: <Merchant>"
    RegExp(r'\b(?:info|info:|narration|desc|remarks|remarks:)\s*([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    // "<Merchant> payment of"
    RegExp(r'\b([A-Za-z0-9 &.\''\-*/_@#]{2,100})\s+payment\s+of\b', caseSensitive: false),
  ];

  final orderedPatterns = <RegExp>[];
  if (isDebit) {
    orderedPatterns.addAll(toPatterns);
    orderedPatterns.addAll(fromPatterns);
  } else {
    orderedPatterns.addAll(fromPatterns);
    orderedPatterns.addAll(toPatterns);
  }
  orderedPatterns.addAll(otherPatterns);

  for (final pattern in orderedPatterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      final matchStr = match.group(1)?.trim();
      if (matchStr != null && matchStr.isNotEmpty) {
        final cleaned = _cleanCandidateMerchant(matchStr, txnAmount);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
  }
  
  // Fallback 1: UPI ID or reference prefixes
  final upiMatch = RegExp(r'\b(?:upi|vpa|info|ref):\s*([A-Za-z0-9 &.\''\-]{2,100})', caseSensitive: false).firstMatch(text);
  if (upiMatch != null) {
    final cleaned = _cleanCandidateMerchant(upiMatch.group(1)!, txnAmount);
    if (cleaned.isNotEmpty) return cleaned;
  }
  
  // Fallback 2: Known merchants scan
  final lowerText = text.toLowerCase();
  final knownMerchants = [
    'porter', 'swiggy', 'zomato', 'blinkit', 'zepto', 'instamart', 'bigbasket', 'dunzo',
    'ola', 'uber', 'rapido', 'redbus', 'irctc', 'makemytrip', 'goibibo', 'easemytrip',
    'amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'nykaa', 'tata cliq', 'jiomart',
    'reliance digital', 'reliance trends', 'westside', 'lifestyle', 'decathlon',
    'pvr', 'inox', 'cinepolis', 'bookmyshow', 'netflix', 'spotify', 'youtube', 'hotstar',
    'airtel', 'jio', 'vi', 'bsnl', 'bescom', 'tata power', 'adani', 'indane', 'hp gas',
    'practo', 'pharmeasy', '1mg', 'apollo', 'medplus', 'netmeds',
    'groww', 'zerodha', 'upstox', 'paytm', 'phonepe', 'gpay', 'google pay',
    'starbucks', 'mcdonald', 'kfc', 'burger king', 'pizza hut', 'domino'
  ];
  for (final merchant in knownMerchants) {
    final re = RegExp(r'\b' + RegExp.escape(merchant) + r'\b', caseSensitive: false);
    if (re.hasMatch(lowerText)) {
      return _toTitleCase(merchant);
    }
  }
  
  return isDebit ? 'UPI' : 'Transfer';
}

bool _isP2PTransfer(String body) {
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
    'porter',
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

  if (b.contains('restaurant') || b.contains('food') || b.contains('cafe')) return TransactionCategory.food;
  if (b.contains('movie') || b.contains('cinema') || b.contains('ott')) return TransactionCategory.entertainment;
  if (b.contains('electricity') || b.contains('bill')) return TransactionCategory.bills;
  if (b.contains('hospital') || b.contains('pharmacy')) return TransactionCategory.health;
  if (b.contains('flight') || b.contains('cab') || b.contains('train')) return TransactionCategory.travel;

  return TransactionCategory.other;
}

List<TransactionModel> _parseSmsBatch(List<Map<String, dynamic>> items) {
  final List<TransactionModel> out = [];
  final uuid = Uuid();

  for (final m in items) {
    final body = (m['body'] ?? '') as String;
    final dateMs = (m['date'] ?? 0) as int;
    final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
    
    final rejectionReason = _getRejectionReason(body);
    if (rejectionReason != null) {
      debugPrint('''
======================================================================
[SMS PARSER LOG] - REJECTED
Original SMS: "$body"
Reason:       $rejectionReason
======================================================================''');
      continue;
    }

    final amount = _extractAmount(body);
    if (amount <= 0) {
      debugPrint('''
======================================================================
[SMS PARSER LOG] - REJECTED
Original SMS: "$body"
Reason:       Extracted amount was 0 or invalid
======================================================================''');
      continue;
    }

    final isDebit = _isDebit(body);
    final merchant = _extractMerchant(body, amount, isDebit);
    final category = _categoryFor(merchant, body);

    final idVal = (m['id'] ?? uuid.v4()).toString();
    final id = 'sms_${idVal}_$dateMs';

    debugPrint('''
======================================================================
[SMS PARSER LOG] - PARSED SUCCESSFULLY
Original SMS: "$body"
Extracted Fields:
  - Amount:      ₹$amount
  - Merchant:    $merchant
  - Type:        ${isDebit ? 'Debit (Expense)' : 'Credit (Income)'}
  - Category:    ${category.name.toUpperCase()}
  - Date:        $date
======================================================================''');

    out.add(
      TransactionModel(
        id: id,
        amount: amount,
        merchant: merchant,
        categoryIndex: category.index,
        date: date,
        isDebit: isDebit,
        rawSmsText: body,
      ),
    );
  }

  return out;
}

// Exposed helper for unit testing
List<TransactionModel> parseSmsBatchForTesting(List<Map<String, dynamic>> items) {
  return _parseSmsBatch(items);
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
