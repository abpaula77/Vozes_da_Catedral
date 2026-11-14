import 'package:intl/intl.dart';

/// Brazilian date/time formatting (dd/MM/yyyy, 24h HH:mm).
///
/// Values are shown in the device's local time zone. Stored values are UTC.
final _dataFormat = DateFormat('dd/MM/yyyy');
final _horaFormat = DateFormat('HH:mm');

/// `05/03/2026`
String formatarData(DateTime data) => _dataFormat.format(data.toLocal());

/// `19:30`
String formatarHora(DateTime data) => _horaFormat.format(data.toLocal());

/// `05/03/2026 19:30`
String formatarDataHora(DateTime data) =>
    '${formatarData(data)} ${formatarHora(data)}';
