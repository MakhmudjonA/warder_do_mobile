import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/error_mapper.dart';
import '../../domain/entities/program.dart';
import '../models/program_models.dart';

/// Dasturlar bo'yicha HTTP so'rovlar.
abstract class ProgramsRemoteDataSource {
  Future<ProgramPreviewModel> generate({
    required String prompt,
    int? durationDays,
  });

  Future<void> save({
    required ProgramPreview preview,
    required String startDate,
    required String habitTitle,
    required String habitIcon,
    required String habitColor,
  });
}

class ProgramsRemoteDataSourceImpl implements ProgramsRemoteDataSource {
  const ProgramsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ProgramPreviewModel> generate({
    required String prompt,
    int? durationDays,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.programsGenerate,
        // `duration_days` ni faqat foydalanuvchi aniq bergan bo'lsa yuboramiz —
        // aks holda uzunlikni AI matndan o'zi aniqlaydi.
        data: {'prompt': prompt, 'duration_days': ?durationDays},
        // AI javobi oddiy so'rovdan ancha uzoq: backend Gemini'ni 60 s gacha,
        // ikki urinishgacha kutadi (docs/PROGRAMS.md). Umumiy 20 s bilan
        // telefon javobni kutmay uzib qo'yardi.
        options: Options(receiveTimeout: ApiConstants.aiReceiveTimeout),
      );
      return ProgramPreviewModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> save({
    required ProgramPreview preview,
    required String startDate,
    required String habitTitle,
    required String habitIcon,
    required String habitColor,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.programs,
        data: {
          'title': preview.title,
          'description': preview.description,
          'start_date': startDate,
          'source': 'ai',
          'habit': {
            'title': habitTitle,
            'icon': habitIcon,
            'color': habitColor,
          },
          'days': preview.days.map(ProgramDayModel.encode).toList(),
        },
      );
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
