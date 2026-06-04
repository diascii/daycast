import '../models/weather_model.dart';

class NotificationMessageBuilder {
  static String build(String noteContent, DayWeather weather, DateTime date) {
    final dateStr = _formatDate(date);
    final keywords = noteContent.toLowerCase();

    if (weather.isBadWeather) {
      if (_hasKeyword(keywords,
          ['picnic', 'bbq', 'barbecue', 'outdoor', 'park', 'garden'])) {
        return 'Heads up! Your outdoor plan on $dateStr might be affected - ${weather.description} expected (${weather.tempMax.round()}/${weather.tempMin.round()}). Consider a backup plan!';
      }
      if (_hasKeyword(keywords, ['beach', 'swim', 'surf', 'boat', 'sail'])) {
        return 'Beach day alert! $dateStr is showing ${weather.description}. Waves and weather might not cooperate.';
      }
      if (_hasKeyword(keywords, ['hike', 'trek', 'trail', 'climb', 'camp'])) {
        return 'Trail warning! ${weather.description} expected on $dateStr. Stay safe - check conditions before you go.';
      }
      if (_hasKeyword(
          keywords, ['run', 'jog', 'cycle', 'bike', 'workout', 'exercise'])) {
        return 'Weather check! ${weather.description} on $dateStr. You might want to move your workout indoors.';
      }
      if (_hasKeyword(
          keywords, ['wedding', 'party', 'event', 'birthday', 'celebration'])) {
        return 'Event alert! ${weather.description} is forecast for $dateStr. If it is outdoors, time to prep a Plan B.';
      }
      if (_hasKeyword(
          keywords, ['travel', 'flight', 'trip', 'drive', 'road'])) {
        return 'Travel heads up! ${weather.description} on $dateStr could affect your journey. Check for delays.';
      }
      return 'Weather alert for $dateStr: ${weather.description} (${weather.tempMax.round()}/${weather.tempMin.round()}). You have a plan that day - might be worth checking it.';
    }

    if (weather.isGoodWeather) {
      if (_hasKeyword(keywords,
          ['picnic', 'bbq', 'barbecue', 'outdoor', 'park', 'garden'])) {
        return 'Perfect conditions for $dateStr! ${weather.description}, ${weather.tempMax.round()} - ideal for your outdoor plans.';
      }
      if (_hasKeyword(keywords, ['beach', 'swim', 'surf'])) {
        return 'Beach day approved! $dateStr looks beautiful - ${weather.description}, ${weather.tempMax.round()}.';
      }
      if (_hasKeyword(keywords, ['hike', 'trek', 'trail', 'climb', 'camp'])) {
        return 'Trail conditions look great for $dateStr! ${weather.description} and ${weather.tempMax.round()} - perfect hiking weather.';
      }
      if (_hasKeyword(keywords, ['run', 'jog', 'cycle', 'bike', 'workout'])) {
        return 'Go crush it! $dateStr is ${weather.description}, ${weather.tempMax.round()} - great day for your outdoor workout.';
      }
      if (_hasKeyword(
          keywords, ['wedding', 'party', 'event', 'birthday', 'celebration'])) {
        return 'Your event weather looks gorgeous for $dateStr - ${weather.description}, ${weather.tempMax.round()}.';
      }
      return 'Great news for $dateStr! ${weather.description}, ${weather.tempMax.round()}/${weather.tempMin.round()} - nice weather for your plans.';
    }

    return 'Weather update for $dateStr: ${weather.emoji} ${weather.description}, ${weather.tempMax.round()}/${weather.tempMin.round()}. You have something planned.';
  }

  static bool _hasKeyword(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
