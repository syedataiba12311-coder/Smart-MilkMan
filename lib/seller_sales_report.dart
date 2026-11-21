import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'app_theme.dart';

class SalesRevenuePage extends StatefulWidget {
  final String dairyName;
  const SalesRevenuePage({super.key, required this.dairyName});

  @override
  State<SalesRevenuePage> createState() => _SalesRevenuePageState();
}

class _SalesRevenuePageState extends State<SalesRevenuePage> {
  double totalRevenue = 0;
  double pendingRevenue = 0;
  List<Map<String, dynamic>> recentOrders = [];
  Map<int, double> weeklySales = {}; // 0=Mon, 6=Sun
  bool isLoading = true;

  StreamSubscription<QuerySnapshot>? _salesSubscription;

  @override
  void initState() {
    super.initState();
    _startSalesStream();
  }

  @override
  void dispose() {
    _salesSubscription?.cancel();
    super.dispose();
  }

  void _startSalesStream() {
    _salesSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('dairyName', isEqualTo: widget.dairyName)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((query) {
      _processSalesData(query);
    }, onError: (e) {
      debugPrint("Error fetching sales stream: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void _processSalesData(QuerySnapshot query) {
    try {

      double total = 0;
      double pending = 0;
      List<Map<String, dynamic>> orders = [];
      Map<int, double> weekly = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

      final now = DateTime.now();
      // Calculate start of the current week (Monday) at 00:00:00
      final startOfWeek = now
          .subtract(Duration(days: now.weekday - 1))
          .subtract(
            Duration(
              hours: now.hour,
              minutes: now.minute,
              seconds: now.second,
              milliseconds: now.millisecond,
            ),
          );

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Pending';

        // Parse price safely (handle String or num)
        double price = 0.0;
        try {
          final priceVal = data['totalPrice'];
          if (priceVal is num) {
            price = priceVal.toDouble();
          } else if (priceVal is String) {
            price = double.tryParse(priceVal) ?? 0.0;
          }
        } catch (e) {
          debugPrint("Error parsing price for order ${doc.id}: $e");
        }

        final timestamp = data['orderDate'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();

        if (status == 'Rejected' || status == 'Cancelled') continue;

        bool isPaid = data['paymentStatus'] == 'Paid' || status == 'Paid' || status == 'Completed' || status == 'Delivered';

        if (isPaid) {
          total += price;

          // Weekly Sales Logic (Only include actual paid revenue in chart)
          if (date.isAfter(startOfWeek)) {
            int dayIndex = date.weekday - 1; // 1=Mon -> 0
            if (dayIndex >= 0 && dayIndex <= 6) {
              weekly[dayIndex] = (weekly[dayIndex] ?? 0) + price;
            }
          }
        } else {
          pending += price;
        }

        // Populate recent orders list (limit to 20)
        if (orders.length < 20) {
          orders.add({...data, 'id': doc.id, 'date': date});
        }
      }

      if (mounted) {
        setState(() {
          totalRevenue = total;
          pendingRevenue = pending;
          recentOrders = orders;
          weeklySales = weekly;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching sales data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Sales & Revenue",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Total Revenue",
                            totalRevenue,
                            const Color(0xFF667EEA),
                            const Color(0xFF764BA2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            "Pending",
                            pendingRevenue,
                            const Color(0xFFF6D365),
                            const Color(0xFFFDA085),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Chart Section
                    Text(
                      "Weekly Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),

                    // Recent Orders Section
                    Text(
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentOrdersList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color1,
    Color color2,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Rs. ${NumberFormat.compact().format(amount)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    double maxY = 0;
    if (weeklySales.isNotEmpty) {
      maxY = weeklySales.values.reduce((a, b) => a > b ? a : b);
    }
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Rs. ${rod.toY.round()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[100], strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklySales[index] ?? 0,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey[50],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    if (recentOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No recent orders found.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        final customerId = order['customerId']; // Should be String
        final date = order['date'] as DateTime;
        // final price = 0.0; // Unused
        double displayPrice = 0.0;
        try {
          final priceVal = order['totalPrice'];
          if (priceVal is num) {
            displayPrice = priceVal.toDouble();
          } else if (priceVal is String) {
            displayPrice = double.tryParse(priceVal) ?? 0.0;
          }
        } catch (e) {
          // ignore
        }

        final status = order['status'] ?? 'Pending';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('customer')
              .doc(customerId)
              .get(),
          builder: (context, snapshot) {
            String customerName = "Unknown Customer";
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              customerName = data?['fullname'] ?? "Unknown";
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: _getStatusColor(status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(date),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rs. ${NumberFormat('#,##0').format(displayPrice)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
      case 'Completed':
      case 'Delivered':
        return Colors.green;
      case 'Accepted':
      case 'On Route':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
