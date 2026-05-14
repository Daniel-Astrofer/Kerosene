import '../entities/mining_dashboard_snapshot.dart';

abstract class MiningDashboardRepository {
  MiningDashboardSnapshot? get cachedSnapshot;

  Future<MiningDashboardSnapshot> fetchSnapshot();
}
