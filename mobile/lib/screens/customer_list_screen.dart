import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../widgets/customer_card.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final bool initialFilterHasDebt;

  const CustomerListScreen({Key? key, this.initialFilterHasDebt = false}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  bool _hasDebtOnly = false;

  @override
  void initState() {
    super.initState();
    _hasDebtOnly = widget.initialFilterHasDebt;
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _customerService.getCustomers(
        search: _searchController.text.trim(),
        hasBalanceOnly: _hasDebtOnly,
      );
      if (mounted) {
        setState(() {
          _customers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalOutstanding {
    double total = 0.0;
    for (var c in _customers) {
      if (c.balance > 0) total += c.balance;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Customer Khata (बहीखाता)",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          elevation: 0,
          backgroundColor: Colors.transparent,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text(
            "Add Customer (नया ग्राहक)",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            );
            if (res == true) _fetchCustomers();
          },
        ),
      ),
      body: Column(
        children: [
          // Total Khata Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.debtRedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.debtRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Khata Due (कुल उधार बाकी)",
                        style: TextStyle(fontSize: 13, color: AppColors.debtRed, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "मार्केट से कुल लेना है",
                        style: TextStyle(fontSize: 11, color: AppColors.debtRed.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    "₹${_totalOutstanding.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.debtRed,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search customer name or phone...",
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchCustomers();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => _fetchCustomers(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() => _hasDebtOnly = !_hasDebtOnly);
                    _fetchCustomers();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: _hasDebtOnly ? AppColors.debtRed : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasDebtOnly ? Colors.transparent : AppColors.cardBorder,
                      ),
                      boxShadow: _hasDebtOnly
                          ? [
                              BoxShadow(
                                color: AppColors.debtRed.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          size: 16,
                          color: _hasDebtOnly ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Due Only",
                          style: TextStyle(
                            color: _hasDebtOnly ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "No khata customers found",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Tap '+ Add Customer' to register a new Khata customer",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 84, left: 14, right: 14, top: 4),
                          itemCount: _customers.length,
                          itemBuilder: (ctx, i) {
                            final c = _customers[i];
                            return CustomerCard(
                              customer: c,
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customerId: c.id)),
                                );
                                if (res == true) _fetchCustomers();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
