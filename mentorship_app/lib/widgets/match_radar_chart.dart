import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class MatchRadarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const MatchRadarChart({super.key, required this.values, required this.labels})
    : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13)), // 0.05 opacity
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient circles to simulate radar waves
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5B13EC).withAlpha(25), // 0.1 opacity
                width: 1,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5B13EC).withAlpha(51), // 0.2 opacity
                width: 1,
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5B13EC).withAlpha(25), // 0.1 opacity
            ),
          ),
          RadarChart(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutBack,
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 5,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              gridBorderData: const BorderSide(color: Colors.transparent),
              radarBorderData: BorderSide(
                color: const Color(0xFF8B5CF6).withAlpha(77), // 0.3 opacity
                width: 1,
              ),
              getTitle: (index, angle) {
                return RadarChartTitle(
                  text: labels[index],
                  angle: angle,
                  positionPercentageOffset: 0.2,
                );
              },
              titleTextStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              dataSets: [
                RadarDataSet(
                  fillColor: const Color(
                    0xFF5B13EC,
                  ).withAlpha(64), // 0.25 opacity
                  borderColor: const Color(0xFF6C63FF),
                  entryRadius: 4,
                  dataEntries: values
                      .map((value) => RadarEntry(value: value))
                      .toList(),
                  borderWidth: 2,
                ),
              ],
            ),
          ),
          // Center Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF5B13EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
