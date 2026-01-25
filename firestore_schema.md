# Firestore Database Schema - Aula Cibermedida SCORM-Master

## Overview
This schema is designed to support the hierarchical structure of **Courses > Modules > Sections > Interactions**. It leverages Firestore's subcollections for scalability (Modules) and Map structures for fixed Configuration items (Sections).

## Collections

### 1. `courses`
Root collection for all courses.

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique Course ID (UUID/Auto-ID) |
| `title` | String | Course Title |
| `description` | String | Brief course description |
| `author_id` | String | ID of the creating user |
| `created_at` | Timestamp | Creation date |
| `updated_at` | Timestamp | Last modified date |
| `scorm_version` | String | target version: "1.2" or "2004" |
| `status` | String | "draft", "processing", "ready", "archived" |

### 2. `courses/{courseId}/modules`
Subcollection for the modules within a course. Each module represents an **"Interactive Book"**.

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique Module ID |
| `title` | String | Module Title (e.g. "Module 1: Fundamentals") |
| `order` | Number | Sort order index (1, 2, 3...) |
| `summary` | String | Short summary of the module content |
| `sections` | Map | Configuration for the 8 fixed sections (see below) |

#### `sections` Map Structure
The `sections` map contains keys for each fixed section. Each key holds an object with `enabled` (bool) and specific data.

```json
{
  "introduction": {
    "enabled": true,
    "title": "Introduction",
    "content": "Welcome text...",
    "objectives": ["Obj 1", "Obj 2"] 
  },
  "concept_map": {
    "enabled": true,
    "hotspots": [
      { "x": 10, "y": 20, "label": "Node A", "content": "..." }
    ]
  },
  "content_development": {
    "enabled": true,
    "blocks": [ /* Array of InteractiveBlock objects */ ] 
  },
  "key_concepts": {
    "enabled": true,
    "items": [
      { "term": "ADDIE", "definition": "Analysis..." }
    ]
  },
  "deep_dive": {
    "enabled": true,
    "resources": [
      { "type": "link", "url": "...", "label": "Read more" }
    ]
  },
  "glossary": {
    "enabled": true,
    "cards": [
      { "front": "Term", "back": "Definition", "audio": null }
    ]
  },
  "evaluation": {
    "enabled": true,
    "config": { "passing_score": 80, "randomize": true },
    "questions": [ /* Array of Question objects */ ]
  },
  "stats_closing": {
    "enabled": true,
    "message_pass": "Great job!",
    "message_fail": "Try again."
  }
}
```

### 3. Interactive Block Structure (JSON Object)
Used within `content_development.blocks` and potentially other flexible areas.

```json
{
  "id": "uuid",
  "type": "string", // One of the 20 types: 'accordion', 'drag_drop', 'fill_blanks', etc.
  "content": {
    // Dynamic based on 'type'. 
    // Example for 'accordion':
    "panels": [
      { "title": "Section 1", "text": "..." }
    ]
    // Example for 'multiple_choice':
    "question": "What is...?",
    "answers": [
      { "text": "A", "correct": true },
      { "text": "B", "correct": false }
    ],
    "feedback_correct": "Right!",
    "feedback_incorrect": "Wrong."
  },
  "config": {
    // Visual/Behavior settings
    "behavior_enable_retry": true
  }
}
```

## Indexes
- `courses`: Order by `updated_at` DESC.
- `modules`: Order by `order` ASC per course.
