class RevenueByEntry {
  const RevenueByEntry({required this.name, required this.revenue});

  final String name;
  final double revenue;
}

class ProfitByEntry {
  const ProfitByEntry({required this.name, required this.profit});

  final String name;
  final double profit;
}

class CustomerKhataBalance {
  const CustomerKhataBalance({
    required this.customerName,
    required this.balance,
  });

  final String customerName;
  final double balance;
}

class BuyerPayable {
  const BuyerPayable({required this.buyerName, required this.payable});

  final String buyerName;
  final double payable;
}

class TopProduct {
  const TopProduct({required this.productName, required this.quantity});

  final String productName;
  final double quantity;
}

class LowStockEntry {
  const LowStockEntry({
    required this.productName,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  });

  final String productName;
  final double quantityOnHand;
  final double lowStockThreshold;
}

class Dashboard {
  const Dashboard({
    required this.revenueByCompany,
    required this.profitByCompany,
    required this.customerKhataBalances,
    required this.buyerPendingPayables,
    required this.topProductsByQuantity,
    required this.lowStock,
  });

  factory Dashboard.empty() {
    return const Dashboard(
      revenueByCompany: [],
      profitByCompany: [],
      customerKhataBalances: [],
      buyerPendingPayables: [],
      topProductsByQuantity: [],
      lowStock: [],
    );
  }

  final List<RevenueByEntry> revenueByCompany;
  final List<ProfitByEntry> profitByCompany;
  final List<CustomerKhataBalance> customerKhataBalances;
  final List<BuyerPayable> buyerPendingPayables;
  final List<TopProduct> topProductsByQuantity;
  final List<LowStockEntry> lowStock;
}
