class DashboardModel {
  final double todaySalesAmount;
  final int todayTransactionsCount;
  final double todayCashSales;
  final double todayUpiSales;
  final double todayCreditSales;
  final double todayPaidSales;
  final double todayUnpaidSales;
  final double todayProfit;
  final double totalOutstandingCredit;
  final int lowStockCount;
  final int totalProductsCount;
  final int totalCustomersCount;

  DashboardModel({
    required this.todaySalesAmount,
    required this.todayTransactionsCount,
    required this.todayCashSales,
    required this.todayUpiSales,
    required this.todayCreditSales,
    this.todayPaidSales = 0.0,
    this.todayUnpaidSales = 0.0,
    this.todayProfit = 0.0,
    required this.totalOutstandingCredit,
    required this.lowStockCount,
    required this.totalProductsCount,
    required this.totalCustomersCount,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      todaySalesAmount: double.tryParse(json['today_sales_amount'].toString()) ?? 0.0,
      todayTransactionsCount: json['today_transactions_count'] as int? ?? 0,
      todayCashSales: double.tryParse(json['today_cash_sales'].toString()) ?? 0.0,
      todayUpiSales: double.tryParse(json['today_upi_sales'].toString()) ?? 0.0,
      todayCreditSales: double.tryParse(json['today_credit_sales'].toString()) ?? 0.0,
      todayPaidSales: double.tryParse(json['today_paid_sales'].toString()) ?? 0.0,
      todayUnpaidSales: double.tryParse(json['today_unpaid_sales'].toString()) ?? 0.0,
      todayProfit: double.tryParse(json['today_profit'].toString()) ?? 0.0,
      totalOutstandingCredit: double.tryParse(json['total_outstanding_credit'].toString()) ?? 0.0,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      totalProductsCount: json['total_products_count'] as int? ?? 0,
      totalCustomersCount: json['total_customers_count'] as int? ?? 0,
    );
  }
}
