import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/clock.dart';
import '../../domain/entities/time_entry.dart';
import 'formatters.dart';

/// Время, прошедшее с запуска таймера; обновляется раз в секунду.
///
/// Длительность каждый раз считается от [TimeEntry.startedAt], а не
/// накапливается прибавлением секунды: так значение не «уплывает»,
/// если вкладка браузера была неактивна и тики пропускались.
class ElapsedTimeText extends StatefulWidget {
  const ElapsedTimeText({super.key, required this.entry, this.style});

  final TimeEntry entry;
  final TextStyle? style;

  @override
  State<ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends State<ElapsedTimeText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = context.watch<Clock>().now();
    return Text(
      formatDuration(widget.entry.durationAt(now)),
      style: widget.style,
    );
  }
}
