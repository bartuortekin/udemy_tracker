import 'package:hive/hive.dart';

const dailySettingsBoxName = 'settings';
const dailyAvailableMinutesKey = 'dailyAvailableMinutes';
const defaultDailyAvailableMinutes = 60;

class DailyCapacityRepository {
  DailyCapacityRepository({Box<int>? settingsBox})
    : _settingsBox = settingsBox ?? Hive.box<int>(dailySettingsBoxName);

  final Box<int> _settingsBox;

  int get dailyAvailableMinutes {
    final storedValue = _settingsBox.get(
      dailyAvailableMinutesKey,
      defaultValue: defaultDailyAvailableMinutes,
    );
    return storedValue == null || storedValue <= 0
        ? defaultDailyAvailableMinutes
        : storedValue;
  }

  Future<void> setDailyAvailableMinutes(int minutes) {
    if (minutes <= 0) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Daily available minutes must be greater than zero.',
      );
    }
    return _settingsBox.put(dailyAvailableMinutesKey, minutes);
  }
}
