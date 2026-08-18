class VaccinationAnalytics {
  final int completed;
  final int dueToday;
  final int dueThisWeek;
  final int overdue;
  final int upcoming;
  final double compliancePercentage;

  const VaccinationAnalytics({
    this.completed = 0,
    this.dueToday = 0,
    this.dueThisWeek = 0,
    this.overdue = 0,
    this.upcoming = 0,
    this.compliancePercentage = 100.0,
  });
}
