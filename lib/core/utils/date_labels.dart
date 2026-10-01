import '../constants/app_strings.dart';
import 'api_date.dart';

/// Foydalanuvchiga ko'rinadigan sana: "Сегодня", "Завтра" yoki "5 октября".
///
/// Joriy yil bo'lmasa yil ham qo'shiladi — "5 октября 2027".
String dayLabel(DateTime date, {DateTime? now}) {
  final today = ApiDate.dayOnly(now ?? DateTime.now());
  final day = ApiDate.dayOnly(date);
  final diff = day.difference(today).inDays;

  if (diff == 0) return AppStrings.today;
  if (diff == 1) return AppStrings.tomorrow;
  if (diff == -1) return AppStrings.yesterday;

  final text = '${day.day} ${AppStrings.months[day.month - 1]}';
  return day.year == today.year ? text : '$text ${day.year}';
}
