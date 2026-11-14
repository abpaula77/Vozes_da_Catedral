import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/core/utils/date_format_br.dart';

void main() {
  test('formats date as dd/MM/yyyy', () {
    expect(formatarData(DateTime(2026, 3, 5, 23, 59)), '05/03/2026');
  });

  test('formats time in 24h HH:mm', () {
    expect(formatarHora(DateTime(2026, 3, 5, 9, 5)), '09:05');
    expect(formatarHora(DateTime(2026, 3, 5, 19, 30)), '19:30');
    expect(formatarHora(DateTime(2026, 3, 5, 0, 0)), '00:00');
  });

  test('formats date and time together', () {
    expect(
      formatarDataHora(DateTime(2026, 12, 25, 19, 30)),
      '25/12/2026 19:30',
    );
  });

  test('converts UTC values to the device local time zone', () {
    final utc = DateTime.utc(2026, 3, 5, 22, 0);
    expect(formatarDataHora(utc), formatarDataHora(utc.toLocal()));
  });
}
