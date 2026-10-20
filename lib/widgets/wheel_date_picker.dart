import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 滚动式日期选择器（滚轮），返回选中的日期时间，取消则返回 null。
/// [withTime] 为 true 时同时显示时/分滚轮。
Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  bool withTime = false,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  var selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                Text(withTime ? '选择日期时间' : '选择日期', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('确定'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: withTime ? CupertinoDatePickerMode.dateAndTime : CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              minimumDate: firstDate ?? DateTime(2000),
              maximumDate: lastDate ?? DateTime(2100),
              use24hFormat: withTime,
              onDateTimeChanged: (d) => selected = d,
            ),
          ),
        ],
      ),
    ),
  );
}
