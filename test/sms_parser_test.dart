import 'package:flutter_test/flutter_test.dart';
import 'package:purze/data/services/sms_importer.dart';
import 'package:purze/data/models/transaction_model.dart';

// We will test the SMS parsing logic in sms_importer.dart
// Since sms_importer.dart has private helper functions, we will expose them
// or implement a public testable method, or test it via the batch/single parser.
// Let's check how _parseSmsBatch is designed.
// It is a top-level private function: List<TransactionModel> _parseSmsBatch(List<Map<String, dynamic>> items)
// We can expose a public testing helper in sms_importer.dart:
//
// List<Map<String, dynamic>> parseSmsForTesting(List<Map<String, dynamic>> smsList) { ... }
//
// Let's create the test suite now.

class SmsTestCase {
  final String body;
  final double? expectedAmount;
  final String? expectedMerchant;
  final bool? expectedIsDebit;
  final bool shouldParse;

  const SmsTestCase({
    required this.body,
    this.expectedAmount,
    this.expectedMerchant,
    this.expectedIsDebit,
    required this.shouldParse,
  });
}

void main() {
  final testCases = <SmsTestCase>[
    // 1. Porter Thursday payment (User's specific bug)
    const SmsTestCase(
      body: 'Porter payment of ₹410 on Thursday',
      expectedAmount: 410.0,
      expectedMerchant: 'Porter',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 2. HDFC Debit / UPI
    const SmsTestCase(
      body: 'Dear Customer, ₹410.00 has been debited from your A/c **3456 to PORTER on 01-06-26. Info: UPI-PORTER-61501234. UPI Ref: 615012345678.',
      expectedAmount: 410.0,
      expectedMerchant: 'Porter',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 3. SBI UPI Debit
    const SmsTestCase(
      body: 'Dear SBI User, Rs 120.00 debited from A/c X1234 to Swiggy on 01-06-26. Ref No: 612345678901.',
      expectedAmount: 120.0,
      expectedMerchant: 'Swiggy',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 4. ICICI Bank Debit
    const SmsTestCase(
      body: 'Dear Customer, your A/c XX345 is debited with INR 2,500.00 on 01-Jun-26. Info: VPS*Zomato. Ref: 612345678901.',
      expectedAmount: 2500.0,
      expectedMerchant: 'Zomato',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 5. Axis Bank UPI (Long name preservation)
    const SmsTestCase(
      body: 'Sent Rs 400 to Daivik Kumar Rao from A/c XX8901. Ref: 612345678901.',
      expectedAmount: 400.0,
      expectedMerchant: 'Daivik Kumar Rao',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 6. Paytm Wallet
    const SmsTestCase(
      body: 'Paid Rs. 80 to Chai Point using Paytm Wallet for txn 9876543210.',
      expectedAmount: 80.0,
      expectedMerchant: 'Chai Point',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 7. Kotak Mahindra Bank
    const SmsTestCase(
      body: 'Rs. 1,500.00 debited from A/c XX9876 on 01/06/2026 to Reliance Digital. UPI Ref: 612345678901.',
      expectedAmount: 1500.0,
      expectedMerchant: 'Reliance Digital',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 8. PNB Debit
    const SmsTestCase(
      body: 'Dear Customer, Txn of Rs 350.00 debited from A/c XX1234 to Ola Cabs via UPI on 01-06-26.',
      expectedAmount: 350.0,
      expectedMerchant: 'Ola Cabs',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 9. BOB Credit
    const SmsTestCase(
      body: 'Dear Customer, your A/c XX4321 has been credited with Rs. 50,000.00 on 01-Jun-26 by Salary Credit.',
      expectedAmount: 50000.0,
      expectedMerchant: 'Salary Credit',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 10. Canara Bank Debit
    const SmsTestCase(
      body: 'Amt Rs 850.00 debited from A/c XX5678 to Zepto. UPI Ref: 612345678901.',
      expectedAmount: 850.0,
      expectedMerchant: 'Zepto',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 11. Union Bank UPI
    const SmsTestCase(
      body: 'Union Bank: Rs 90.00 debited from A/c XX1234 to Blinkit on 01-06-2026. Ref: 612345678901.',
      expectedAmount: 90.0,
      expectedMerchant: 'Blinkit',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 12. GPay UPI
    const SmsTestCase(
      body: 'You paid ₹250 to Ramesh Kumar using HDFC Bank A/c ending 1234. UPI Ref 612345678901.',
      expectedAmount: 250.0,
      expectedMerchant: 'Ramesh Kumar',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 13. PhonePe UPI
    const SmsTestCase(
      body: 'Paid ₹1,200 to MakeMyTrip via PhonePe. Txn ID: T260601190456.',
      expectedAmount: 1200.0,
      expectedMerchant: 'MakeMyTrip',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 14. Amazon Pay UPI
    const SmsTestCase(
      body: 'Rs 499.00 debited from SBI A/c XX1234 for payment to Amazon Pay. Ref: 612345678901.',
      expectedAmount: 499.0,
      expectedMerchant: 'Amazon Pay',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 15. Airtel Payments Bank
    const SmsTestCase(
      body: 'Paid Rs 199 to Airtel Prepaid Recharge from A/c XX1234. Ref: 612345678901.',
      expectedAmount: 199.0,
      expectedMerchant: 'Airtel Prepaid Recharge',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 16. BHIM UPI
    const SmsTestCase(
      body: 'Transaction successful: Rs 150.00 sent from A/c XX1234 to Soni Grocery Store on 01-06-26.',
      expectedAmount: 150.0,
      expectedMerchant: 'Soni Grocery Store',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 17. Post Office IPPB
    const SmsTestCase(
      body: 'IPPB: Rs 500.00 debited from A/c XX1234 to Electricity Bill. Ref: 612345678901.',
      expectedAmount: 500.0,
      expectedMerchant: 'Electricity Bill',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 18. Standard Chartered
    const SmsTestCase(
      body: 'Spent Rs. 4,500.00 on SCB Card ending 5678 at Lifestyle Store on 01-06-26.',
      expectedAmount: 4500.0,
      expectedMerchant: 'Lifestyle Store',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 19. IDFC First Bank
    const SmsTestCase(
      body: 'Dear Customer, Rs 12,000.00 debited from your A/c XX1234 to Rent Payment on 01-06-2026.',
      expectedAmount: 12000.0,
      expectedMerchant: 'Rent Payment',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 20. Yes Bank UPI
    const SmsTestCase(
      body: 'Yes Bank: Rs 75.00 debited from A/c XX1234. Recipient: Mother Dairy. Ref: 612345678901.',
      expectedAmount: 75.0,
      expectedMerchant: 'Mother Dairy',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 21. Federal Bank
    const SmsTestCase(
      body: 'Federal Bank: Rs 300.00 debited from A/c XX1234. Paid to Star Biryani. Ref: 612345678901.',
      expectedAmount: 300.0,
      expectedMerchant: 'Star Biryani',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 22. HDFC Credit Card (With balance)
    const SmsTestCase(
      body: 'Spent Rs 2,300.00 on HDFC Bank Credit Card ending 9876 at Amazon India on 01-06-26. Avl Limit: Rs 75,000.00.',
      expectedAmount: 2300.0,
      expectedMerchant: 'Amazon India',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 23. SBI Credit Card
    const SmsTestCase(
      body: 'Txn of Rs. 12,500.00 on SBI Card ending 1234 at Flipkart on 01-06-26. Avl Limit: Rs. 45,000.00.',
      expectedAmount: 12500.0,
      expectedMerchant: 'Flipkart',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 24. ICICI Credit Card
    const SmsTestCase(
      body: 'Dear Customer, purchase of Rs. 650.00 done on ICICI Bank Credit Card ending 4321 at Netflix on 01-06-26.',
      expectedAmount: 650.0,
      expectedMerchant: 'Netflix',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 25. Axis Credit Card
    const SmsTestCase(
      body: 'Transaction of INR 1,800.00 on Axis Bank Credit Card ending 2109 at PVR Cinemas on 01-06-2026.',
      expectedAmount: 1800.0,
      expectedMerchant: 'Pvr Cinemas',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 26. OneCard Credit Card
    const SmsTestCase(
      body: 'Spent ₹450 at Starbucks on OneCard ending 1234 on 01-Jun-2026.',
      expectedAmount: 450.0,
      expectedMerchant: 'Starbucks',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 27. IndusInd Bank
    const SmsTestCase(
      body: 'IndusInd Bank A/c XX5678 debited by Rs. 2,200.00 to Apollo Pharmacy on 01-06-26.',
      expectedAmount: 2200.0,
      expectedMerchant: 'Apollo Pharmacy',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 28. RBL Bank
    const SmsTestCase(
      body: 'Spent Rs 950.00 at BookMyShow on RBL Credit Card ending 6543 on 01-06-26.',
      expectedAmount: 950.0,
      expectedMerchant: 'Bookmyshow',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 29. UPI Credit (from Bank)
    const SmsTestCase(
      body: 'Your A/c XX1234 has been credited with Rs 5,000.00 on 01-06-26 from Suresh Patel via UPI Ref: 612345678901.',
      expectedAmount: 5000.0,
      expectedMerchant: 'Suresh Patel',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 30. HDFC Credit (from Bank)
    const SmsTestCase(
      body: 'Dear Customer, A/c **3456 has been credited with ₹12,500.00 on 01-06-26 by Suresh Patel. UPI Ref: 612345678901.',
      expectedAmount: 12500.0,
      expectedMerchant: 'Suresh Patel',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 31. SBI Credit (from Bank)
    const SmsTestCase(
      body: 'Dear SBI User, Rs 2,000.00 credited to A/c X1234 from GPay Transfer on 01-06-26. Ref No: 612345678901.',
      expectedAmount: 2000.0,
      expectedMerchant: 'Gpay Transfer',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 32. ICICI Credit (from Bank)
    const SmsTestCase(
      body: 'Dear Customer, your A/c XX345 is credited with INR 10,000.00 on 01-Jun-26 from Swiggy Refund. Ref: 612345678901.',
      expectedAmount: 10000.0,
      expectedMerchant: 'Swiggy Refund',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 33. Axis Credit (from Bank)
    const SmsTestCase(
      body: 'Received Rs 1,500 from Amit Sharma in A/c XX8901. Ref: 612345678901.',
      expectedAmount: 1500.0,
      expectedMerchant: 'Amit Sharma',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 34. Kotak Credit (from Bank)
    const SmsTestCase(
      body: 'Rs. 500.00 credited to A/c XX9876 on 01/06/2026 from Zepto Cashback. UPI Ref: 612345678901.',
      expectedAmount: 500.0,
      expectedMerchant: 'Zepto Cashback',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 35. PNB Credit (from Bank)
    const SmsTestCase(
      body: 'Dear Customer, Txn of Rs 7,200.00 credited to A/c XX1234 from Father on 01-06-26.',
      expectedAmount: 7200.0,
      expectedMerchant: 'Father',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 36. BOB Debit (from Bank)
    const SmsTestCase(
      body: 'Dear Customer, your A/c XX4321 has been debited by Rs. 3,500.00 on 01-Jun-26 to Reliance Digital.',
      expectedAmount: 3500.0,
      expectedMerchant: 'Reliance Digital',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 37. Canara Credit (from Bank)
    const SmsTestCase(
      body: 'Amt Rs 450.00 credited to A/c XX5678 from Friend. UPI Ref: 612345678901.',
      expectedAmount: 450.0,
      expectedMerchant: 'Friend',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 38. Union Credit (from Bank)
    const SmsTestCase(
      body: 'Union Bank: Rs 15,000.00 credited to A/c XX1234 from Salary on 01-06-2026. Ref: 612345678901.',
      expectedAmount: 15000.0,
      expectedMerchant: 'Salary',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 39. Standard Chartered Credit
    const SmsTestCase(
      body: 'Dear Customer, Rs. 1,200.00 credited to SCB Card ending 5678 from Refund on 01-06-26.',
      expectedAmount: 1200.0,
      expectedMerchant: 'Refund',
      expectedIsDebit: false,
      shouldParse: true,
    ),
    // 40. Mutual Fund SIP Credit/Debit
    const SmsTestCase(
      body: 'Your SIP of Rs 5,000.00 in Groww Mutual Fund was processed successfully on 01-06-2026.',
      expectedAmount: 5000.0,
      expectedMerchant: 'Groww Mutual Fund',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 41. Rent payment via UPI
    const SmsTestCase(
      body: 'Dear Customer, Rs 18,000.00 debited from A/c XX1234 to Ramesh Landlord via UPI Ref: 612345678901.',
      expectedAmount: 18000.0,
      expectedMerchant: 'Ramesh Landlord',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 42. Insurance Payment
    const SmsTestCase(
      body: 'Paid Rs 3,499.00 to HDFC Ergo Insurance on 01-06-26. Ref: 612345678901.',
      expectedAmount: 3499.0,
      expectedMerchant: 'Hdfc Ergo Insurance',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 43. Electricity Bill Auto-debit
    const SmsTestCase(
      body: 'Auto-debit of Rs 2,150.00 processed from your A/c XX1234 to BESCOM on 01-06-2026.',
      expectedAmount: 2150.0,
      expectedMerchant: 'Bescom',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    // 44. Preventing amount leakage ("₹80 paid to ₹80" / "₹400 paid to Rs 400" - User's specific bug)
    const SmsTestCase(
      body: 'Your account XX1234 has been debited for Rs 400.00 to Swiggy on 01-06-26.',
      expectedAmount: 400.0,
      expectedMerchant: 'Swiggy',
      expectedIsDebit: true,
      shouldParse: true,
    ),
    const SmsTestCase(
      body: 'INR 80.00 debited from A/c XX1234 to Daivik Kumar Rao on 01-06-26. Ref: 612345678901.',
      expectedAmount: 80.0,
      expectedMerchant: 'Daivik Kumar Rao',
      expectedIsDebit: true,
      shouldParse: true,
    ),

    // --- REJECTIONS (Non-transaction messages) ---
    // 45. OTP / Non-transaction SMS
    const SmsTestCase(
      body: 'Your OTP for transaction of Rs. 4,500 at Amazon is 123456. Do not share.',
      shouldParse: false,
    ),
    // 46. Promo / Non-transaction SMS
    const SmsTestCase(
      body: 'Get flat Rs 100 cashback on your next Swiggy order! Use code SWIGGY100. Recharge now.',
      shouldParse: false,
    ),
    // 47. Reminder / Non-transaction SMS
    const SmsTestCase(
      body: 'Reminder: Your HDFC Credit Card bill of Rs 12,450.00 is due on 05-06-2026.',
      shouldParse: false,
    ),
    // 48. Balance Alert / Non-transaction SMS
    const SmsTestCase(
      body: 'Your A/c XX1234 has an available balance of Rs 45,670.00. Thank you for banking with us.',
      shouldParse: false,
    ),
    // 49. Failed Txn / Non-transaction SMS
    const SmsTestCase(
      body: 'Transaction failed: Rs 200 to Swiggy could not be processed due to network issues.',
      shouldParse: false,
    ),
    // 50. Declined Txn / Non-transaction SMS
    const SmsTestCase(
      body: 'Txn of Rs. 500.00 declined on Card ending 1234 due to insufficient funds.',
      shouldParse: false,
    ),
    // 51. Arbitrary non-financial text
    const SmsTestCase(
      body: 'Hey, are we still meeting for lunch today at 1 PM?',
      shouldParse: false,
    ),
  ];

  test('Run SMS Parser on 51 Real-world Indian SMS Samples', () {
    int passed = 0;
    int failed = 0;

    print('\n==================================================');
    print('          RUNNING SMS PARSER TEST SUITE           ');
    print('==================================================\n');

    for (int i = 0; i < testCases.length; i++) {
      final tc = testCases[i];
      final input = <String, dynamic>{
        'body': tc.body,
        'date': DateTime.now().millisecondsSinceEpoch,
        'id': 'test_case_$i',
      };

      // Call the parser on the single item
      final parsedList = parseSmsBatchForTesting([input]);
      final success = parsedList.isNotEmpty;

      if (tc.shouldParse) {
        if (!success) {
          print('❌ Test Case #${i + 1} Failed!');
          print('   SMS Text: "${tc.body}"');
          print('   Expected: Parse success');
          print('   Actual: Rejected / Not parsed\n');
          failed++;
          continue;
        }

        final tx = parsedList.first;
        final amountOk = tx.amount == tc.expectedAmount;
        final merchantOk = tx.merchant.toLowerCase() == tc.expectedMerchant?.toLowerCase();
        final typeOk = tx.isDebit == tc.expectedIsDebit;

        if (amountOk && merchantOk && typeOk) {
          passed++;
        } else {
          print('❌ Test Case #${i + 1} Failed!');
          print('   SMS Text: "${tc.body}"');
          print('   Expected: Amount=${tc.expectedAmount}, Merchant="${tc.expectedMerchant}", isDebit=${tc.expectedIsDebit}');
          print('   Actual: Amount=${tx.amount}, Merchant="${tx.merchant}", isDebit=${tx.isDebit}\n');
          failed++;
        }
      } else {
        if (success) {
          final tx = parsedList.first;
          print('❌ Test Case #${i + 1} Failed (Should have been ignored/rejected)!');
          print('   SMS Text: "${tc.body}"');
          print('   Actual: Parsed as Amount=${tx.amount}, Merchant="${tx.merchant}"\n');
          failed++;
        } else {
          passed++;
        }
      }
    }

    final total = testCases.length;
    final accuracy = (passed / total) * 100.0;
    print('==================================================');
    print('                TEST RESULT SUMMARY               ');
    print('==================================================');
    print('Total Cases Evaluated : $total');
    print('Passed Cases          : $passed');
    print('Failed Cases          : $failed');
    print('Overall Accuracy      : ${accuracy.toStringAsFixed(2)}%');
    print('==================================================\n');

    expect(failed, 0, reason: 'Some test cases failed. See console output above.');
  });
}
