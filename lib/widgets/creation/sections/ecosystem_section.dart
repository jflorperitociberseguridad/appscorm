import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class EcosystemSectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final double xApiDataDensity;
  final bool xApiEnabled;
  final ValueChanged<double> onXApiDataDensityChanged;
  final String xApiDataDensityLabel;
  final VoidCallback onSelectExpirationDate;
  final String Function(DateTime date) formatDate;

  final List<ChipOption> targetLmsOptions;
  final String targetLms;
  final ValueChanged<String> onTargetLmsChanged;
  final List<ChipOption> compatibilityPatchOptions;
  final List<String> compatibilityPatches;
  final ValueChanged<List<String>> onCompatibilityPatchesChanged;

  final bool passwordProtectionEnabled;
  final ValueChanged<bool> onPasswordProtectionEnabledChanged;
  final TextEditingController passwordController;
  final bool domainRestrictionEnabled;
  final ValueChanged<bool> onDomainRestrictionEnabledChanged;
  final TextEditingController domainController;
  final DateTime? contentExpirationDate;
  final bool offlineModeEnabled;
  final ValueChanged<bool> onOfflineModeEnabledChanged;

  final List<ChipOption> wcagLevelOptions;
  final String wcagLevel;
  final ValueChanged<String> onWcagLevelChanged;
  final bool gdprCompliance;
  final ValueChanged<bool> onGdprComplianceChanged;
  final bool anonymizeLearnerData;
  final ValueChanged<bool> onAnonymizeLearnerDataChanged;

  final ValueChanged<bool> onXApiEnabledChanged;
  final TextEditingController lrsUrlController;
  final TextEditingController lrsKeyController;
  final TextEditingController lrsSecretController;

  final TextEditingController supportEmailController;
  final TextEditingController supportPhoneController;
  final TextEditingController documentationUrlController;
  final TextEditingController versionTagController;
  final TextEditingController changeLogController;
  final TextEditingController ecosystemNotesController;

  const EcosystemSectionView({
    super.key,
    required this.inputStyle,
    required this.xApiDataDensity,
    required this.xApiEnabled,
    required this.onXApiDataDensityChanged,
    required this.xApiDataDensityLabel,
    required this.onSelectExpirationDate,
    required this.formatDate,
    required this.targetLmsOptions,
    required this.targetLms,
    required this.onTargetLmsChanged,
    required this.compatibilityPatchOptions,
    required this.compatibilityPatches,
    required this.onCompatibilityPatchesChanged,
    required this.passwordProtectionEnabled,
    required this.onPasswordProtectionEnabledChanged,
    required this.passwordController,
    required this.domainRestrictionEnabled,
    required this.onDomainRestrictionEnabledChanged,
    required this.domainController,
    required this.contentExpirationDate,
    required this.offlineModeEnabled,
    required this.onOfflineModeEnabledChanged,
    required this.wcagLevelOptions,
    required this.wcagLevel,
    required this.onWcagLevelChanged,
    required this.gdprCompliance,
    required this.onGdprComplianceChanged,
    required this.anonymizeLearnerData,
    required this.onAnonymizeLearnerDataChanged,
    required this.onXApiEnabledChanged,
    required this.lrsUrlController,
    required this.lrsKeyController,
    required this.lrsSecretController,
    required this.supportEmailController,
    required this.supportPhoneController,
    required this.documentationUrlController,
    required this.versionTagController,
    required this.changeLogController,
    required this.ecosystemNotesController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: const Text("Optimización y Target LMS (Compatibilidad)"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Compatibilidad y target LMS",
                icon: Icons.language,
                color: const Color(0xFF2563EB),
                children: [
                  const SectionLabel(text: "Selector de plataforma"),
                  IconChoiceChips(
                    options: targetLmsOptions,
                    current: targetLms,
                    onChanged: onTargetLmsChanged,
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(text: "Parches de compatibilidad"),
                  FilterChips(
                    options: compatibilityPatchOptions,
                    selected: compatibilityPatches,
                    onChanged: onCompatibilityPatchesChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.security),
            title: const Text("Seguridad, DRM y Licenciamiento"),
            children: [
              SectionCard(
                title: "Control de acceso",
                icon: Icons.security,
                color: const Color(0xFFDC2626),
                children: [
                  SwitchRow(
                    title: "Protección por contraseña",
                    value: passwordProtectionEnabled,
                    onChanged: onPasswordProtectionEnabledChanged,
                  ),
                  if (passwordProtectionEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: inputStyle("Clave de acceso"),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchRow(
                    title: "Restricción de dominio (CORS)",
                    value: domainRestrictionEnabled,
                    onChanged: onDomainRestrictionEnabledChanged,
                  ),
                  if (domainRestrictionEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: domainController,
                      decoration: inputStyle("URL permitida (ej: https://lms.miempresa.com)"),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Fecha de expiración del contenido"),
                  InkWell(
                    onTap: onSelectExpirationDate,
                    child: InputDecorator(
                      decoration: inputStyle("Selecciona fecha"),
                      child: Text(
                        contentExpirationDate == null ? "Sin fecha" : formatDate(contentExpirationDate!),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchRow(
                    title: "Permitir descarga y ejecución sin internet (PWA/Offline SCORM)",
                    value: offlineModeEnabled,
                    onChanged: onOfflineModeEnabledChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.accessibility),
            title: const Text("Accesibilidad y Cumplimiento Normativo"),
            children: [
              SectionCard(
                title: "Compliance y privacidad",
                icon: Icons.accessibility,
                color: const Color(0xFF0F766E),
                children: [
                  const SectionLabel(text: "Estándar WCAG"),
                  IconChoiceChips(
                    options: wcagLevelOptions,
                    current: wcagLevel,
                    onChanged: onWcagLevelChanged,
                  ),
                  const SizedBox(height: 12),
                  SwitchRow(
                    title: "Cumplimiento RGPD/GDPR",
                    subtitle: "Muestra aviso de privacidad al inicio",
                    value: gdprCompliance,
                    onChanged: onGdprComplianceChanged,
                  ),
                  SwitchRow(
                    title: "Anonimizar datos del alumno",
                    subtitle: "No envía nombre al LMS, solo ID",
                    value: anonymizeLearnerData,
                    onChanged: onAnonymizeLearnerDataChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.analytics),
            title: const Text("Analítica Avanzada y xAPI (LRS)"),
            children: [
              SectionCard(
                title: "Telemetry y LRS",
                icon: Icons.analytics,
                color: const Color(0xFF7C3AED),
                children: [
                  SwitchRow(
                    title: "Habilitar Tin Can API",
                    value: xApiEnabled,
                    onChanged: onXApiEnabledChanged,
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Endpoint LRS"),
                  TextField(
                    controller: lrsUrlController,
                    enabled: xApiEnabled,
                    decoration: inputStyle("LRS URL"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: lrsKeyController,
                          enabled: xApiEnabled,
                          decoration: inputStyle("Key"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lrsSecretController,
                          enabled: xApiEnabled,
                          obscureText: true,
                          decoration: inputStyle("Secret"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Densidad de datos"),
                  DataDensitySlider(
                    value: xApiDataDensity,
                    label: xApiDataDensityLabel,
                    enabled: xApiEnabled,
                    onChanged: onXApiDataDensityChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.build),
            title: const Text("DevOps, Soporte y Versionado"),
            children: [
              SectionCard(
                title: "Operación y soporte",
                icon: Icons.build,
                color: const Color(0xFF0F172A),
                children: [
                  const SectionLabel(text: "Información de soporte"),
                  TextField(
                    controller: supportEmailController,
                    decoration: inputStyle("Email de ayuda"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: supportPhoneController,
                    decoration: inputStyle("Teléfono"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: documentationUrlController,
                    decoration: inputStyle("URL de documentación"),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(text: "Control de versiones"),
                  TextField(
                    controller: versionTagController,
                    decoration: inputStyle("Versión del Proyecto (ej: 1.0.5)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: changeLogController,
                    maxLines: 3,
                    decoration: inputStyle("Log de cambios"),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(text: "Notas de ecosistema"),
                  TextField(
                    controller: ecosystemNotesController,
                    maxLines: 3,
                    decoration: inputStyle("Ej: LMS, repositorios, accesos..."),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
