class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? companyName;
  final String? address;
  final String? tinNumber;
  final double creditBalance;
  final double totalPurchases;
  final int totalOrders;
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.companyName,
    this.address,
    this.tinNumber,
    this.creditBalance = 0.0,
    this.totalPurchases = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? companyName,
    String? address,
    String? tinNumber,
    double? creditBalance,
    double? totalPurchases,
    int? totalOrders,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      tinNumber: tinNumber ?? this.tinNumber,
      creditBalance: creditBalance ?? this.creditBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> j) {
    return Supplier(
      id: j['supplier_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? j['supplier_name']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      email: j['email']?.toString(),
      companyName: j['company_name']?.toString() ?? j['name']?.toString(),
      address: j['address']?.toString(),
      tinNumber: j['tin_number']?.toString() ?? j['supplier_tin']?.toString(),
      creditBalance: _toDouble(j['credit_balance'] ?? j['balance'] ?? j['wallet_balance']),
      totalPurchases: _toDouble(j['total_purchases'] ?? j['total_amount']),
      totalOrders: (j['total_orders'] as num?)?.toInt() ?? (j['purchase_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(j['record_date'] ?? j['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'supplier_id': id,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (companyName != null) 'company_name': companyName,
        if (address != null) 'address': address,
        if (tinNumber != null) 'tin_number': tinNumber,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }

  static List<Supplier> sampleSuppliers() {
    return [
      Supplier(
        id: '1',
        name: 'TANZANIA BEVERAGES LTD',
        phone: '+255 22 211 0001',
        email: 'info@tabl.co.tz',
        companyName: 'Tanzania Beverages Ltd',
        address: 'Sanza Street, Dar es Salaam',
        tinNumber: '100-123-456',
        creditBalance: 0,
        totalPurchases: 4500000,
        totalOrders: 32,
        createdAt: DateTime(2024, 6, 15),
      ),
      Supplier(
        id: '2',
        name: 'KILIMANJARO PREMIUM LTD',
        phone: '+255 27 275 0002',
        email: 'sales@kpl.co.tz',
        companyName: 'Kilimanjaro Premium Ltd',
        address: 'Uru Street, Moshi',
        tinNumber: '200-456-789',
        creditBalance: 150000,
        totalPurchases: 2800000,
        totalOrders: 21,
        createdAt: DateTime(2024, 8, 20),
      ),
      Supplier(
        id: '3',
        name: 'Coca-Cola Kwanza Ltd',
        phone: '+255 22 213 0003',
        companyName: 'Coca-Cola Kwanza Ltd',
        address: 'Mkuranga Road, Dar es Salaam',
        creditBalance: 0,
        totalPurchases: 6200000,
        totalOrders: 45,
        createdAt: DateTime(2024, 3, 10),
      ),
      Supplier(
        id: '4',
        name: 'SAFARI BREWERIES LTD',
        phone: '+255 22 215 0004',
        email: 'orders@safari-breweries.co.tz',
        companyName: 'Safari Breweries Ltd',
        address: 'Mbezi Beach, Dar es Salaam',
        tinNumber: '300-789-012',
        creditBalance: 280000,
        totalPurchases: 3500000,
        totalOrders: 28,
        createdAt: DateTime(2024, 5, 25),
      ),
      Supplier(
        id: '5',
        name: 'JUMA SUPPLIERS',
        phone: '+255 713 456 789',
        email: 'juma.suppliers@gmail.com',
        companyName: 'Juma Suppliers & General Traders',
        address: 'Kariakoo Market, Dar es Salaam',
        creditBalance: 50000,
        totalPurchases: 1200000,
        totalOrders: 15,
        createdAt: DateTime(2025, 1, 5),
      ),
      Supplier(
        id: '6',
        name: 'AMINA TRADERS',
        phone: '+255 724 567 890',
        companyName: 'Amina Traders',
        address: 'Nyerere Road, Arusha',
        creditBalance: 0,
        totalPurchases: 890000,
        totalOrders: 10,
        createdAt: DateTime(2025, 2, 18),
      ),
      Supplier(
        id: '7',
        name: 'HASSAN WHOLESALE',
        phone: '+255 735 678 901',
        email: 'hassan.wholesale@yahoo.com',
        companyName: 'Hassan Wholesale Distributors',
        address: 'Soweto East, Dar es Salaam',
        tinNumber: '400-321-654',
        creditBalance: 120000,
        totalPurchases: 2100000,
        totalOrders: 19,
        createdAt: DateTime(2024, 11, 12),
      ),
      Supplier(
        id: '8',
        name: 'FATIMA ENTERPRISES',
        phone: '+255 746 789 012',
        companyName: 'Fatima Enterprises',
        address: 'Mwanakwerekwe, Zanzibar',
        creditBalance: 0,
        totalPurchases: 750000,
        totalOrders: 8,
        createdAt: DateTime(2025, 3, 1),
      ),
    ];
  }
}
