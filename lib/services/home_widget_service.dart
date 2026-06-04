import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/note_model.dart';
import '../models/weather_model.dart';
import 'weather_service.dart';

class HomeWidgetService {
  Future<void> update({
    required String cityName,
    required bool useFahrenheit,
    required CurrentWeather? weather,
    required DayNote? note,
    List<HourlyWeather>? nextHours,
    int widgetThemeIndex = 0,
  }) async {
    await HomeWidget.saveWidgetData<int>('widget_theme', widgetThemeIndex);
    await HomeWidget.saveWidgetData<String>('widget_city', cityName);
    await HomeWidget.saveWidgetData<String>(
      'widget_temp',
      weather != null
          ? '${TempUnit.convert(weather.temperature, useFahrenheit).round()}\u00B0'
          : '--\u00B0',
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_emoji',
      weather?.emoji ?? '\u2601\uFE0F',
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_note',
      note?.content ?? 'No plans for today',
    );

    final slots = nextHours ?? [];
    for (int i = 0; i < 6; i++) {
      if (i < slots.length) {
        final h = slots[i];
        final timeStr = DateFormat('ha').format(h.time);
        final tempStr = '${TempUnit.convert(h.temperature, useFahrenheit).round()}\u00B0';
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_time', timeStr);
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_temp', tempStr);
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_emoji', h.emoji);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_time', '');
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_temp', '');
        await HomeWidget.saveWidgetData<String>('widget_fc_${i}_emoji', '');
      }
    }

    await HomeWidget.updateWidget(
      name: 'WeatherWidgetProvider',
      androidName: 'WeatherWidgetProvider',
    );
  }
}
