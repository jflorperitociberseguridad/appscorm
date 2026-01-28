import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createCourse(CourseModel course) async {
    try {
      // 1. Create the Course document
      final courseRef = _db.collection('courses').doc(course.id);
      await courseRef.set(course.toMap());

      // 2. Create the Subcollection for Modules
      final modulesRef = courseRef.collection('modules');

      for (var module in course.modules) {
        await modulesRef.doc(module.id).set(module.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }
}
