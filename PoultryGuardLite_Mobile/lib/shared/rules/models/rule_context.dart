import '../../../features/flock/models/batch_model.dart';
import '../../../features/flock/models/farm_model.dart';
import '../../../features/flock/models/entry_model.dart';
import '../../../features/flock/models/sales_model.dart';
// Note: We'll add VaccinationModel and InventoryModel later in Phase 5.
// For now, we use dynamic lists or leave them out of the Phase 1 schema
// but provide empty lists to keep the structure intact.

class RuleContext {
  final FarmModel farm;
  final BatchModel batch;
  final List<EntryModel> entries;
  final List<SalesModel> sales;
  final List<dynamic> vaccinations;
  final List<dynamic> inventory;

  const RuleContext({
    required this.farm,
    required this.batch,
    this.entries = const [],
    this.sales = const [],
    this.vaccinations = const [],
    this.inventory = const [],
  });
}
