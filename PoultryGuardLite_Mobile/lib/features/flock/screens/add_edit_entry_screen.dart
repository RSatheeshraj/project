import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/farm_model.dart';
import '../providers/entry_provider.dart';

class AddEditEntryScreen extends ConsumerStatefulWidget {
  const AddEditEntryScreen({
    super.key,
    required this.farm,
    required this.batch,
    this.entry,
    this.selectedDate,
    this.weekNumber,
  });

  final FarmModel farm;
  final BatchModel batch;
  final EntryModel? entry;
  final DateTime? selectedDate;
  final int? weekNumber;

  @override
  ConsumerState<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends ConsumerState<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _feedCtrl;
  late final TextEditingController _waterCtrl;
  late final TextEditingController _mortalityCtrl;
  late final TextEditingController _avgWeightCtrl;
  late final TextEditingController _temperatureCtrl;
  late final TextEditingController _humidityCtrl;
  late final TextEditingController _vaccinationCtrl;
  late final TextEditingController _medicineCtrl;
  late final TextEditingController _notesCtrl;
  
  // Financial
  late final TextEditingController _feedCostCtrl;
  late final TextEditingController _medicineCostCtrl;
  late final TextEditingController _labourCostCtrl;
  late final TextEditingController _otherExpenseCtrl;

  DateTime? _entryDate;
  DateTime? _vaccinationDate;
  DateTime? _nextVaccinationDate;

  @override
  void initState() {
    super.initState();
    _feedCtrl = TextEditingController(text: widget.entry?.feedConsumedKg.toString());
    _waterCtrl = TextEditingController(text: widget.entry?.waterConsumedLitres.toString());
    _mortalityCtrl = TextEditingController(text: widget.entry?.mortalityCount.toString());
    _avgWeightCtrl = TextEditingController(text: widget.entry?.averageWeightKg.toString());
    _temperatureCtrl = TextEditingController(text: widget.entry?.temperature.toString());
    _humidityCtrl = TextEditingController(text: widget.entry?.humidity.toString());
    _vaccinationCtrl = TextEditingController(text: widget.entry?.vaccination);
    _medicineCtrl = TextEditingController(text: widget.entry?.medicine);
    _notesCtrl = TextEditingController(text: widget.entry?.notes);

    _feedCostCtrl = TextEditingController(text: widget.entry?.feedCost.toString() ?? '0.0');
    _medicineCostCtrl = TextEditingController(text: widget.entry?.medicineCost.toString() ?? '0.0');
    _labourCostCtrl = TextEditingController(text: widget.entry?.labourCost.toString() ?? '0.0');
    _otherExpenseCtrl = TextEditingController(text: widget.entry?.otherExpense.toString() ?? '0.0');

    // Default entry date to passed date, or today for new entries.
    _entryDate = widget.entry?.entryDate ?? widget.selectedDate ?? DateTime.now();
    _vaccinationDate = widget.entry?.vaccinationDate;
    _nextVaccinationDate = widget.entry?.nextVaccinationDate;
  }

  @override
  void dispose() {
    _feedCtrl.dispose();
    _waterCtrl.dispose();
    _mortalityCtrl.dispose();
    _avgWeightCtrl.dispose();
    _temperatureCtrl.dispose();
    _humidityCtrl.dispose();
    _vaccinationCtrl.dispose();
    _medicineCtrl.dispose();
    _notesCtrl.dispose();
    
    _feedCostCtrl.dispose();
    _medicineCostCtrl.dispose();
    _labourCostCtrl.dispose();
    _otherExpenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isEntry, bool isNext = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEntry ? (_entryDate ?? DateTime.now()) : (isNext ? (_nextVaccinationDate ?? DateTime.now().add(const Duration(days: 7))) : (_vaccinationDate ?? DateTime.now())),
      firstDate: DateTime(2000),
      lastDate: isNext ? DateTime(2100) : (isEntry ? DateTime.now() : DateTime.now().add(const Duration(days: 365))),
    );
    if (picked != null) {
      setState(() {
        if (isEntry) {
          _entryDate = picked;
        } else if (isNext) {
          _nextVaccinationDate = picked;
        } else {
          _vaccinationDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_entryDate == null) {
      UiHelpers.showErrorDialog(context, 'Please select an entry date.');
      return;
    }

    final isEditing = widget.entry != null;

    int computedWeekNumber = widget.entry?.weekNumber ?? widget.weekNumber ?? 0;
    if (computedWeekNumber == 0 && widget.batch.arrivalDate != null && _entryDate != null) {
      final arrival = DateTime(widget.batch.arrivalDate!.year, widget.batch.arrivalDate!.month, widget.batch.arrivalDate!.day);
      final entryDay = DateTime(_entryDate!.year, _entryDate!.month, _entryDate!.day);
      final daysDiff = entryDay.difference(arrival).inDays;
      if (daysDiff >= 0) {
        computedWeekNumber = (daysDiff ~/ 7) + 1;
      } else {
        computedWeekNumber = 1;
      }
    }

    final entryData = EntryModel(
      id: widget.entry?.id ?? '',
      batchId: widget.batch.id,
      farmId: widget.farm.id,
      ownerId: widget.entry?.ownerId ?? '',
      entryDate: _entryDate,
      weekNumber: computedWeekNumber,
      feedConsumedKg: double.tryParse(_feedCtrl.text.trim()) ?? 0.0,
      waterConsumedLitres: double.tryParse(_waterCtrl.text.trim()) ?? 0.0,
      mortalityCount: int.tryParse(_mortalityCtrl.text.trim()) ?? 0,
      averageWeightKg: double.tryParse(_avgWeightCtrl.text.trim()) ?? 0.0,
      temperature: double.tryParse(_temperatureCtrl.text.trim()) ?? 0.0,
      humidity: double.tryParse(_humidityCtrl.text.trim()) ?? 0.0,
      vaccination: _vaccinationCtrl.text.trim(),
      medicine: _medicineCtrl.text.trim(),
      vaccinationDate: _vaccinationDate,
      nextVaccinationDate: _nextVaccinationDate,
      feedCost: double.tryParse(_feedCostCtrl.text.trim()) ?? 0.0,
      medicineCost: double.tryParse(_medicineCostCtrl.text.trim()) ?? 0.0,
      labourCost: double.tryParse(_labourCostCtrl.text.trim()) ?? 0.0,
      otherExpense: double.tryParse(_otherExpenseCtrl.text.trim()) ?? 0.0,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.entry?.createdAt,
    );

    // 1. Show loading dialog
    UiHelpers.showLoadingDialog(
      context,
      isEditing ? 'Updating Entry...' : 'Saving Entry...',
      isEditing ? 'Please wait...' : 'Please wait while we save your entry.',
    );

    // 2. Perform action
    if (isEditing) {
      await ref.read(entryControllerProvider.notifier).updateEntry(entryData);
    } else {
      await ref.read(entryControllerProvider.notifier).addEntry(entryData);
    }

    if (!mounted) return;

    // 3. Close loading dialog
    context.pop();

    // 4. Handle result
    final error = ref.read(entryControllerProvider).error;
    if (error != null) {
      UiHelpers.showErrorDialog(context, error.toString());
    } else {
      await UiHelpers.showSuccessDialog(
        context,
        isEditing ? 'Entry Updated Successfully' : 'Entry Saved Successfully',
        isEditing ? '' : 'Your weekly entry has been added successfully.',
      );
      if (mounted) context.pop(); // Return to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    final state = ref.watch(entryControllerProvider);
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'Add Weekly Entry'),
      ),
      body: SafeArea(
        child: IgnorePointer(
          ignoring: state.isLoading,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // ── Entry Date ────────────────────────────────────────────────
                InkWell(
                  onTap: () => _selectDate(context, isEntry: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Entry Date',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(
                      _entryDate != null
                          ? df.format(_entryDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Health & Consumption', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // ── Feed & Water ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feedCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Feed Consumed (kg)',
                          prefixIcon: Icon(Icons.restaurant_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          if (double.parse(val) < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _waterCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Water Consumed (L)',
                          prefixIcon: Icon(Icons.water_drop_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          if (double.parse(val) < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Mortality & Avg Weight ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mortalityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mortality Count',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (int.tryParse(val) == null) {
                            return 'Whole number only';
                          }
                          if (int.parse(val) < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _avgWeightCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Avg Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          if (double.parse(val) <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Temperature & Humidity ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _temperatureCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Temperature (°C)',
                          prefixIcon: Icon(Icons.thermostat_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _humidityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Humidity (%)',
                          prefixIcon: Icon(Icons.water_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final v = double.tryParse(val);
                          if (v == null) return 'Invalid number';
                          if (v < 0 || v > 100) return '0–100%';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Interventions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // ── Vaccination ───────────────────────────────────────────────
                TextFormField(
                  controller: _vaccinationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vaccination',
                    prefixIcon: Icon(Icons.vaccines_rounded),
                    hintText: 'e.g. Newcastle Disease vaccine',
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isEntry: false, isNext: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Vaccinated On',
                            prefixIcon: Icon(Icons.event_available),
                          ),
                          child: Text(_vaccinationDate != null ? df.format(_vaccinationDate!) : 'None'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isEntry: false, isNext: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Next Due',
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(_nextVaccinationDate != null ? df.format(_nextVaccinationDate!) : 'None'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Medicine ──────────────────────────────────────────────────
                TextFormField(
                  controller: _medicineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine',
                    prefixIcon: Icon(Icons.medication_rounded),
                    hintText: 'e.g. Antibiotics',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Financial Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // ── Financial ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feedCostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Feed Cost',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _medicineCostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Cost',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _labourCostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Labour Cost',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _otherExpenseCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Other Expenses',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // ── Notes ─────────────────────────────────────────────────────
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEditing ? 'Update Entry' : 'Save Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
