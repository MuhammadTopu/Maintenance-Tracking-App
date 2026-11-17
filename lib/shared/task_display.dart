import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maintenance_genie/data/models/task_list_response_model.dart';

const Set<String> _placeholders = <String>{
  'n/a',
  'na',
  'unknown',
  'unavailable',
  'not specified',
  'not available',
  'none',
  'null',
  '-',
  '--',
};

bool isMeaningful(String? value) {
  if (value == null) return false;
  final text = value.trim();
  return text.isNotEmpty && !_placeholders.contains(text.toLowerCase());
}

String formatTaskDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

Color priorityColor(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
      return const Color(0xffC62828);
    case 'medium':
      return const Color(0xffE65100);
    case 'low':
      return const Color(0xff2E7D32);
    default:
      return const Color(0xff546E7A);
  }
}

extension TaskDisplay on TaskResponse {
  String get dueDateLabel {
    final due = dueAt;
    if (due != null) return formatTaskDate(due.toUtc());
    if (isMeaningful(nextDueDate)) return nextDueDate;
    return 'Not scheduled';
  }

  String? get completedOnLabel {
    final done = lastDate;
    if (!isComplete || done == null) return null;
    return formatTaskDate(done.toLocal());
  }

  String? get mileageLabel {
    if (!isMeaningful(nextDueMileage)) return null;
    final number = num.tryParse(nextDueMileage.replaceAll(',', '').trim());
    if (number == null) return nextDueMileage;
    return '${NumberFormat.decimalPattern().format(number)} mi';
  }

  String? get lastServicedLabel {
    final date = itemLastServiceDate;
    if (date == null) return null;
    return formatTaskDate(date.toUtc());
  }
}

class TaskDetailRow {
  const TaskDetailRow(this.label, this.value, {this.isPriority = false});

  final String label;
  final String value;
  final bool isPriority;
}

List<TaskDetailRow> taskDetailRows(TaskResponse task) {
  final mileage = task.mileageLabel;
  final lastServiced = task.lastServicedLabel;

  return <TaskDetailRow>[
    if (isMeaningful(task.category)) TaskDetailRow('Category', task.category),
    if (isMeaningful(task.priority))
      TaskDetailRow('Priority', task.priority, isPriority: true),
    if (isMeaningful(task.recommendedInterval))
      TaskDetailRow('Recommended interval', task.recommendedInterval),
    if (isMeaningful(task.lastServiceAssumption))
      TaskDetailRow('Last service', task.lastServiceAssumption),
    if (mileage != null) TaskDetailRow('Next due mileage', mileage),
    if (lastServiced != null) TaskDetailRow('Item last serviced', lastServiced),
  ];
}