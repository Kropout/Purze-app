import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'mock_sms_provider.dart';

String? _getRejectionReason(String text) {
  if (text.isEmpty) return 'Empty SMS body';
  
  // 0. Date filter: ignore messages older than 1 year
  // Assuming extractDate can parse a date, if it fails, fallback to current time
  final now = DateTime.now();
  final smsDate = _extractDate(text, now);
  if (smsDate.isBefore(now.subtract(const Duration(days: 365)))) {
    return 'Message older than 1 year';
  }

  // 1. Rejection filter for service-based transactions
  final serviceRe = RegExp(
    r'\b(FASTag|toll|highway|Sodexo|voucher|meal\s+card|corporate\s+card|fleet|parking)\b',
    caseSensitive: false,
  );
  // Do not reject if paid via UPI/Netbanking - detected by presence of those keywords
  final paymentMethodRe = RegExp(
    r'\b(UPI|NetBanking|IMPS|NEFT|AutoPay)\b',
    caseSensitive: false,
  );
  if (serviceRe.hasMatch(text) && !paymentMethodRe.hasMatch(text)) {
    return 'Service-based transaction (corporate/voucher)';
  }

  // 1. OTP/verification check
  final otpRe = RegExp(
    r'\b(OTP|one\.time\.password|verification\s+code|login\s+code|signup\s+code)\b',
    caseSensitive: false,
  );
  if (otpRe.hasMatch(text)) {
    return 'Contains OTP/verification keyword';
  }

  // 2. Promotional check
  final promoRe = RegExp(
    r'\b(offer|discount|cashback|win|free|click\s+here|download|install|refer|invite|expires|hurry|limited)\b',
    caseSensitive: false,
  );
  // Do not reject if it explicitly contains a transaction action verb
  final actionVerbRe = RegExp(
    r'\b(debited|credited|paid|received|transferred|sent|spent|withdrawn|refunded|charged|purchase)\b',
    caseSensitive: false,
  );
  if (promoRe.hasMatch(text) && !actionVerbRe.hasMatch(text)) {
    return 'Promotional/marketing message';
  }

  // 3. Failed/declined check
  final failedRe = RegExp(
    r'\b(failed|declined|unsuccessful|insufficient|rejected|reversed|cancelled)\b',
    caseSensitive: false,
  );
  if (failedRe.hasMatch(text)) {
    return 'Failed/declined/insufficient-funds transaction';
  }

  // 4. Pure reminders check
  final reminderRe = RegExp(
    r'\b(due|overdue|payment\s+due|bill\s+due|minimum\s+due|outstanding)\b',
    caseSensitive: false,
  );
  if (reminderRe.hasMatch(text) && !actionVerbRe.hasMatch(text)) {
    return 'Reminder/Bill due notice';
  }

  // 5. Amount check (reject if no Rs / INR / ₹ found followed by number)
  final amountRe = RegExp(
    r'(?:Rs\.?|INR|₹)\s*[\d,]+',
    caseSensitive: false,
  );
  if (!amountRe.hasMatch(text)) {
    return 'No transaction amount detected';
  }
  
  // 6. Action check
  final actionWordRe = RegExp(
    r'\b(debited|credited|debit|credit|paid|received|transferred|sent|spent|withdrawn|txn|transaction|purchase|charged|processed|sip|auto-debit|payment|transfer)\b',
    caseSensitive: false,
  );
  if (!actionWordRe.hasMatch(text)) {
    return 'No transaction action keywords found';
  }
  
  return null; // Valid financial SMS!
}

double _extractAmount(String text) {
  final amountRe = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );

  final matches = amountRe.allMatches(text).toList();
  if (matches.isEmpty) return 0.0;

  final actionWordRe = RegExp(
    r'\b(debited|credited|debit|credit|paid|received|transferred|sent|spent|withdrawn|txn|transaction|purchase|charged|processed|sip|auto-debit|payment|transfer)\b',
    caseSensitive: false,
  );

  double? candidateAmount;
  double minDistance = 999999.0;
  for (final m in matches) {
    final raw = m.group(1)!.replaceAll(',', '');
    final val = double.tryParse(raw) ?? 0.0;
    if (val <= 0.0) continue;

    // Ignore amounts preceded by Bal, Balance, Available, Limit, Outstanding, minimum, Total, due within 40 chars
    final start = (m.start - 40).clamp(0, text.length);
    final prefix = text.substring(start, m.start).toLowerCase();

    final ignoreRe = RegExp(
      r'\b(bal|balance|available|avl|limit|outstanding|minimum|min|total|due)\b',
    caseSensitive: false,
  );
    if (ignoreRe.hasMatch(prefix)) {
      continue; // Skip balance/limit amount
  }

    // Find the closest action word
    double dist = 999999.0;
    final actionMatches = actionWordRe.allMatches(text);
    for (final act in actionMatches) {
      final d = (act.start - m.start).abs().toDouble();
      if (d < dist) {
        dist = d;
      }
    }

    if (dist < minDistance) {
      minDistance = dist;
      candidateAmount = val;
    }
  }

  // Fallback to first valid match if all candidate checks failed or no action word was found
  if (candidateAmount == null && matches.isNotEmpty) {
    for (final m in matches) {
      final raw = m.group(1)!.replaceAll(',', '');
      final val = double.tryParse(raw) ?? 0.0;
      if (val > 0.0) return val;
    }
  }

  return candidateAmount ?? 0.0;
}

bool _isDebit(String text) {
  final lowerText = text.toLowerCase();

  final debitRe = RegExp(
    r'\b(debited|debit|paid|sent|transferred\s+to|spent|withdrawn|purchase|payment|charged|auto-debit)\b',
    caseSensitive: false,
    );
  final creditRe = RegExp(
    r'\b(credited|credit(?!\s+card)|received|transferred\s+from)\b',
    caseSensitive: false,
  );

  final hasDebit = debitRe.hasMatch(lowerText);
  final hasCredit = creditRe.hasMatch(lowerText);

  if (hasDebit && !hasCredit) return true;
  if (hasCredit && !hasDebit) return false;

  if (hasDebit && hasCredit) {
    final debitIdx = debitRe.firstMatch(lowerText)?.start ?? -1;
    final creditIdx = creditRe.firstMatch(lowerText)?.start ?? -1;
    if (debitIdx != -1 && creditIdx != -1) {
      return debitIdx < creditIdx;
  }
}

  // If no clear debit/credit word, check if it looks like a credit/income format
  if (lowerText.contains('from ')) return false;

  return true; // Default to debit
}

String _toTitleCase(String input) {
  if (input.isEmpty) return input;
  return input.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String _cleanCandidateMerchant(String rawCandidate) {
  var m = rawCandidate.replaceAll('\n', ' ').trim();

  // Strip boilerplate substrings
  m = m.replaceAll(RegExp(r'\bCall\s*18002662\b', caseSensitive: false), '');
  m = m.replaceAll(RegExp(r'\bSMS\s*BLOCK\b', caseSensitive: false), '');
  m = m.replaceAll(RegExp(r'\bfor\s*dispute\b', caseSensitive: false), '');
  m = m.replaceAll(RegExp(r'\bIf\s*not\s*you\b', caseSensitive: false), '');

  // Strip title prefixes: MR, MRS, MS, DR, SRI, SMT
  m = m.replaceAll(RegExp(r'^\b(?:MR|MRS|MS|DR|SRI|SMT)\b\.?\s+', caseSensitive: false), '');

  // Strip bank name suffixes: - ICICI Bank, - HDFC Bank, etc.
  m = m.replaceAll(RegExp(r'\s*[-–]\s*(?:ICICI|HDFC|SBI|AXIS|KOTAK|PNB)\s*Bank\.?$', caseSensitive: false), '');

  // Replace *, _, #, / with space
  m = m.replaceAll(RegExp(r'[*_#/]'), ' ');

  // Normalize whitespace
  m = m.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Remove common banking boilerplate endings/tails.
  final stopWords = RegExp(
    r'\b(via|on|for|at|using|date|time|ref|ref\s*no|reference|txn|txnid|id|transaction|upi|imps|neft|rtgs|card|ending|a/c|account|xx\d+|\*\d+|success|successful|done|processed|completed|bal|balance|avl|limit|from|by|to|in|was|is|has|been)\b.*$',
    caseSensitive: false,
  );
  m = m.replaceAll(stopWords, '').trim();

  // Strip surrounding non-word characters (except spaces/letters/digits)
  m = m.replaceAll(RegExp(r'^[\W_]+|[\W_]+$'), '').trim();

  // Reject if result matches \d{8,} (reference number leaked) -> return "Unknown"
  if (RegExp(r'\d{8,}').hasMatch(m)) {
    return 'Unknown';
  }

  // Title case the result
  m = _toTitleCase(m);

  // Max length 60 chars
  if (m.length > 60) {
    m = m.substring(0, 60).trim();
  }

  // Reject if result is empty or less than 2 chars -> return "Unknown"
  if (m.length < 2) {
    return 'Unknown';
  }

  return m;
}

String? _tryPattern(String text, RegExp pattern, {int groupIndex = 1}) {
  final match = pattern.firstMatch(text);
  if (match != null && match.groupCount >= groupIndex) {
    final raw = match.group(groupIndex);
    if (raw != null) {
      final cleaned = _cleanCandidateMerchant(raw);
      if (cleaned != 'Unknown') {
        return cleaned;
      }
    }
  }
  return null;
}

String? _properNounScan(String text) {
  final bankNames = {
    'icici', 'hdfc', 'sbi', 'axis', 'kotak', 'pnb', 'bob', 'canara', 'union', 'yes', 'idfc', 'federal', 'rbl', 'indusind'
  };
  final boilerplate = {
    'call', 'sms', 'block', 'upi', 'bal', 'acct', 'bank', 'dear', 'customer', 'info',
    'ref', 'reference', 'txn', 'txnid', 'id', 'no', 'credit', 'card', 'debit', 'avl', 'limit', 'rs', 'inr'
  };
  final daysOfWeek = {
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
  };
  final months = {
    'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december',
    'jan', 'feb', 'mar', 'apr', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
  };

  final wordRe = RegExp(r'\b[A-Za-z0-9]+\b');
  final matches = wordRe.allMatches(text).toList();

  List<List<String>> sequences = [];
  List<String> currentSeq = [];
  int lastEnd = -1;

  for (final m in matches) {
    final word = m.group(0)!;

    // Check capitalization: starts with a letter and it's uppercase
    final isCapitalized = word.isNotEmpty &&
                          word[0] == word[0].toUpperCase() &&
                          RegExp(r'^[A-Z]$').hasMatch(word[0]);

    final wordLower = word.toLowerCase();

    final isExcluded = bankNames.contains(wordLower) ||
                       boilerplate.contains(wordLower) ||
                       daysOfWeek.contains(wordLower) ||
                       months.contains(wordLower);

    if (isCapitalized && !isExcluded) {
      if (currentSeq.isEmpty) {
        currentSeq.add(word);
      } else {
        final gap = text.substring(lastEnd, m.start);
        if (RegExp(r'^[,\s.]*$').hasMatch(gap)) {
          currentSeq.add(word);
        } else {
          sequences.add(List.from(currentSeq));
          currentSeq.clear();
          currentSeq.add(word);
        }
      }
      lastEnd = m.end;
    } else {
      if (currentSeq.isNotEmpty) {
        sequences.add(List.from(currentSeq));
        currentSeq.clear();
      }
    }
  }
  if (currentSeq.isNotEmpty) {
    sequences.add(currentSeq);
  }

  final validSeqs = sequences.where((s) => s.length >= 2).toList();
  if (validSeqs.isEmpty) return null;

  validSeqs.sort((a, b) {
    final cmp = b.length.compareTo(a.length);
    if (cmp != 0) return cmp;
    return b.join(' ').length.compareTo(a.join(' ').length);
  });

  return validSeqs.first.join(' ');
}

enum DetectedBank { icici, sbi, hdfc, pnb, none }

DetectedBank _detectBank(String body, String sender) {
  final bodyLower = body.toLowerCase();
  final senderUpper = sender.toUpperCase();

  if (bodyLower.contains('icici bank') || senderUpper == 'AX-ICICIT-S' || senderUpper == 'ICICIB') {
    return DetectedBank.icici;
  }
  if (bodyLower.contains('sbi') || bodyLower.contains('state bank') || senderUpper.contains('SBI')) {
    return DetectedBank.sbi;
  }
  if (bodyLower.contains('hdfc') || senderUpper.contains('HDFC')) {
    return DetectedBank.hdfc;
  }
  if (bodyLower.contains('pnb') || bodyLower.contains('punjab national') || senderUpper.contains('PNB')) {
    return DetectedBank.pnb;
  }
  return DetectedBank.none;
}

String _extractBankSpecificMerchant(DetectedBank bank, String text) {
  switch (bank) {
    case DetectedBank.icici:
      // Format 1 — P2P Debit:
      if (text.toLowerCase().contains('credited') && text.contains(';')) {
        final match = RegExp(r';\s*(.+?)\s+credited', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      // Format 2 — Merchant Debit:
      if (text.contains('*') && text.toLowerCase().contains('. bal')) {
        final match = RegExp(r'\*\s*(.+?)\s*\.\s*Bal', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      // Format 3 — Credit:
      if (text.toLowerCase().contains('credited') && text.toLowerCase().contains('from')) {
        final match = RegExp(r'\bfrom\s+([^.]+)\.', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      break;

    case DetectedBank.sbi:
      // SBI: Your A/c [ACCT] debited by Rs [AMOUNT]. Info: [MERCHANT]@[VPA]
      if (text.toLowerCase().contains('info:')) {
        final match = RegExp(r'\binfo:\s*([^@]+)@', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      break;

    case DetectedBank.hdfc:
      // HDFC: Rs [AMOUNT] debited from HDFC Bank A/c XX[ACCT] to VPA [MERCHANT]@
      if (text.toLowerCase().contains('to vpa')) {
        final match = RegExp(r'\bto\s+vpa\s+([^@]+)@', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      break;

    case DetectedBank.pnb:
      // PNB: Rs [AMOUNT] has been debited.*Payee: [MERCHANT]
      if (text.toLowerCase().contains('payee:')) {
        final match = RegExp(r'\bpayee:\s*(.+)$', caseSensitive: false).firstMatch(text);
        if (match != null) {
          final cleaned = _cleanCandidateMerchant(match.group(1)!);
          if (cleaned != 'Unknown') return cleaned;
        }
      }
      break;

    case DetectedBank.none:
      break;
  }
  return 'Unknown';
}

String _extractMerchant(String text, double txnAmount, bool isDebit, {String sender = ''}) {
  String? processCandidate(String raw) {
    if (RegExp(r'\d{8,}').hasMatch(raw)) {
      return 'Unknown';
    }
    final cleaned = _cleanCandidateMerchant(raw);
    if (cleaned == 'Unknown') return null;
    return cleaned;
  }

  // Strategy 1 — Explicit payee markers:
  final strat1 = RegExp(
    r'\b(to|paid\s+to|transferred\s+to|payee[:\s]+)\s*([A-Za-z][A-Za-z\s\.]{2,50}?)(?=\s+(?:UPI\b|on\s+\d|Ref\b|A/c\b|Acct\b|using\b|via\b|for\b|from\b|at\b|to\b)|\s*\.|\s*$)',
    caseSensitive: false,
  );
  final m1 = strat1.firstMatch(text)?.group(2);
  if (m1 != null) {
    final res = processCandidate(m1);
    if (res != null) return res;
  }

  // Strategy 2 — Explicit sender markers:
  final strat2 = RegExp(
    r'\b(from|received\s+from|credited\s+by|by)\s+([A-Za-z][A-Za-z\s\.]{2,50}?)(?=\s+(?:UPI\b|on\s+\d|Ref\b|A/c\b|Acct\b|using\b|via\b|for\b|from\b|at\b|to\b)|\s*\.|\s*$)',
    caseSensitive: false,
  );
  final m2 = strat2.firstMatch(text)?.group(2);
  if (m2 != null) {
    final res = processCandidate(m2);
    if (res != null) return res;
  }

  // Strategy 3 — Semicolon pattern:
  final strat3 = RegExp(
    r';\s*([A-Za-z][A-Za-z\s\.]{2,50}?)\s+credited',
    caseSensitive: false,
  );
  final m3 = strat3.firstMatch(text)?.group(1);
  if (m3 != null) {
    final res = processCandidate(m3);
    if (res != null) return res;
  }

  // Strategy 4 — Star/slash merchant code pattern:
  final strat4 = RegExp(
    r'\b[A-Za-z]{2,5}\*([A-Za-z][A-Za-z\s]{2,40})',
  );
  final m4 = strat4.firstMatch(text)?.group(1);
  if (m4 != null) {
    final res = processCandidate(m4);
    if (res != null) return res;
  }

  // Strategy 5 — "from NAME." pattern:
  final strat5 = RegExp(
    r'\bfrom\s+([A-Z][a-zA-Z\s\.]{2,50})\.\s*UPI',
  );
  final m5 = strat5.firstMatch(text)?.group(1);
  if (m5 != null) {
    final res = processCandidate(m5);
    if (res != null) return res;
  }

  // Strategy 6 — Proper noun scan:
  final m6 = _properNounScan(text);
  if (m6 != null) {
    final res = processCandidate(m6);
    if (res != null) return res;
  }

  // Strategy 7 — Original patterns fallback for backwards compatibility
  final toPatterns = <RegExp>[
    RegExp(r'\b(?:debited|paid|sent|transferred|payment|transfer|txn|purc|purchase)\b.*?\bto\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\b(?:spent\s+at|done\s+at|purchase\s+at|txn\s+at|spent|done|purchase|txn)\b.*?\bat\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\bat\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\bto\s+vpa\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})@', caseSensitive: false),
    RegExp(r'\bto\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})@', caseSensitive: false),
  ];

  final fromPatterns = <RegExp>[
    RegExp(r'\b(?:credited|received|refunded|deposit|refund)\b.*?\b(?:from|by)\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
  ];

  final otherPatterns = <RegExp>[
    RegExp(r'\bin\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\bfor\s+payment\s+to\s+([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\b(?:beneficiary|payee|recipient)\s*(?:name|is|:)?\s*([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
    RegExp(r'\b(?:info|info:|narration|desc|remarks|remarks:)\s*([A-Za-z0-9 &.\''\-*/_@#]{2,100})', caseSensitive: false),
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
        final res = processCandidate(matchStr);
        if (res != null) return res;
      }
    }
  }

  // Fallback 8: Known merchants scan
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
    'starbucks', 'mcdonald', 'kfc', 'burger king', 'pizza hut', 'domino', 'max', 'mubi' ,
  ];
  for (final merchant in knownMerchants) {
    final re = RegExp(r'\b' + RegExp.escape(merchant) + r'\b', caseSensitive: false);
    if (re.hasMatch(lowerText)) {
      return _toTitleCase(merchant);
    }
  }

  // Fallback 9: Bank-Specific Fallback (if and only if generic returns "Unknown")
  final bank = _detectBank(text, sender);
  if (bank != DetectedBank.none) {
    final bankMerchant = _extractBankSpecificMerchant(bank, text);
    if (bankMerchant != 'Unknown') {
      return bankMerchant;
    }
  }

  return isDebit ? 'UPI' : 'Transfer';
}

DateTime _extractDate(String text, DateTime fallback) {
  // Pattern 1: DD-MMM-YY or DD-MMM-YYYY (e.g. 28-May-26 or 28-May-2026)
  final pattern1 = RegExp(r'\b(\d{1,2})-([A-Za-z]{3})-(\d{2,4})\b');
  final match1 = pattern1.firstMatch(text);
  if (match1 != null) {
    final day = int.tryParse(match1.group(1)!) ?? 1;
    final monthStr = match1.group(2)!.toLowerCase();
    final yearStr = match1.group(3)!;

    int month = 1;
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final idx = months.indexOf(monthStr.substring(0, 3));
    if (idx != -1) {
      month = idx + 1;
    }

    int year = int.tryParse(yearStr) ?? fallback.year;
    if (yearStr.length == 2) {
      year += 2000;
    }
    return DateTime(year, month, day);
  }

  // Pattern 2: DD/MM/YYYY or DD/MM/YY (e.g. 01/06/2026)
  final pattern2 = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{2,4})\b');
  final match2 = pattern2.firstMatch(text);
  if (match2 != null) {
    final day = int.tryParse(match2.group(1)!) ?? 1;
    final month = int.tryParse(match2.group(2)!) ?? 1;
    final yearStr = match2.group(3)!;
    int year = int.tryParse(yearStr) ?? fallback.year;
    if (yearStr.length == 2) {
      year += 2000;
    }
    return DateTime(year, month, day);
  }

  // Pattern 3: DD MMM YYYY (e.g. 01 Jun 2026)
  final pattern3 = RegExp(r'\b(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\b');
  final match3 = pattern3.firstMatch(text);
  if (match3 != null) {
    final day = int.tryParse(match3.group(1)!) ?? 1;
    final monthStr = match3.group(2)!.toLowerCase();
    final yearStr = match3.group(3)!;

    int month = 1;
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final idx = months.indexOf(monthStr.substring(0, 3));
    if (idx != -1) {
      month = idx + 1;
    }

    final year = int.tryParse(yearStr) ?? fallback.year;
    return DateTime(year, month, day);
  }
  return fallback;
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

  // 1. Delivery Services
  if (hasAny(['blinkit', 'zepto', 'instamart', 'bigbasket', 'dunzo'])) {
    return TransactionCategory.delivery;
  }

  // 2. Food
  if (hasAny(['swiggy', 'zomato', 'domino', 'mcdonald', 'kfc', 'burger king', 'pizza hut', 'starbucks', 'cafe coffee day'])) {
    return TransactionCategory.food;
  }

  // 3. Taxis
  if (hasAny(['ola', 'uber', 'rapido', 'porter'])) {
    return TransactionCategory.taxi;
  }

  // 4. Shopping
  if (hasAny(['zara', 'h&m', 'hm', 'myntra', 'amazon', 'flipkart', 'meesho', 'ajio', 'reliance trends', 'westside', 'lifestyle', 'nykaa', 'decathlon'])) {
    return TransactionCategory.shopping;
  }

  // 5. Finance
  if (hasAny(['groww', 'zerodha', 'upstox', 'kuvera', 'coin'])) {
    return TransactionCategory.finance;
  }

  // 6. Travel
  if (hasAny(['redbus', 'irctc', 'makemytrip', 'goibibo', 'indigo', 'air india', 'yatra'])) {
    return TransactionCategory.travel;
  }

  // 7. Bills
  if (hasAny(['airtel', 'jio', 'vi', 'bsnl', 'bescom', 'tata power', 'adani', 'lpg', 'indane', 'hp gas', 'electricity', 'gas', 'broadband', 'dth'])) {
    return TransactionCategory.bills;
  }

  // 8. Health
  if (hasAny(['practo', 'pharmeasy', '1mg', 'apollo', 'medplus', 'netmeds'])) {
    return TransactionCategory.health;
  }

  // 9. Entertainment
  if (hasAny(['pvr', 'inox', 'cinepolis', 'bookmyshow', 'netflix', 'spotify', 'youtube', 'hotstar', 'jiosaavn'])) {
    return TransactionCategory.entertainment;
  }

  // 10. Default Others
    return TransactionCategory.other;
  }

List<TransactionModel> _parseSmsBatch(List<Map<String, dynamic>> items) {
  final List<TransactionModel> out = [];
  final uuid = Uuid();

  for (final m in items) {
    final body = (m['body'] ?? '') as String;
    final dateMs = (m['date'] ?? 0) as int;
    final sender = (m['address'] ?? m['sender'] ?? '') as String;

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
    final merchant = _extractMerchant(body, amount, isDebit, sender: sender);
    final date = _extractDate(body, DateTime.fromMillisecondsSinceEpoch(dateMs));
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

  /// Import entire inbox (Android only, web uses mock data). Returns number imported.
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
      final mockTxs = await MockSmsProvider.getMockTransactions();
      final existing = repo.getAllTransactions();
      int added = 0; 
      for (final tx in mockTxs) {
        final dup = existing.any((e) => e.rawSmsText == tx.rawSmsText && e.date.millisecondsSinceEpoch == tx.date.millisecondsSinceEpoch);
        if (dup) continue;
        await repo.addTransaction(tx);
        added++;
      }
      return added;
    }
  }
}

