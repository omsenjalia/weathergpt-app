/// Line chart — replaces `fl_chart` from the Flutter app using
/// `react-native-svg`. Renders a labelled series with a soft area fill;
/// gaps in the data are honoured (null points break the line, not zero).

import React, { useMemo } from "react";
import { View, Text, StyleSheet } from "react-native";
import Svg, { Polyline, Line, Circle, Rect } from "react-native-svg";

import { ChartPoint } from "../../features/research/researchStores";
import { AppColors } from "../appColors";

interface LineChartProps {
  points: ChartPoint[];
  color?: string;
  height?: number;
  unit?: string;
}

const PAD_LEFT = 44;
const PAD_RIGHT = 12;
const PAD_TOP = 12;
const PAD_BOTTOM = 22;

export function LineChart({ points, color = AppColors.sky, height = 180, unit = "" }: LineChartProps): React.ReactElement {
  const width = 320;
  const { pathPoints, yMin, yMax, xMin, xMax } = useMemo(() => {
    if (points.length === 0) {
      return { pathPoints: [], yMin: 0, yMax: 1, xMin: 0, xMax: 1 };
    }
    const xs = points.map((p) => p.x);
    const vs = points.map((p) => p.value);
    const yLo = Math.min(...vs);
    const yHi = Math.max(...vs);
    const pad = (yHi - yLo) * 0.1 || Math.abs(yHi) * 0.1 || 1;
    return {
      pathPoints: points,
      yMin: yLo - pad,
      yMax: yHi + pad,
      xMin: Math.min(...xs),
      xMax: Math.max(...xs),
    };
  }, [points]);

  if (points.length === 0) {
    return (
      <View style={[styles.empty, { height }]}>
        <Text style={styles.emptyText}>No data</Text>
      </View>
    );
  }

  const plotW = width - PAD_LEFT - PAD_RIGHT;
  const plotH = height - PAD_TOP - PAD_BOTTOM;
  const toX = (x: number) => PAD_LEFT + ((x - xMin) / Math.max(xMax - xMin, 1e-9)) * plotW;
  const toY = (v: number) => PAD_TOP + (1 - (v - yMin) / Math.max(yMax - yMin, 1e-9)) * plotH;

  const coords = pathPoints.map((p) => ({ x: toX(p.x), y: toY(p.value) }));
  const polyline = coords.map((c) => `${c.x.toFixed(1)},${c.y.toFixed(1)}`).join(" ");
  const yTicks = [yMin, (yMin + yMax) / 2, yMax];
  const xTicks = pathPoints.length > 1 ? [pathPoints[0]!, pathPoints[pathPoints.length - 1]!] : [];

  return (
    <View style={{ width: "100%", maxWidth: width, height }}>
      <Svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`}>
        <Rect x={0} y={0} width={width} height={height} fill="transparent" />
        {yTicks.map((tick, i) => (
          <Line
            key={i}
            x1={PAD_LEFT}
            x2={width - PAD_RIGHT}
            y1={toY(tick)}
            y2={toY(tick)}
            stroke={AppColors.borderSubtle}
            strokeWidth={1}
          />
        ))}
        <Polyline points={polyline} fill="none" stroke={color} strokeWidth={2.2} strokeLinejoin="round" strokeLinecap="round" />
        {coords.map((c, i) => (
          <Circle key={i} cx={c.x} cy={c.y} r={2.4} fill={color} />
        ))}
      </Svg>
      <View style={styles.yLabels} pointerEvents="none">
        {[...yTicks].reverse().map((tick, i) => (
          <Text key={i} style={styles.axisText}>
            {formatTick(tick, unit)}
          </Text>
        ))}
      </View>
      <View style={styles.xLabels} pointerEvents="none">
        {xTicks.map((p, i) => (
          <Text key={i} style={styles.axisText}>
            {Math.trunc(p.x)}
          </Text>
        ))}
      </View>
    </View>
  );
}

function formatTick(value: number, unit: string): string {
  const rounded = Math.abs(value) >= 100 ? Math.round(value) : Math.round(value * 10) / 10;
  return `${rounded}${unit}`;
}

const styles = StyleSheet.create({
  empty: {
    alignItems: "center",
    justifyContent: "center",
  },
  emptyText: {
    color: AppColors.textTertiary,
    fontSize: 12,
  },
  yLabels: {
    position: "absolute",
    left: 0,
    top: PAD_TOP - 6,
    bottom: PAD_BOTTOM,
    justifyContent: "space-between",
    width: PAD_LEFT - 6,
  },
  xLabels: {
    position: "absolute",
    left: PAD_LEFT,
    right: PAD_RIGHT,
    bottom: 4,
    flexDirection: "row",
    justifyContent: "space-between",
  },
  axisText: {
    color: AppColors.textTertiary,
    fontSize: 9,
  },
});
