import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/farm_model.dart';
import '../models/sales_model.dart';
import '../providers/sales_provider.dart';
import '../providers/bird_stats_provider.dart';

class AddEditSalesScreen extends ConsumerStatefulWidget {
  const AddEditSalesScreen({
    super.key,
    required this.farm,
    required this.batch,
    this.sale,
  });

  final FarmModel farm;
  final BatchModel batch;
  final SalesModel? sale;

  @override
  ConsumerState<AddEditSalesScreen> createState() => _AddEditSalesScreenState();
}

class _AddEditSalesScreenState extends ConsumerState<AddEditSalesScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  final _birdsSoldController = TextEditingController();
  final _totalWeightController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _notesController = TextEditingController();
  late TextEditingController _dateController;

  double _avgWeight = 0.0;
  double _totalRevenue = 0.0;

  void _calculateTotals() {
    final birds = int.tryParse(_birdsSoldController.text.trim()) ?? 0;
    final totalWeight = double.tryParse(_totalWeightController.text.trim()) ?? 0.0;
    final price = double.tryParse(_pricePerKgController.text.trim()) ?? 0.0;

    setState(() {
      _avgWeight = birds > 0 ? totalWeight / birds : 0.0;
      _totalRevenue = totalWeight * price;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.sale?.date ?? DateTime.now();
    // Use a persistent controller so the date field never resets on rebuild
    _dateController = TextEditingController(
      text: DateFormat.yMMMd().format(_selectedDate),
    );

    _birdsSoldController.addListener(_calculateTotals);
    _totalWeightController.addListener(_calculateTotals);
    _pricePerKgController.addListener(_calculateTotals);

    if (widget.sale != null) {
      _birdsSoldController.text = widget.sale!.birdsSold.toString();
      _totalWeightController.text = widget.sale!.totalWeight.toString();
      _pricePerKgController.text = widget.sale!.pricePerKg.toString();
      _invoiceNumberController.text = widget.sale!.invoiceNumber;
      _buyerNameController.text = widget.sale!.buyerName;
      _notesController.text = widget.sale!.notes;
      _calculateTotals();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _birdsSoldController.dispose();
    _totalWeightController.dispose();
    _pricePerKgController.dispose();
    _invoiceNumberController.dispose();
    _buyerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        // Update the persistent controller text so the field reflects new date
        _dateController.text = DateFormat.yMMMd().format(date);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final birdsSold = int.tryParse(_birdsSoldController.text.trim()) ?? 0;

    // Validation check for overselling — only applies to ACTIVE batches
    // Completed batch sales are historical records and should not be blocked
    if (widget.batch.status.toLowerCase() == 'active') {
      final params = (farmId: widget.farm.id, batchId: widget.batch.id);
      final stats = ref.read(batchStatsProvider(params));
      
      final oldSaleBirds = widget.sale?.birdsSold ?? 0;
      final maxAvailable = stats.remainingBirds + oldSaleBirds;
      
      if (birdsSold > maxAvailable) {
        UiHelpers.showErrorDialog(
          context,
          'Cannot sell $birdsSold birds. Only $maxAvailable birds remaining in this batch.',
        );
        return;
      }
    }

    UiHelpers.showLoadingDialog(context, 'Saving Sale...', 'Please wait');

    final totalWeight = double.tryParse(_totalWeightController.text.trim()) ?? 0.0;
    final pricePerKg = double.tryParse(_pricePerKgController.text.trim()) ?? 0.0;
    
    final sale = SalesModel(
      id: widget.sale?.id ?? '',
      date: _selectedDate,
      birdsSold: birdsSold,
      averageWeight: _avgWeight,
      pricePerKg: pricePerKg,
      totalWeight: totalWeight,
      totalRevenue: totalWeight * pricePerKg,
      invoiceNumber: _invoiceNumberController.text.trim(),
      buyerName: _buyerNameController.text.trim(),
      notes: _notesController.text.trim(),
    );

    await ref.read(salesControllerProvider.notifier).addOrUpdateSale(
          farmId: widget.farm.id,
          batchId: widget.batch.id,
          sale: sale,
        );

    if (!mounted) return;
    context.pop(); // Close loading

    final error = ref.read(salesControllerProvider).error;
    if (error != null) {
      UiHelpers.showErrorDialog(context, error.toString());
    } else {
      await UiHelpers.showSuccessDialog(
          context, 'Success', 'Sale saved successfully.');
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sale == null ? 'Record Sale' : 'Edit Sale'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              readOnly: true,
              onTap: _pickDate,
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date of Sale',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birdsSoldController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Number of Birds Sold',
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricePerKgController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per Kg (₹)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Average Weight:'),
                      Text('${_avgWeight.toStringAsFixed(2)} kg/bird', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Revenue:'),
                      Text('₹${_totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'Invoice Number (Optional)',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: 'Buyer Name (Optional)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Save Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
