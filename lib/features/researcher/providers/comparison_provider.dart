import 'chart_point.dart';

class ComparedLocation {
  const ComparedLocation(
      this.name, this.colorValue, this.points, this.y2024, this.y2025);
  final String name;
  final int colorValue;
  final List<ChartPoint> points;
  final int y2024;
  final int y2025;
}

/// A list makes it straightforward to add or remove comparison locations later.
const comparedLocations = <ComparedLocation>[
  ComparedLocation(
      'Ahmedabad',
      0xFF3B82F6,
      [
        ChartPoint(2021, 245),
        ChartPoint(2022, 302),
        ChartPoint(2023, 355),
        ChartPoint(2024, 412),
        ChartPoint(2025, 387)
      ],
      412,
      387),
  ComparedLocation(
      'Rajkot',
      0xFFF59E0B,
      [
        ChartPoint(2021, 188),
        ChartPoint(2022, 263),
        ChartPoint(2023, 289),
        ChartPoint(2024, 381),
        ChartPoint(2025, 326)
      ],
      381,
      326),
  ComparedLocation(
      'Surat',
      0xFF22C55E,
      [
        ChartPoint(2021, 376),
        ChartPoint(2022, 398),
        ChartPoint(2023, 459),
        ChartPoint(2024, 526),
        ChartPoint(2025, 498)
      ],
      526,
      498),
];
