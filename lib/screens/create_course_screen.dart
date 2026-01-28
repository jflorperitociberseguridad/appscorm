import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../widgets/creation/sections/identity_section.dart';
import '../widgets/creation/sections/evaluation_section.dart';
import '../widgets/creation/sections/scorm_section.dart';
import '../widgets/creation/sections/ecosystem_section.dart';
import '../widgets/creation/sections/strategy_section.dart';
import '../widgets/creation/sections/architecture_section.dart';
import '../widgets/creation/sections/style_section.dart';
import '../widgets/creation/sections/support_section.dart';
import '../widgets/creation/sections/interactivity_section.dart';
import '../widgets/creation/sections/multimedia_section.dart';
import '../widgets/creation/sections/content_bank_section.dart';
import '../widgets/creation/creation_shared_widgets.dart';
import '../widgets/creation/manuscript_logic_handler.dart';
import '../widgets/creation/course_generation_controller.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

part 'create_course_screen_state.dart';
part 'create_course_screen_fields.dart';
part 'create_course_screen_zone_body.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}
