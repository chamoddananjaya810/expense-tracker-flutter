import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/category_helper.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final String? expenseId;
  final Map<String, dynamic>? existingData;

  const AddEditExpenseScreen({super.key, this.expenseId, this.existingData});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingData?['title'] ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingData?['amount']?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.existingData?['note'] ?? '',
    );

    if (widget.existingData != null) {
      _selectedCategory = widget.existingData!['category'] ?? 'Food';
      _selectedDate = DateTime.parse(widget.existingData!['date']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final expenseData = {
      'title': _titleController.text.trim(),
      'amount': double.parse(_amountController.text.trim()),
      'category': _selectedCategory,
      'date': _selectedDate.toIso8601String(),
      'note': _noteController.text.trim(),
    };

    try {
      if (widget.expenseId == null) {
        await FirebaseFirestore.instance
            .collection('expenses')
            .add(expenseData);
      } else {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.expenseId)
            .update(expenseData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Expense saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseId != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add New Expense'),
      ),
      body: SafeArea(
        // Lock the form while a save/update is in flight so a second tap
        // can't fire a duplicate write while it's processing.
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Please enter a title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Please enter an amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Please enter a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: kCategories.map((cat) {
                    final info = categoryInfoFor(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(info.icon, size: 18, color: info.color),
                          const SizedBox(width: 10),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 16),

                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        ),
                        Icon(
                          Icons.edit_calendar_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Optional Note / Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isSaving
                        ? Row(
                            key: const ValueKey('saving'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(isEditing ? 'Updating...' : 'Saving...'),
                            ],
                          )
                        : Text(
                            key: const ValueKey('idle'),
                            isEditing ? 'Update Expense' : 'Save Expense',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
