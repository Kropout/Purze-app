import 'package:flutter/foundation.dart';
import '../mock/mock_sms_data.dart';
import '../models/transaction_model.dart';
import 'sms_importer.dart';

 /// Provides mock SMS transactions for web platform.
class MockSmsProvider {
  /// Parse mock SMS data and return valid transactions.
  static Future<List<TransactionModel>> getMockTransactions() async {
    final result = <TransactionModel>[];

    final smsItems = mockSmsList.map((smsBody) {
      return <String, dynamic>{
        'body': smsBody,
        'date': DateTime.now().millisecondsSinceEpoch,
        'address': 'MockSMS',
      };
    }).toList();

   final parsed = parseSmsBatchForTesting(smsItems);

    for (final tx in parsed) {
      if (tx.merchant.isNotEmpty && tx.amount > 0) {
        result.add(tx);
      }
    }

    return result;
  }
}