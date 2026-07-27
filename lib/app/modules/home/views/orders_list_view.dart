import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/modules/home/views/order_summary_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every diet plan request ("order") the patient has ever submitted, newest
/// first - one per renewal cycle. Tapping one opens the same Order Summary
/// screen Home uses, but scoped to that specific order (see
/// OrderSummaryView's requestId param) - editable only while that order is
/// still Unpaid, exactly like the Home button.
class OrdersListView extends StatefulWidget {
  const OrdersListView({super.key});

  @override
  State<OrdersListView> createState() => _OrdersListViewState();
}

class _OrdersListViewState extends State<OrdersListView> {
  final RequestDietService _service = RequestDietService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final response = await _service.listRequests();
    final data = response?['data'];
    setState(() {
      _orders = data is List
          ? data.map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      _loading = false;
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
      case 'PartiallyPaid':
        return const Color(0xff0E9F6E);
      case 'Unpaid':
        return const Color(0xffDE2493);
      default:
        return const Color(0xff9DA4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Your Orders',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: CustomText(
                    text: 'No orders yet.',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff9DA4AE),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final status = (order['status'] ?? '').toString();
                      final plan = (order['membershipPlan'] ?? 'Membership')
                          .toString();
                      final amount = order['membershipAmount'];
                      final requestId = order['requestId'].toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Get.to(
                            () => OrderSummaryView(requestId: requestId),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: plan,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff111927),
                                    ),
                                    const SizedBox(height: 4),
                                    CustomText(
                                      text:
                                          'Placed on ${_formatDate(order['createdAt']?.toString())}',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff6C737F),
                                    ),
                                    if (amount != null) ...[
                                      const SizedBox(height: 4),
                                      CustomText(
                                        text: '₹${amount.toString()}',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xff851653),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        status,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: CustomText(
                                      text: status.isEmpty ? '--' : status,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xff9DA4AE),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
