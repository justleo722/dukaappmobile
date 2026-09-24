// ignore_for_file: prefer_constructors_over_static_methods

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? tinNumber;
  final String? location;
  final double creditLimit;
  final double totalSpent;
  final double walletBalance;
  final double creditBalance;
  final int totalPurchases;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.tinNumber,
    this.location,
    this.creditLimit = 0.0,
    this.totalSpent = 0.0,
    this.walletBalance = 0.0,
    this.creditBalance = 0.0,
    this.totalPurchases = 0,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? tinNumber,
    String? location,
    double? creditLimit,
    double? totalSpent,
    double? walletBalance,
    double? creditBalance,
    int? totalPurchases,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tinNumber: tinNumber ?? this.tinNumber,
      location: location ?? this.location,
      creditLimit: creditLimit ?? this.creditLimit,
      totalSpent: totalSpent ?? this.totalSpent,
      walletBalance: walletBalance ?? this.walletBalance,
      creditBalance: creditBalance ?? this.creditBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Build a [Customer] from an API JSON object.
  ///
  /// Field mapping:
  ///  - customer_id → id
  ///  - name, phone, email
  ///  - customer_tin → tinNumber
  ///  - address → location
  ///  - credit_limit → creditLimit
  ///  - wallet_balance (prepaid wallet) → walletBalance
  ///  - credit_balance (amount owed) → creditBalance
  ///  - record_date → createdAt
  static Customer fromJson(Map<String, dynamic> j) {
    double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    return Customer(
      id: j['customer_id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      email: j['email']?.toString(),
      tinNumber: j['customer_tin']?.toString(),
      location: j['address']?.toString(),
      creditLimit: _d(j['credit_limit']),
      totalSpent: _d(j['total_spent'] ?? j['totalSpent']),
      walletBalance: _d(j['wallet_balance']),
      creditBalance: _d(j['credit_balance']),
      totalPurchases: int.tryParse(j['total_purchases']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(j['record_date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Serialize back for display / legacy use.
  Map<String, dynamic> toJson() => {
    'customer_id': id,
    'name': name,
    'phone': phone,
    if (email != null) 'email': email,
    if (tinNumber != null) 'customer_tin': tinNumber,
    if (location != null) 'address': location,
    'credit_limit': creditLimit,
    'wallet_balance': walletBalance,
    'credit_balance': creditBalance,
  };

  static List<Customer> sampleCustomers() {
    return [
      Customer(
        id: '1',
        name: 'Amina Juma',
        phone: '+255 712 345 678',
        email: 'amina@example.com',
        tinNumber: '123-456-789',
        location: 'Dar es Salaam',
        creditLimit: 500000,
        totalSpent: 450000,
        creditBalance: 0,
        totalPurchases: 12,
        createdAt: DateTime(2025, 1, 15),
      ),
      Customer(
        id: '2',
        name: 'Hassan Mwangi',
        phone: '+255 723 456 789',
        tinNumber: '987-654-321',
        location: 'Arusha',
        creditLimit: 200000,
        totalSpent: 320000,
        creditBalance: 50000,
        totalPurchases: 8,
        createdAt: DateTime(2025, 2, 20),
      ),
      Customer(
        id: '3',
        name: 'Fatima Omar',
        phone: '+255 734 567 890',
        email: 'fatima@example.com',
        location: 'Mwanza',
        creditLimit: 1000000,
        totalSpent: 780000,
        creditBalance: 0,
        totalPurchases: 23,
        createdAt: DateTime(2024, 11, 5),
      ),
      Customer(
        id: '4',
        name: 'Juma Bakari',
        phone: '+255 745 678 901',
        location: 'Dodoma',
        creditLimit: 150000,
        totalSpent: 150000,
        creditBalance: 25000,
        totalPurchases: 5,
        createdAt: DateTime(2025, 3, 10),
      ),
      Customer(
        id: '5',
        name: 'Neema Kimaro',
        phone: '+255 756 789 012',
        email: 'neema@example.com',
        tinNumber: '456-789-123',
        location: 'Tanga',
        creditLimit: 300000,
        totalSpent: 920000,
        creditBalance: 0,
        totalPurchases: 31,
        createdAt: DateTime(2024, 9, 1),
      ),
      Customer(
        id: '6',
        name: 'Ibrahim Hassan',
        phone: '+255 767 890 123',
        location: 'Morogoro',
        creditLimit: 100000,
        totalSpent: 210000,
        creditBalance: 15000,
        totalPurchases: 7,
        createdAt: DateTime(2025, 4, 18),
      ),
      Customer(
        id: '7',
        name: 'Rehema Salim',
        phone: '+255 778 901 234',
        tinNumber: '789-123-456',
        location: 'Zanzibar',
        creditLimit: 400000,
        totalSpent: 560000,
        creditBalance: 0,
        totalPurchases: 16,
        createdAt: DateTime(2025, 1, 8),
      ),
    ];
  }
}
