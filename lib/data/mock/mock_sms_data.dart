  // Mock SMS data for web platform testing.
// Extracted from test/sms_parser_test.dart

const List<String> mockSmsList = [
  // 1. Porter Thursday payment
  'Porter payment of ₹410 on Thursday',
  // 2. HDFC Debit / UPI
  'Dear Customer, ₹410.00 has been debited from your A/c **3456 to PORTER on 01-06-26. Info: UPI-PORTER-61501234. UPI Ref: 615012345678.',
  // 3. SBI UPI Debit
  'Dear SBI User, Rs 120.00 debited from A/c X1234 to Swiggy on 01-06-26. Ref No: 612345678901.',
  // 4. ICICI Bank Debit
  'Dear Customer, your A/c XX345 is debited with INR 2,500.00 on 01-Jun-26. Info: VPS*Zomato. Ref: 612345678901.',
  // 5. Axis Bank UPI (Long name preservation)
  'Sent Rs 400 to Arvind Kumar Das from A/c XX8901. Ref: 612345678901.',
  // 6. Paytm Wallet
  'Paid Rs. 80 to Chai Point using Paytm Wallet for txn 9876543210.',
  // 7. Kotak Mahindra Bank
  'Rs. 1,500.00 debited from A/c XX9876 on 01/06/2026 to Reliance Digital. UPI Ref: 612345678901.',
  // 8. PNB Debit
  'Dear Customer, Txn of Rs 350.00 debited from A/c XX1234 to Ola Cabs via UPI on 01-06-26.',
  // 9. BOB Credit
  'Dear Customer, your A/c XX4321 has been credited with Rs. 50,000.00 on 01-Jun-26 by Salary Credit.',
  // 10. Canara Bank Debit
  'Amt Rs 850.00 debited from A/c XX5678 to Zepto. UPI Ref: 612345678901.',
  // 11. Union Bank UPI
  'Union Bank: Rs 90.00 debited from A/c XX1234 to Blinkit on 01-06-2026. Ref: 612345678901.',
  // 12. GPay UPI
  'You paid ₹250 to Dinesh Gupta using HDFC Bank A/c ending 1234. UPI Ref 612345678901.',
  // 13. PhonePe UPI
  'Paid ₹1,200 to MakeMyTrip via PhonePe. Txn ID: T260601190456.',
  // 14. Amazon Pay UPI
  'Rs 499.00 debited from SBI A/c XX1234 for payment to Amazon Pay. Ref: 612345678901.',
  // 15. Airtel Payments Bank
  'Paid Rs 199 to Airtel Prepaid Recharge from A/c XX1234. Ref: 612345678901.',
  // 16. BHIM UPI
  'Transaction successful: Rs 150.00 sent from A/c XX1234 to Soni Grocery Store on 01-06-26.',
  // 17. Post Office IPPB
  'IPPB: Rs 500.00 debited from A/c XX1234 to Electricity Bill. Ref: 612345678901.',
  // 18. Standard Chartered
  'Spent Rs. 4,500.00 on SCB Card ending 5678 at Lifestyle Store on 01-06-26.',
  // 19. IDFC First Bank
  'Dear Customer, Rs 12,000.00 debited from your A/c XX1234 to Rent Payment on 01-06-2026.',
  // 20. Yes Bank UPI
  'Yes Bank: Rs 75.00 debited from A/c XX1234. Recipient: Mother Dairy. Ref: 612345678901.',
  // 21. Federal Bank
  'Federal Bank: Rs 300.00 debited from A/c XX1234. Paid to Star Biryani. Ref: 612345678901.',
  // 22. HDFC Credit Card (With balance)
  'Spent Rs 2,300.00 on HDFC Bank Credit Card ending 9876 at Amazon India on 01-06-26. Avl Limit: Rs 75,000.00.',
  // 23. SBI Credit Card
  'Txn of Rs. 12,500.00 on SBI Card ending 1234 at Flipkart on 01-06-26. Avl Limit: Rs. 45,000.00.',
  // 24. ICICI Credit Card
  'Dear Customer, purchase of Rs. 650.00 done on ICICI Bank Credit Card ending 4321 at Netflix on 01-06-26.',
  // 25. Axis Credit Card
  'Transaction of INR 1,800.00 on Axis Bank Credit Card ending 2109 at PVR Cinemas on 01-06-2026.',
  // 26. OneCard Credit Card
  'Spent ₹450 at Starbucks on OneCard ending 1234 on 01-Jun-2026.',
  // 27. IndusInd Bank
  'IndusInd Bank A/c XX5678 debited by Rs. 2,200.00 to Apollo Pharmacy on 01-06-26.',
  // 28. RBL Bank
  'Spent Rs 950.00 at BookMyShow on RBL Credit Card ending 6543 on 01-06-26.',
  // 29. UPI Credit (from Bank)
  'Your A/c XX1234 has been credited with Rs 5,000.00 on 01-06-26 from Ganesh Verma via UPI Ref: 612345678901.',
  // 30. HDFC Credit (from Bank)
  'Dear Customer, A/c **3456 has been credited with ₹12,500.00 on 01-06-26 by Ganesh Verma. UPI Ref: 612345678901.',
  // 31. SBI Credit (from Bank)
  'Dear SBI User, Rs 2,000.00 credited to A/c X1234 from GPay Transfer on 01-06-26. Ref No: 612345678901.',
  // 32. ICICI Credit (from Bank)
  'Dear Customer, your A/c XX345 is credited with INR 10,000.00 on 01-Jun-26 from Swiggy Refund. Ref: 612345678901.',
  // 33. Axis Credit (from Bank)
  'Received Rs 1,500 from Anil Thakur in A/c XX8901. Ref: 612345678901.',
  // 34. Kotak Credit (from Bank)
  'Rs. 500.00 credited to A/c XX9876 on 01/06/2026 from Zepto Cashback. UPI Ref: 612345678901.',
  // 35. PNB Credit (from Bank)
  'Dear Customer, Txn of Rs 7,200.00 credited to A/c XX1234 from Father on 01-06-26.',
  // 36. BOB Debit (from Bank)
  'Dear Customer, your A/c XX4321 has been debited by Rs. 3,500.00 on 01-Jun-26 to Reliance Digital.',
  // 37. Canara Credit (from Bank)
  'Amt Rs 450.00 credited to A/c XX5678 from Friend. UPI Ref: 612345678901.',
  // 38. Union Credit (from Bank)
  'Union Bank: Rs 15,000.00 credited to A/c XX1234 from Salary on 01-06-2026. Ref: 612345678901.',
  // 39. Standard Chartered Credit
  'Dear Customer, Rs. 1,200.00 credited to SCB Card ending 5678 from Refund on 01-06-26.',
  // 40. Mutual Fund SIP Credit/Debit
  'Your SIP of Rs 5,000.00 in Groww Mutual Fund was processed successfully on 01-06-2026.',
  // 41. Rent payment via UPI
  'Dear Customer, Rs 18,000.00 debited from A/c XX1234 to Ramesh Landlord via UPI Ref: 612345678901.',
  // 42. Insurance Payment
  'Paid Rs 3,499.00 to HDFC Ergo Insurance on 01-06-26. Ref: 612345678901.',
  // 43. Electricity Bill Auto-debit
  'Auto-debit of Rs 2,150.00 processed from your A/c XX1234 to BESCOM on 01-06-2026.',
  // 44. Preventing amount leakage ("₹80 paid to ₹80" / "₹400 paid to Rs 400")
  'Your account XX1234 has been debited for Rs 400.00 to Swiggy on 01-06-26.',
  // 45. Amount + reference number
  'INR 80.00 debited from A/c XX1234 to Arvind Kumar Das on 01-06-26. Ref: 612345678901.',
  // 56. Reference number rejection (will be parsed with merchant "Unknown")
  'Amt Rs 850.00 debited from A/c XX5678 to 615179062849. UPI Ref: 615179062849',
  // 52. ICICI Format 1 — P2P debit
  'ICICI Bank Acct XX946 debited for Rs 84.00 on 28-May-26; MR RAKESH SHARMA credited. UPI:651446008723',
  // 53. ICICI Format 2 — Merchant debit
  'Rs. 178.66 debited from ICICI Bank Acc XX946 on 31-May-26 VIN*Raz INOX . Bal Rs. 406.96',
  // 54. ICICI Format 3 — Credit
  'Dear Customer, Acct XX946 is credited with Rs 175.00 on 29-May-26 from ROHIT MANDAL. UPI:651576400335-ICICI Bank',
  // 55. Generic P2P from unknown bank with paid to NAME pattern
  'Paid Rs. 150 to Vikram Kumar Singh from unknown bank.',
  // 60. ICICI P2P — Full name "Vikram Kumar Singh" must NOT truncate
  'ICICI Bank Acct XX946 debited for Rs 84.00 on 28-May-26; VIKRAM KUMAR SINGH credited. UPI:651446008723',
];
