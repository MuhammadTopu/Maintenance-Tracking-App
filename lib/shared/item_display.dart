import 'package:intl/intl.dart';
import 'package:maintenance_genie/data/models/item.dart';
const String kNotAvailable = 'N/A';

String? formatApiDate(String? iso, {String pattern = 'yyyy-MM-dd'}) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso; // unexpected format: show it as received
  return DateFormat(pattern).format(parsed);
}

class _Field {
  const _Field(this.label, this.value, {this.alwaysShow = false});

  final String label;
  final String? value;
  final bool alwaysShow;
}

List<MapEntry<String, String>> itemInfoRows(Item item) {
  final notes = _Field('Notes', item.userNotes);

  final List<_Field> fields = switch (item) {
    VehicleItem v => [
      _Field('Category', v.category, alwaysShow: true),
      _Field('Brand', v.brand, alwaysShow: true),
      _Field('Model', v.model, alwaysShow: true),
      _Field('Year', v.yearOfTheModel, alwaysShow: true),
      _Field('Purchase Date', formatApiDate(v.purchaseDate), alwaysShow: true),
      _Field('Current Mileage', _miles(v.currentMileage), alwaysShow: true),
      _Field('Total Mileage', _miles(v.totalMileage), alwaysShow: true),
      _Field('Avg. Mileage / Year', _miles(v.averageMileagePerYear),
          alwaysShow: true),
      _Field('Engine', v.engine, alwaysShow: true),
      _Field('Transmission', v.transmission, alwaysShow: true),
      _Field('Drivetrain', v.drivetrain, alwaysShow: true),
      notes,
    ],
    HomeItem h => [
      _Field('Category', h.category, alwaysShow: true),
      _Field('Property Type', h.propertyType, alwaysShow: true),
      _Field('Year Built', h.yearBuilt),
      _Field('ZIP Code', h.zipCode),
      _Field('Ownership', h.ownOrRent),
      _Field('Systems', h.systems.isEmpty ? null : h.systemLabels.join(', ')),
      notes,
    ],
    OtherItem o => [
      _Field('Category', o.category, alwaysShow: true),
      _Field('Group', o.group),
      _Field('Sub Category', o.subCategory),
      _Field('Description', o.description),
      _Field('Due Date', formatApiDate(o.dueDate)),
      _Field('Repeat', o.repeat),
      _Field('Reminder', o.reminder),
      notes,
    ],
    UnknownItem u => [
      _Field('Category', u.category, alwaysShow: true),
      notes,
    ],
  };

  return [
    for (final field in fields)
      if (_hasText(field.value))
        MapEntry(field.label, field.value!.trim())
      else if (field.alwaysShow)
        MapEntry(field.label, kNotAvailable),
  ];
}

String itemSummary(Item item) {
  final parts = switch (item) {
    VehicleItem v => [
      [v.brand, v.model].where(_hasText).join(' '),
      v.yearOfTheModel,
    ],
    HomeItem h => [
      h.propertyType,
      _hasText(h.zipCode) ? 'ZIP ${h.zipCode}' : null,
    ],
    OtherItem o => [
      o.group,
      _hasText(formatApiDate(o.dueDate))
          ? 'Due ${formatApiDate(o.dueDate, pattern: 'MMM d, yyyy')}'
          : null,
    ],
    UnknownItem _ => <String?>[],
  };

  final text = parts.where(_hasText).join(' · ');
  return text.isEmpty ? kNotAvailable : text;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String? _miles(int? value) => value == null ? null : '$value miles';