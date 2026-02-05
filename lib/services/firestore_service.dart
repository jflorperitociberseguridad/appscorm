import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createCourse(CourseModel course) async {
    try {
      final batch = _db.batch();

      // 1. Prepare the Course document
      final courseRef = _db.collection('courses').doc(course.id);
      batch.set(courseRef, course.toMap());

      // 2. Queue all modules in a single batch
      final modulesRef = courseRef.collection('modules');
      for (final module in course.modules) {
        batch.set(modulesRef.doc(module.id), module.toMap());
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
