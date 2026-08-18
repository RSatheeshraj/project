import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/farm_model.dart';
import '../providers/batch_provider.dart';
import '../providers/bird_stats_provider.dart';

class AddEditBatchScreen extends ConsumerStatefulWidget {
  const AddEditBatchScreen({super.key, required this.farm, this.batch});

  final FarmModel farm;
  final BatchModel? batch;

  @override
  ConsumerState<AddEditBatchScreen> createState() => _AddEditBatchScreenState();
}

class _AddEditBatchScreenState extends ConsumerState<AddEditBatchScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _totalBirdsCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _notesCtrl;

  String _birdType = 'Broiler';
  String _status = 'Active';
  DateTime? _arrivalDate;
  DateTime? _marketDate;

  final List<String> _birdTypes = ['Broiler', 'Layer', 'Country Chicken'];
  final List<String> _statuses = ['Active', 'Completed', 'Archived'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.batch?.batchName);
    _breedCtrl = TextEditingController(text: widget.batch?.breed);
    _totalBirdsCtrl = TextEditingController(
      text: widget.batch?.totalBirds.toString(),
    );
    _supplierCtrl = TextEditingController(text: widget.batch?.supplier);
    _notesCtrl = TextEditingController(text: widget.batch?.notes);

    if (widget.batch != null) {
      _birdType = _birdTypes.contains(widget.batch!.birdType)
          ? widget.batch!.birdType
          : 'Broiler';
      _status = _statuses.contains(widget.batch!.status)
          ? widget.batch!.status
          : 'Active';
      _arrivalDate = widget.batch!.arrivalDate;
      _marketDate = widget.batch!.expectedMarketDate;
    } else {
      _arrivalDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _totalBirdsCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isArrival) async {
    final initialDate = isArrival
        ? (_arrivalDate ?? DateTime.now())
        : (_marketDate ?? DateTime.now().add(const Duration(days: 40)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isArrival) {
          _arrivalDate = picked;
        } else {
          _marketDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_arrivalDate == null) {
      UiHelpers.showErrorDialog(context, 'Please select an arrival date.');
      return;
    }

    final isEditing = widget.batch != null;
    final totalBirds = int.tryParse(_totalBirdsCtrl.text.trim()) ?? 0;

    // Validate if editing
    if (isEditing) {
      final params = (farmId: widget.farm.id, batchId: widget.batch!.id);
      final stats = ref.read(batchStatsProvider(params));
      
      final usedBirds = stats.totalSold + stats.totalMortality;
      if (totalBirds < usedBirds) {
        UiHelpers.showErrorDialog(context, 'Initial birds cannot be less than birds already sold/dead ($usedBirds).');
        return;
      }
    }

    // If we're creating, currentBirds starts equal to totalBirds.
    // If editing, we preserve the currentBirds unless it's null.
    final currentBirds = isEditing ? widget.batch!.currentBirds : totalBirds;

    final batchData = BatchModel(
      id: widget.batch?.id ?? '',
      farmId: widget.farm.id,
      ownerId: widget.batch?.ownerId ?? '',
      batchName: _nameCtrl.text.trim(),
      birdType: _birdType,
      breed: _breedCtrl.text.trim(),
      totalBirds: totalBirds,
      currentBirds: currentBirds,
      supplier: _supplierCtrl.text.trim(),
      arrivalDate: _arrivalDate,
      expectedMarketDate: _marketDate,
      status: _status,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.batch?.createdAt,
    );

    UiHelpers.showLoadingDialog(
      context,
      isEditing ? 'Updating Batch...' : 'Saving Batch...',
      isEditing ? 'Please wait...' : 'Please wait while we save your batch.',
    );

    if (isEditing) {
      await ref.read(batchControllerProvider.notifier).updateBatch(batchData);
    } else {
      await ref.read(batchControllerProvider.notifier).addBatch(batchData);
    }

    if (!mounted) return;
    context.pop(); // close loading

    final error = ref.read(batchControllerProvider).error;
    if (error != null) {
      UiHelpers.showErrorDialog(context, error.toString());
    } else {
      await UiHelpers.showSuccessDialog(
        context,
        isEditing ? 'Batch Updated Successfully' : 'Batch Saved Successfully',
        isEditing ? '' : 'Your batch has been added successfully.',
      );
      if (mounted) context.pop(); // Return
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.batch != null;
    final state = ref.watch(batchControllerProvider);
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Batch' : 'Add Batch')),
      body: SafeArea(
        child: IgnorePointer(
          ignoring: state.isLoading,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _birdType,
                        decoration: const InputDecoration(
                          labelText: 'Bird Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _birdTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _birdType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: _statuses
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _totalBirdsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial Bird Count',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _supplierCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Arrival Date',
                            prefixIcon: Icon(Icons.flight_land),
                          ),
                          child: Text(
                            _arrivalDate != null
                                ? df.format(_arrivalDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Market Date',
                            prefixIcon: Icon(Icons.shopping_cart),
                          ),
                          child: Text(
                            _marketDate != null
                                ? df.format(_marketDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(isEditing ? 'Update Batch' : 'Save Batch'),
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
