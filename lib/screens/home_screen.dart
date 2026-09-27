import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../main.dart';
import '../utils/category_helper.dart';
import 'add_edit_expense_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currency = NumberFormat('#,##0.00');

  String _searchQuery = '';
  String _selectedMonthFilter = 'This Month';
  String _selectedCategoryFilter = 'All';
  bool _isLoading = false;

  void _triggerFakeLoading([int milliseconds = 600]) {
    setState(() => _isLoading = true);
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _resetAndAddSampleData() async {
    final expensesRef = FirebaseFirestore.instance.collection('expenses');
    
    // Clear existing data
    final existingDocs = await expensesRef.get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    final random = Random();
    final categories = kCategories;
    
    final titles = {
      'Food': ['Lunch at Cafe', 'Groceries', 'Dinner', 'Coffee', 'Snacks'],
      'Travel': ['Uber ride', 'Bus ticket', 'Flight booking', 'Train pass'],
      'Bills': ['Electricity Bill', 'Internet', 'Water Bill', 'Phone plan'],
      'Shopping': ['Shoes', 'T-shirt', 'Jeans', 'Electronics'],
      'Health': ['Pharmacy', 'Doctor appointment', 'Gym membership'],
      'Other': ['Movie ticket', 'Gift', 'Donation']
    };

    // Add 20 for this month, 20 for last month
    for (int i = 0; i < 40; i++) {
      final category = categories[random.nextInt(categories.length)];
      final categoryTitles = titles[category] ?? ['Misc'];
      final title = categoryTitles[random.nextInt(categoryTitles.length)];
      final amount = (random.nextDouble() * 15000 + 500).roundToDouble(); // Rs. 500 to Rs. 15500
      
      DateTime date;
      final now = DateTime.now();
      
      if (i < 20) {
        // Current month
        final start = DateTime(now.year, now.month, 1);
        final daysDiff = now.difference(start).inDays;
        final randomDays = daysDiff > 0 ? random.nextInt(daysDiff + 1) : 0;
        date = now.subtract(Duration(days: randomDays));
      } else {
        // Last month
        final previousMonthStart = DateTime(now.year, now.month - 1, 1);
        final previousMonthEnd = DateTime(now.year, now.month, 0); // Last day of previous month
        final daysDiff = previousMonthEnd.difference(previousMonthStart).inDays;
        final randomDays = random.nextInt(daysDiff + 1);
        date = previousMonthStart.add(Duration(days: randomDays));
      }

      await expensesRef.add({
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': 'Sample data generated automatically',
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old data cleared and 40 new Rs. sample expenses added!')),
      );
    }
  }

  void _openExpenseForm({String? expenseId, Map<String, dynamic>? existingData}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75, // Pop-up fills 75% height
            child: AddEditExpenseScreen(
              expenseId: expenseId,
              existingData: existingData,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CyphLab Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_circle_outlined),
            tooltip: 'Reset & Add Sample Data',
            onPressed: _resetAndAddSampleData,
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                  _triggerFakeLoading(1500); // 1.5 seconds delay for theme toggle
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SummaryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _triggerFakeLoading();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonthFilter,
                    items: ['This Month', 'Last Month', 'All Time'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectedMonthFilter = val;
                        _triggerFakeLoading();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ...['All', ...kCategories].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: _selectedCategoryFilter == category
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      selected: _selectedCategoryFilter == category,
                      onSelected: (selected) {
                        if (selected) {
                          _selectedCategoryFilter = category;
                          _triggerFakeLoading();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Data Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No expenses yet.'));
                }

                final docs = snapshot.data!.docs;
                final now = DateTime.now();
                final currentMonthStart = DateTime(now.year, now.month, 1);
                final previousMonthStart = DateTime(now.year, now.month - 1, 1);
                
                double rawCurrentMonthTotal = 0.0;
                double rawLastMonthTotal = 0.0;
                
                // First calculate overall stats before filtering
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0.0).toDouble();
                  final dateStr = data['date'];
                  final date = dateStr != null ? DateTime.parse(dateStr) : now;
                  
                  if (!date.isBefore(currentMonthStart)) {
                    rawCurrentMonthTotal += amount;
                  } else if (!date.isBefore(previousMonthStart) && date.isBefore(currentMonthStart)) {
                    rawLastMonthTotal += amount;
                  }
                }

                // Apply Filters
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] ?? 'Other';
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final dateStr = data['date'];
                  final date = dateStr != null ? DateTime.parse(dateStr) : now;

                  // Month filter
                  bool monthMatch = true;
                  if (_selectedMonthFilter == 'This Month') {
                    monthMatch = !date.isBefore(currentMonthStart);
                  } else if (_selectedMonthFilter == 'Last Month') {
                    monthMatch = !date.isBefore(previousMonthStart) && date.isBefore(currentMonthStart);
                  }

                  // Category filter
                  bool categoryMatch = true;
                  if (_selectedCategoryFilter != 'All') {
                    categoryMatch = category == _selectedCategoryFilter;
                  }

                  // Search filter
                  bool searchMatch = true;
                  if (_searchQuery.isNotEmpty) {
                    searchMatch = title.contains(_searchQuery.toLowerCase());
                  }

                  return monthMatch && categoryMatch && searchMatch;
                }).toList();

                double filteredTotal = 0.0;
                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  filteredTotal += (data['amount'] ?? 0.0).toDouble();
                }

                // Prepare comparison text if standard view
                bool isStandardView = _selectedMonthFilter == 'This Month' && 
                                      _selectedCategoryFilter == 'All' && 
                                      _searchQuery.isEmpty;

                String comparisonText = "";
                Color comparisonColor = Colors.grey;
                IconData comparisonIcon = Icons.info_outline;

                if (isStandardView && rawLastMonthTotal > 0) {
                  if (rawCurrentMonthTotal > rawLastMonthTotal) {
                    final diff = rawCurrentMonthTotal - rawLastMonthTotal;
                    comparisonText = "You spent Rs. ${currency.format(diff)} more than last month";
                    comparisonColor = Colors.redAccent;
                    comparisonIcon = Icons.trending_up;
                  } else if (rawCurrentMonthTotal < rawLastMonthTotal) {
                    final diff = rawLastMonthTotal - rawCurrentMonthTotal;
                    comparisonText = "You spent Rs. ${currency.format(diff)} less than last month";
                    comparisonColor = Colors.green;
                    comparisonIcon = Icons.trending_down;
                  } else {
                    comparisonText = "Same spending as last month";
                    comparisonColor = Colors.grey;
                    comparisonIcon = Icons.trending_flat;
                  }
                }

                String cardTitle = 'Total Expenses';
                if (_selectedMonthFilter == 'This Month') cardTitle = 'This Month\'s Expenses';
                if (_selectedMonthFilter == 'Last Month') cardTitle = 'Last Month\'s Expenses';
                if (_selectedCategoryFilter != 'All') cardTitle += ' ($_selectedCategoryFilter)';

                return Column(
                  children: [
                    // Total Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                cardTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${currency.format(filteredTotal)}',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              if (isStandardView && (rawLastMonthTotal > 0 || rawCurrentMonthTotal > 0)) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(comparisonIcon, color: comparisonColor, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      comparisonText,
                                      style: TextStyle(
                                        color: comparisonColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : (filteredDocs.isEmpty 
                          ? const Center(child: Text('No matching expenses found.'))
                          : ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final category = data['category'] ?? 'Other';
                              final info = categoryInfoFor(category);
                              final amount = (data['amount'] ?? 0.0).toDouble();
                              final dateStr = data['date'];
                              final date = dateStr != null
                                  ? DateTime.parse(dateStr)
                                  : DateTime.now();

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: info.color.withOpacity(0.15),
                                    child: Icon(info.icon, color: info.color),
                                  ),
                                  title: Text(data['title'] ?? 'Expense'),
                                  subtitle: Text(DateFormat.yMMMd().format(date)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Rs. ${currency.format(amount)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _openExpenseForm(
                                          expenseId: doc.id,
                                          existingData: data,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('expenses')
                                              .doc(doc.id)
                                              .delete();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openExpenseForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
