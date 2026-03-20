# Plan de Implementación: Aula Cibermedida SCORM-Master (Actualizado)

Este documento detalla el estado actual del proyecto y la hoja de ruta para la finalización de "Aula Cibermedida SCORM-Master", la herramienta definitiva de autoría de cursos con IA.

## 🟢 Fase 1: Cimientos y Arquitectura (Completado)
- [x] **Configuración del Proyecto**: Flutter Web con soporte para `riverpod` y `go_router`.
- [x] **Modelado de Datos**: Estructuras para `Course`, `Module`, `InteractiveBlock` (Flexible JSON).
- [x] **Navegación**: Sistema de rutas (`/`, `/create`, `/editor`).
- [x] **Gestión de Estado**: Providers para gestión reactiva del curso y edición.

## 🟢 Fase 2: Editor de Cursos "Drag & Drop" (Completado)
- [x] **Interfaz de Edición**: Panel lateral de módulos y panel principal de bloques.
- [x] **Renderizado de Bloques**: Sistema `InteractiveBlockRenderer` soportando múltiples tipos visuales.
- [x] **Editores Especializados**:
    - [x] Texto / WYSIWYG.
    - [x] Cuestionarios (Selección Múltiple, V/F).
    - [x] Listas y Tarjetas (Acordeón, Flashcards).
    - [x] Imágenes Interactivas (Hotspots, Subida de imágenes).
    - [x] Estructura (Columnas, Libros).

## 🟢 Fase 3: El "Cerebro" AI Multi-Modal (Completado)
Implementación robusta de Inteligencia Artificial para asistir al creador en cada paso.
- [x] **Servicio AI Unificado (`AiService`)**: Integración limpia de múltiples proveedores.
- [x] **Generador de Cursos (Gemini Pro)**: Creación de estructura completa JSON desde un tema.
- [x] **Generador de Imágenes (Hugging Face SDXL)**: Creación de ilustraciones educativas de alta calidad (4K) sin marcas de agua.
- [x] **Asistente de Video (YouTube Smart Search)**: Búsqueda inteligente de contenido real relevante.
- [x] **Modo NotebookLM ("El Analista")**:
    - Capacidad de procesar manuales/PDFs largos (texto pegado).
    - Extracción de conceptos clave y estructura pedagógica.
- [x] **Modo Examinador ("El Profesor")**:
    - Lectura contextual de módulos completos.
    - Generación automática de exámenes (Question Sets) basados en el contenido leído.

## 🟢 Fase 4: Exportación SCORM 1.2 (Completado)
- [x] **Empaquetado**: Generación de estructura ZIP válida.
- [x] **Manifest**: Creación dinámica de `imsmanifest.xml`.
- [x] **Runtime**: Inyección de JavaScript (API SCORM 1.2) para comunicación con LMS (Moodle, Blackboard).
- [x] **HTML Generator**: Conversión de los bloques Flutter/JSON a HTML5 estático responsivo.

## 🟡 Fase 5: Refinamiento y UX (En Progreso)
- [ ] **Previsualización Real**: Ver cómo quedará el HTML antes de exportar.
- [ ] **Mejora de Estilos de Exportación**: Asegurar que el HTML generado sea tan bonito como la App.
- [ ] **Gestión de Errores**: Feedback más detallado si falla la API de IA (Cuotas, Conexión).
- [ ] **Persistencia Local**: Guardado de borradores en el navegador para no perder trabajo al recargar.

## ⚪ Fase 6: Backend y Colaboración (Pendiente)
- [ ] **Autenticación Firebase**: Login de usuarios (Profesores).
- [ ] **Nube de Cursos**: Guardar cursos en Firestore en lugar de memoria temporal.
- [ ] **Biblioteca de Medios**: Gestión de imágenes/vídeos subidos por el usuario en Storage.

## 🚀 Hitos Recientes
1.  **Integración de "Botones Mágicos"**: Panel de creación con 3 modos (NotebookLM, Mejora Rápida, Generación).
2.  **Reparación de Bug JSON**: Corrección de sintaxis en `assistBlockContent`.
3.  **Factoría de Exámenes**: Botón dedicado para evaluar módulos automáticamente.

---
**Próximo Objetivo Prioritario**: Implementar la **Persistencia** o mejorar la **Previsualización** del SCORM.
