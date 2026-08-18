import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DistributionPieChart extends StatelessWidget {
  const DistributionPieChart({
    super.key,
    required this.data,
    this.title,
  });

  final Map<String, int> data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: Theme.of(context).textTheme.bodySmall),
      );
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Colors.orange,
      Colors.teal,
    ];

    int total = data.values.fold(0, (sum, val) => sum + val);
    
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      final color = colors[index % colors.length];
      final percentage = (entry.value / total) * 100;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.asMap().entries.map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final color = colors[index % colors.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key} (${entry.value})',
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
