import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

// Lightweight SMS -> Transaction parser used in background isolate
List<TransactionModel> _parseSmsBatch(List<Map<String, dynamic>> items) {
  final List<TransactionModel> out = [];
  final uuid = Uuid();
  final amountRe = RegExp(r"(?:INR|Rs\.?|₹)\s?([0-9,]+(?:\\.[0-9]{1,2})?)", caseSensitive: false);
  final creditRe = RegExp(r"credit|credited|deposit", caseSensitive: false);
  final debitRe = RegExp(r"debit|debited|withdrawn|paid|purchase", caseSensitive: false);
  for (final m in items) {
    final body = (m['body'] ?? '') as String;
    final dateMs = (m['date'] ?? 0) as int;
    if (body.trim().isEmpty) continue;

    final amountMatch = amountRe.firstMatch(body);
    if (amountMatch == null) continue; // not a transaction-like message

    final rawAmount = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    final isDebit = debitRe.hasMatch(body) && !creditRe.hasMatch(body);

    // naive merchant extraction: look for "to <merchant>" or "for <merchant>" or words before 'via' or 'on'
    String merchant = '';
    final toRe = RegExp(r"to\s+([A-Za-z0-9 &.-]+?)\s+(?:via|on|for|Txn|Ref|$)", caseSensitive: false);
    final forRe = RegExp(r"for\s+([A-Za-z0-9 &.-]+?)\s+(?:via|on|Txn|Ref|$)", caseSensitive: false);
    final viaRe = RegExp(r"([A-Za-z0-9 &.-]+?)\s+via\s+UPI", caseSensitive: false);

    final m1 = toRe.firstMatch(body);
    final m2 = forRe.firstMatch(body);
    final m3 = viaRe.firstMatch(body);
    if (m1 != null) {
      merchant = m1.group(1)!.trim();
    } else if (m2 != null) {
      merchant = m2.group(1)!.trim();
    } else if (m3 != null) {
      merchant = m3.group(1)!.trim();
    }

    if (merchant.isEmpty) {
      // fallback: take first capitalized word sequence after amount
      final afterAmount = body.substring(amountMatch.end).trim();
      final fallbackMatch = RegExp(r"([A-Za-z0-9 &.-]{3,40})").firstMatch(afterAmount);
      merchant = fallbackMatch?.group(1)?.trim() ?? '';
    }

    final idVal = (m['id'] ?? uuid.v4()).toString();
    final id = 'sms_${idVal}_$dateMs';

    final tx = TransactionModel(
      id: id,
      amount: amount,
      merchant: merchant.isEmpty ? 'UPI' : merchant,
      categoryIndex: 0,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      isDebit: isDebit,
      rawSmsText: body,
    );

    out.add(tx);
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
