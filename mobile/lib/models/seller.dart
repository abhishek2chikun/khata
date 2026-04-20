class Seller {
  const Seller({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.gstin,
    required this.state,
    required this.stateCode,
    required this.isActive,
    required this.pendingBalance,
  });

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? gstin;
  final String? state;
  final String? stateCode;
  final bool isActive;
  final double pendingBalance;

  Seller copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? gstin,
    String? state,
    String? stateCode,
    bool? isActive,
    double? pendingBalance,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      isActive: isActive ?? this.isActive,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
      gstin: json['gstin'] as String?,
      state: json['state'] as String?,
      stateCode: json['state_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      pendingBalance: _toDouble(json['pending_balance']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
