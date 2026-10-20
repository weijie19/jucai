import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 滚动式日期选择器（滚轮），返回选中的日期，取消则返回 null。
Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required DateTime initialDate,
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
                const Text('选择日期', style: TextStyle(fontWeight: FontWeight.w600)),
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
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              minimumDate: firstDate ?? DateTime(2000),
              maximumDate: lastDate ?? DateTime(2100),
              onDateTimeChanged: (d) => selected = d,
            ),
          ),
        ],
      ),
    ),
  );
}
