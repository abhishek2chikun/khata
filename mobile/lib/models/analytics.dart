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

class TopProductRevenue {
  const TopProductRevenue({required this.productName, required this.revenue});

  final String productName;
  final double revenue;
}

class TopProductProfit {
  const TopProductProfit({required this.productName, required this.profit});

  final String productName;
  final double profit;
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

class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.revenue,
    required this.profit,
  });

  final String date;
  final double revenue;
  final double profit;
}

class Dashboard {
  const Dashboard({
    required this.totalRevenue,
    required this.totalProfit,
    required this.customerReceivables,
    required this.buyerPayables,
    required this.activeInvoiceCount,
    required this.averageInvoiceValue,
    required this.dailyTrend,
    required this.revenueByCompany,
    required this.profitByCompany,
    required this.revenueByCustomer,
    required this.customerKhataBalances,
    required this.buyerPendingPayables,
    required this.topProductsByQuantity,
    required this.topProductsByRevenue,
    required this.topProductsByProfit,
    required this.lowStock,
  });

  factory Dashboard.empty() {
    return const Dashboard(
      totalRevenue: 0,
      totalProfit: 0,
      customerReceivables: 0,
      buyerPayables: 0,
      activeInvoiceCount: 0,
      averageInvoiceValue: 0,
      dailyTrend: [],
      revenueByCompany: [],
      profitByCompany: [],
      revenueByCustomer: [],
      customerKhataBalances: [],
      buyerPendingPayables: [],
      topProductsByQuantity: [],
      topProductsByRevenue: [],
      topProductsByProfit: [],
      lowStock: [],
    );
  }

  final double totalRevenue;
  final double totalProfit;
  final double customerReceivables;
  final double buyerPayables;
  final int activeInvoiceCount;
  final double averageInvoiceValue;
  final List<DailyTrendPoint> dailyTrend;
  final List<RevenueByEntry> revenueByCompany;
  final List<ProfitByEntry> profitByCompany;
  final List<RevenueByEntry> revenueByCustomer;
  final List<CustomerKhataBalance> customerKhataBalances;
  final List<BuyerPayable> buyerPendingPayables;
  final List<TopProduct> topProductsByQuantity;
  final List<TopProductRevenue> topProductsByRevenue;
  final List<TopProductProfit> topProductsByProfit;
  final List<LowStockEntry> lowStock;

  bool get hasData {
    if (totalRevenue != 0 ||
        totalProfit != 0 ||
        activeInvoiceCount > 0 ||
        customerReceivables != 0 ||
        buyerPayables != 0) {
      return true;
    }
    return revenueByCompany.isNotEmpty ||
        profitByCompany.isNotEmpty ||
        revenueByCustomer.isNotEmpty ||
        customerKhataBalances.any((entry) => entry.balance != 0) ||
        buyerPendingPayables.any((entry) => entry.payable != 0) ||
        topProductsByQuantity.isNotEmpty ||
        topProductsByRevenue.isNotEmpty ||
        topProductsByProfit.isNotEmpty;
  }
}
