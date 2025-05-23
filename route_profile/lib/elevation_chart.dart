// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';
import 'dart:math';

import 'package:route_profile/utility.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';

class LineAreaChartController {
  void Function(double)? setCurrentHighlight;
  void Function(double, double)? changeViewport;
}

class LineAreaChart extends StatefulWidget {
  final void Function(double leftX, double rightX)? onViewPortChanged;
  final void Function(double x)? onSelect;
  final LineAreaChartController controller;

  late final double maxY;
  late final double minY;
  late final double maxX;
  late final double minX;

  static const double leftLabelBarWidth = 40;
  static const double bottomLabelBarHeight = 20;
  static const double tooptipWidth = 60;

  late final List<FlSpot> spots;
  final List<(List<FlSpot>, Color)> highlightedIntervals = [];
  final List<(double, double, Color)> highlightedColoredIntervals = [];
  final List<ClimbSection> climbSections;

  final Color legendLabelColor;
  final Color? indicatorColor;
  final bool isInteractive;

  LineAreaChart({
    super.key,
    required this.controller,
    required List<(double, double)> points,
    required this.climbSections,
    this.onSelect,
    this.onViewPortChanged,
    this.legendLabelColor = Colors.black,
    this.indicatorColor,
    this.isInteractive = true,
  }) {
    spots = points.map((e) => FlSpot(e.$1, e.$2)).toList();

    if (spots.isEmpty) {
      maxY = 0;
      minY = 0;
      maxX = 0;
      minX = 0;
    } else {
      maxY = spots.map((e) => e.y).reduce(max) + 50;
      minY = spots.map((e) => e.y).reduce(min) - 50;

      maxX = spots.map((e) => e.x).reduce(max);
      minX = spots.map((e) => e.x).reduce(min);
    }

    for (var climbSection in climbSections) {
      final Color highligthedColor = getGradeColor(climbSection).withAlpha(255);
      highlightedColoredIntervals.add((
        climbSection.startDistanceM.toDouble(),
        climbSection.endDistanceM.toDouble(),
        highligthedColor,
      ));
    }

    for (final interval in highlightedColoredIntervals) {
      final intervalStart = interval.$1;
      final intervalEnd = interval.$2;
      final intervalColor = interval.$3;

      final affectedSpots = spots
          .where(
            (element) => element.x >= intervalStart && element.x <= intervalEnd,
          )
          .toList();
      highlightedIntervals.add((affectedSpots, intervalColor));
    }
  }

  void setCurrentHighlight(double value) {
    state._setCurrentHighlight(value);
  }

  // ignore: library_private_types_in_public_api
  late final _LineAreaChartState state;

  @override
  // ignore: no_logic_in_create_state
  State<LineAreaChart> createState() {
    state = _LineAreaChartState();
    return state;
  }
}

class _LineAreaChartState extends State<LineAreaChart> {
  late double _currentLeftX;
  late double _currentRightX;
  double get _currentSectionLength => _currentRightX - _currentLeftX;
  double get _currentMiddleX => (_currentLeftX + _currentRightX) * 0.5;

  FlSpot? _currentSpot;
  double? get _currentHighlightX => _currentSpot?.x;
  double? get _currentHighlightY => _currentSpot?.y;

  int _timestampLastTwoFingersGesture = 0;

  int _timestampLastScaleGesture = 0;
  double _scaleOriginXMovingAverage = 0;

  Timer? _timerUntilOnViewportUpdate;

  _ViewportController viewportController = _ViewportController();
  _TooltipController tooltipController = _TooltipController();
  _TitleBarController titleBarController = _TitleBarController();

  @override
  void initState() {
    super.initState();

    resetMarginsAndHighlight();
  }

  @override
  void didUpdateWidget(covariant LineAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    resetMarginsAndHighlight();
  }

  void resetMarginsAndHighlight() {
    _currentLeftX = widget.minX;
    _currentRightX = widget.maxX;

    widget.controller.setCurrentHighlight = _setCurrentHighlight;
    widget.controller.changeViewport = _updatePresentedDomainLimits;

    viewportController.changeViewport(_currentLeftX, _currentRightX);
    titleBarController.horizontalAxisViewportChanged(
      _currentLeftX,
      _currentRightX,
    );
    titleBarController.verticalAxisViewportChanged(widget.minY, widget.maxY);
  }

  void _setCurrentHighlight(double value) {
    if ((value - (_currentHighlightX ?? double.infinity)).abs() <
            _currentSectionLength * 0.03 &&
        widget.isInteractive) {
      return;
    }
    if (!mounted) return;

    FlSpot closestSpot = widget.spots.first;
    for (final spot in widget.spots) {
      if ((closestSpot.x - value).abs() > (spot.x - value).abs()) {
        closestSpot = spot;
      }
    }

    if (_currentSpot != null && _currentSpot!.x == closestSpot.x) return;

    _currentSpot = closestSpot;
    tooltipController.setHighlight(_currentSpot);

    widget.onSelect?.call(closestSpot.x);
  }

  void _updatePresentedDomainLimits(double newMinX, double newMaxX) {
    _currentLeftX = newMinX;
    _currentRightX = newMaxX;

    viewportController.changeViewport(_currentLeftX, _currentRightX);
    titleBarController.horizontalAxisViewportChanged(
      _currentLeftX,
      _currentRightX,
    );
    tooltipController.triggerRebuild();

    if (widget.onViewPortChanged == null) return;

    _timerUntilOnViewportUpdate?.cancel();
    _timerUntilOnViewportUpdate = Timer(const Duration(milliseconds: 200), () {
      widget.onViewPortChanged!(_currentLeftX, _currentRightX);
    });
  }

  void _moveMiddleTowardsX(double x) {
    final leftXWhenXInMiddle = x - _currentSectionLength * 0.5;
    final rightXWhenXInMiddle = x + _currentSectionLength * 0.5;

    const lerpCoefficient = 0.01;

    final newLeftXInterpolated = _currentLeftX * (1 - lerpCoefficient) +
        leftXWhenXInMiddle * lerpCoefficient;
    final newRightXInterpolated = _currentRightX * (1 - lerpCoefficient) +
        rightXWhenXInMiddle * lerpCoefficient;

    _updatePresentedDomainLimits(newLeftXInterpolated, newRightXInterpolated);
  }

  double _getXAtWidthPercentage(double widthPercentage) {
    return _currentSectionLength * widthPercentage + _currentLeftX;
  }

  double _getTooltipXOffset(double widgetWidth) {
    return (_currentHighlightX! - _currentLeftX) /
            (_currentRightX - _currentLeftX) *
            widgetWidth -
        LineAreaChart.tooptipWidth / 2;
  }

  double _getTooltipYOffset(double widgetHeight) {
    return (_currentHighlightY! - widget.minY) /
        (widget.maxY - widget.minY) *
        widgetHeight;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      child: AspectRatio(
        aspectRatio: 2,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _LeftTitleBar(
                    originalMinY: widget.minY,
                    originalMaxY: widget.maxY,
                    intervalsCount: 3,
                    bottomOffset: 0,
                    barWidth: LineAreaChart.leftLabelBarWidth,
                    textColor: widget.legendLabelColor,
                    controller: titleBarController,
                  ),
                  Expanded(
                    child: _ChartGestureDetector(
                      hasGestures: widget.isInteractive,
                      onDragWithOneFinger: (percentageOfChartWidth) {
                        if (DateTime.now().millisecondsSinceEpoch -
                                _timestampLastTwoFingersGesture <
                            50) {
                          return;
                        }

                        final highlightedDistance = _getXAtWidthPercentage(
                          percentageOfChartWidth,
                        );
                        _setCurrentHighlight(highlightedDistance);

                        _timestampLastTwoFingersGesture =
                            DateTime.now().millisecondsSinceEpoch;
                      },
                      onDragWithTwoFingers: (deltaXOffset) {
                        deltaXOffset =
                            deltaXOffset * _currentSectionLength * 0.0050;

                        final newMinX = _currentLeftX + deltaXOffset;
                        final newMaxX = _currentRightX + deltaXOffset;

                        if (newMinX < widget.minX) {
                          return;
                        }
                        if (newMaxX > widget.maxX) {
                          return;
                        }

                        _updatePresentedDomainLimits(newMinX, newMaxX);

                        _timestampLastTwoFingersGesture =
                            DateTime.now().millisecondsSinceEpoch;
                      },
                      onScale: (percentageOfChartWidth, horizontalScale) {
                        // Move towards scale's point of origin
                        final startScaleXOrigin = _getXAtWidthPercentage(
                          percentageOfChartWidth,
                        );

                        if (DateTime.now().millisecondsSinceEpoch -
                                _timestampLastScaleGesture >
                            200) {
                          _scaleOriginXMovingAverage = startScaleXOrigin;
                        } else {
                          const newPositionWeight = 0.01;
                          _scaleOriginXMovingAverage =
                              newPositionWeight * startScaleXOrigin +
                                  (1 - newPositionWeight) *
                                      _scaleOriginXMovingAverage;
                        }
                        _moveMiddleTowardsX(_scaleOriginXMovingAverage);

                        // Scale
                        horizontalScale = 1 / horizontalScale;
                        const lerpCoefficient = 0.01;
                        horizontalScale = horizontalScale * lerpCoefficient +
                            (1 - lerpCoefficient);

                        final newLength =
                            _currentSectionLength * horizontalScale;
                        var newMinX = _currentMiddleX - newLength / 2;
                        var newMaxX = _currentMiddleX + newLength / 2;

                        if (newMinX < widget.minX) newMinX = widget.minX;
                        if (newMaxX > widget.maxX) newMaxX = widget.maxX;

                        double delta = newMaxX - newMinX;
                        if (delta < 10) return;

                        _updatePresentedDomainLimits(newMinX, newMaxX);

                        _timestampLastTwoFingersGesture =
                            DateTime.now().millisecondsSinceEpoch;
                        _timestampLastScaleGesture =
                            DateTime.now().millisecondsSinceEpoch;
                      },
                      child: AbsorbPointer(
                        child: LayoutBuilder(
                          builder: (context, widgetConstrains) {
                            return Stack(
                              clipBehavior: Clip.none,
                              fit: StackFit.expand,
                              children: [
                                _Chart(
                                  minY: widget.minY,
                                  maxY: widget.maxY,
                                  minX: widget.minX,
                                  maxX: widget.maxX,
                                  spots: widget.spots,
                                  highlightedIntervals:
                                      widget.highlightedIntervals,
                                  viewportController: viewportController,
                                ),
                                _ChartTooptip(
                                  xOffset: _getTooltipXOffset,
                                  yOffset: _getTooltipYOffset,
                                  indicatorColor: widget.indicatorColor ??
                                      Theme.of(context).colorScheme.secondary,
                                  maxWidgetWidth: widgetConstrains.maxWidth,
                                  maxWidgetHeight: widgetConstrains.maxHeight,
                                  controller: tooltipController,
                                  textColor: widget.indicatorColor == null
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSecondary
                                      : Colors.black,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _BottomTitleBar(
              originalMinX: _currentLeftX,
              originalMaxX: _currentRightX,
              intervalsCount: 4,
              textColor: widget.legendLabelColor,
              barHeight: LineAreaChart.bottomLabelBarHeight,
              leftOffset: LineAreaChart.leftLabelBarWidth,
              controller: titleBarController,
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipController {
  void Function(FlSpot?) setHighlight = (_) {};
  void Function() triggerRebuild = () {};
}

class _ChartTooptip extends StatefulWidget {
  const _ChartTooptip({
    required this.xOffset,
    required this.yOffset,
    required this.indicatorColor,
    required this.maxWidgetWidth,
    required this.maxWidgetHeight,
    required this.controller,
    required this.textColor,
  });

  final double Function(double) xOffset;
  final double Function(double) yOffset;
  final double maxWidgetWidth;
  final double maxWidgetHeight;
  final _TooltipController controller;

  final Color indicatorColor;
  final Color textColor;

  @override
  State<_ChartTooptip> createState() => _ChartTooptipState();
}

class _ChartTooptipState extends State<_ChartTooptip> {
  FlSpot? highlight;

  @override
  void initState() {
    super.initState();

    _rebindControler();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _rebindControler();
  }

  void _rebindControler() {
    widget.controller.setHighlight = (spot) => setState(() {
          highlight = spot;
        });

    widget.controller.triggerRebuild = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (highlight == null) return Container();
    final offsetX = widget.xOffset(widget.maxWidgetWidth);
    final offsetY = widget.yOffset(widget.maxWidgetHeight);

    if (offsetX < -LineAreaChart.tooptipWidth / 2 ||
        offsetX > widget.maxWidgetWidth - LineAreaChart.tooptipWidth / 2) {
      return Container();
    }

    return Positioned(
      left: offsetX,
      bottom: offsetY,
      child: SizedBox(
        width: LineAreaChart.tooptipWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: widget.indicatorColor),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    convertDistance(highlight!.y),
                    style: TextStyle(fontSize: 16, color: widget.textColor),
                  ),
                ),
              ),
            ),
            Text(
              "▼",
              style: TextStyle(color: widget.indicatorColor, height: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewportController {
  void Function(double, double) changeViewport = (a, b) {};
}

class _Chart extends StatefulWidget {
  const _Chart({
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    required this.spots,
    required this.highlightedIntervals,
    required this.viewportController,
  });

  final double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final List<FlSpot> spots;
  final List<(List<FlSpot>, Color)> highlightedIntervals;
  final _ViewportController viewportController;

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  late double currentLeftX;
  late double currentRightX;

  @override
  void initState() {
    super.initState();

    currentLeftX = widget.minX;
    currentRightX = widget.maxX;
    _rebindController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebindController();
  }

  void _rebindController() {
    widget.viewportController.changeViewport = (left, right) {
      setState(() {
        currentLeftX = left;
        currentRightX = right;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        maxY: widget.maxY,
        minY: widget.minY,
        maxX: currentRightX,
        minX: currentLeftX,
        // Data
        lineBarsData: [
          LineChartBarData(
            spots: widget.spots,
            isCurved: false,
            barWidth: 4,
            color: const Color(0xFF3a77ff),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color.fromARGB(200, 157, 200, 250),
            ),
          ),
          for (final interval in widget.highlightedIntervals)
            LineChartBarData(
              spots: interval.$1,
              isCurved: true,
              barWidth: 5,
              color: interval.$2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1F8AFE),
              ),
            ),
        ],
        // Background grid
        gridData: const FlGridData(
          show: false,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          verticalInterval: 100,
        ),
        //Border
        borderData: FlBorderData(
          show: true,
          border: const Border(
            top: BorderSide(width: 0, color: Colors.transparent),
            right: BorderSide(width: 0, color: Colors.transparent),
            bottom: BorderSide(width: 1, color: Color(0xff37434d)),
            left: BorderSide(width: 1, color: Color(0xff37434d)),
          ),
        ),

        clipData: const FlClipData.all(),
      ),
    );
  }
}

class _TitleBarController {
  void Function(double start, double end) verticalAxisViewportChanged =
      (_, __) {};
  void Function(double start, double end) horizontalAxisViewportChanged =
      (_, __) {};
}

class _LeftTitleBar extends StatefulWidget {
  final double originalMinY;
  final double originalMaxY;
  final int intervalsCount;
  final double barWidth;
  final double bottomOffset;
  final _TitleBarController controller;

  final Color textColor;

  const _LeftTitleBar({
    required this.originalMinY,
    required this.originalMaxY,
    required this.intervalsCount,
    required this.barWidth,
    required this.bottomOffset,
    required this.textColor,
    required this.controller,
  });

  @override
  State<_LeftTitleBar> createState() => _LeftTitleBarState();
}

class _LeftTitleBarState extends State<_LeftTitleBar> {
  double minY = 0;
  double maxY = 0;

  @override
  void initState() {
    super.initState();

    minY = widget.originalMinY;
    maxY = widget.originalMaxY;

    _bindController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _bindController();
  }

  void _bindController() {
    widget.controller.verticalAxisViewportChanged = (mn, mx) {
      setState(() {
        minY = mn;
        maxY = mx;
      });
    };
  }

  double getValueAtInterval(int interval) {
    return minY +
        (maxY - minY) *
            (widget.intervalsCount - interval - 1) /
            (widget.intervalsCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.barWidth,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < widget.intervalsCount; i++)
                  Text(
                    convertDistance(getValueAtInterval(i)),
                    style: TextStyle(fontSize: 9, color: widget.textColor),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),
          SizedBox(height: widget.bottomOffset),
        ],
      ),
    );
  }
}

class _BottomTitleBar extends StatefulWidget {
  final double originalMinX;
  final double originalMaxX;
  final int intervalsCount;
  final double barHeight;
  final double leftOffset;
  final _TitleBarController controller;

  final Color textColor;

  const _BottomTitleBar({
    required this.originalMinX,
    required this.originalMaxX,
    required this.intervalsCount,
    required this.barHeight,
    required this.leftOffset,
    required this.textColor,
    required this.controller,
  });

  @override
  State<_BottomTitleBar> createState() => _BottomTitleBarState();
}

class _BottomTitleBarState extends State<_BottomTitleBar> {
  double minX = 0;
  double maxX = 0;

  @override
  void initState() {
    super.initState();

    minX = widget.originalMinX;
    maxX = widget.originalMaxX;

    _bindController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _bindController();
  }

  void _bindController() {
    widget.controller.horizontalAxisViewportChanged = (mn, mx) {
      setState(() {
        minX = mn;
        maxX = mx;
      });
    };
  }

  double getValueAtInterval(int interval) {
    return minX + (maxX - minX) * interval / (widget.intervalsCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.barHeight,
      child: Row(
        children: [
          SizedBox(width: widget.leftOffset),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < widget.intervalsCount; i++)
                  Text(
                    convertDistance(getValueAtInterval(i)),
                    style: TextStyle(fontSize: 9, color: widget.textColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGestureDetector extends StatelessWidget {
  final void Function(double percentageOfChartWidth) onDragWithOneFinger;
  final void Function(double deltaXOffset) onDragWithTwoFingers;
  final void Function(
    double percentageOfChartWidthStart,
    double horizontalScale,
  ) onScale;
  final Widget child;
  final bool hasGestures;

  const _ChartGestureDetector({
    required this.onDragWithOneFinger,
    required this.onDragWithTwoFingers,
    required this.onScale,
    required this.hasGestures,
    required this.child,
  });

  double getPercentageOfChartWidthFromXOffset(
    double xOffset,
    double widgetWidth,
  ) {
    return xOffset / widgetWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        return GestureDetector(
          onScaleUpdate: (details) {
            if (!hasGestures) {
              return;
            }
            // Higher than 1 -> gestures with high vertical range are more likely to be recognized
            // Closer to 1 -> gestures with high vertical range are less likely to be recognized
            const scaleV = 5;

            // Higher than 1 -> the gesture has higher chance of being registered as DRAG TWO FINGERS
            // Closer to 1 -> the gesture has higher chance of being registered as SCALE
            const scaleH = 1.30;

            // Ignore extreme vertical gestures
            if (details.verticalScale < 1 / scaleV ||
                details.verticalScale > scaleV) {
              return;
            }

            if (details.scale < 1 / scaleH || details.scale > scaleH) {
              // SCALE
              final horizontalScale = details.horizontalScale;
              final startLocalFocalPointX = details.localFocalPoint.dx;
              final startPercentageX = getPercentageOfChartWidthFromXOffset(
                startLocalFocalPointX,
                constrains.maxWidth,
              );

              onScale(startPercentageX, horizontalScale);
            } else if (details.pointerCount == 1) {
              // DRAG ONE FINGER
              final percentageOfWidgetX = getPercentageOfChartWidthFromXOffset(
                details.localFocalPoint.dx,
                constrains.maxWidth,
              );
              if (percentageOfWidgetX < 0 || percentageOfWidgetX > 1) return;
              onDragWithOneFinger(percentageOfWidgetX);
            } else if (details.pointerCount == 2) {
              // DRAG TWO FINGERS
              onDragWithTwoFingers(-details.focalPointDelta.dx);
            }
          },
          child: child,
        );
      },
    );
  }
}
