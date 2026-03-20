import '../../models/course_model.dart';
import 'api_exceptions.dart';
import 'course_api_service.dart';

class CourseRepository {
  final CourseApiService _service;

  CourseRepository(this._service);

  Future<CourseModel> persistCourse(CourseModel course) async {
    try {
      return await _service.updateCourse(course);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return await _service.createCourse(course);
      }
      rethrow;
    }
  }
}
