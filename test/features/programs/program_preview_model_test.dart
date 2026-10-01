import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/features/programs/data/models/program_models.dart';

void main() {
  Map<String, dynamic> preview({Object? startDate}) => {
    'title': 'Отжимания',
    'description': '7 дней',
    'duration_days': 1,
    'days': [
      {'day_number': 1, 'is_rest': true},
    ],
    'disclaimer': 'AI',
    'start_date': startDate,
  };

  test('AI matndan topgan boshlanish sanasi o‘qiladi', () {
    final model = ProgramPreviewModel.fromJson(
      preview(startDate: '2026-10-05'),
    );
    expect(model.startDate, DateTime(2026, 10, 5));
  });

  test('sana aytilmagan yoki buzuq bo‘lsa — null (bugundan)', () {
    expect(ProgramPreviewModel.fromJson(preview()).startDate, isNull);
    expect(
      ProgramPreviewModel.fromJson(preview(startDate: 'soon')).startDate,
      isNull,
    );
  });
}
