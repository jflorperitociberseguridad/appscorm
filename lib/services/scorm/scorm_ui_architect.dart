import 'scorm_engine_scripts.dart';

class ScormUiArchitect {
  static String buildPage({
    required String title,
    required String bodyContent,
    required int progress,
  }) {
    final styles =
        _premiumStyles.replaceAll('{{PROGRESS}}', progress.toString());
    final scripts = ScormEngineScripts.buildScripts(progress);
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    $styles
  </style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <span style="font-size:24px">🎓</span> <span>$title</span>
    </div>
    <div class="header-actions">
      <button class="panel-toggle" onclick="togglePanel('left')">☰ Navegacion</button>
      <button class="panel-toggle" onclick="togglePanel('right')">Panel →</button>
    </div>
  </div>

  <div class="layout" id="layoutRoot">
    <aside class="left-nav">
      <div class="panel-title" style="color:rgba(255,255,255,0.7);"><span>📚</span> NAVEGACION</div>
      <div class="block-nav" id="blockNav"></div>
    </aside>

    <main class="center-content">
      <div class="content-inner">
        $bodyContent
      </div>
    </main>

    <aside class="right-panel">
      <div class="panel-title"><span>📈</span> PROGRESO</div>
      <div class="progress-card">
        <div style="display:flex; justify-content:space-between; font-size:12px; color:#475569; margin-bottom:5px;">
           <span>Completado</span> <strong>$progress%</strong>
        </div>
        <div class="progress-track"><div class="progress-fill"></div></div>
        <div style="font-size:11px; color:#64748b; text-align:right">Sigue así, vas muy bien.</div>
      </div>

      <div class="widget-card" style="margin-top:16px;">
        <div class="widget-title"><span>🏅</span> LOGROS</div>
        <div class="badge-row" id="badgeRow">
          <div class="badge" data-threshold="20">⭐</div>
          <div class="badge" data-threshold="50">🚀</div>
          <div class="badge" data-threshold="80">🏆</div>
        </div>
      </div>

      <div class="widget-card" style="margin-top:16px;">
        <div class="widget-title"><span>📅</span> CALENDARIO ESTUDIO</div>
        <div class="cal-grid" id="calendarGrid">
           <div class="cal-cell cal-head">L</div><div class="cal-cell cal-head">M</div><div class="cal-cell cal-head">X</div><div class="cal-cell cal-head">J</div><div class="cal-cell cal-head">V</div><div class="cal-cell cal-head">S</div><div class="cal-cell cal-head">D</div>
           <div class="cal-cell day" onclick="toggleDay(this)">1</div><div class="cal-cell day" onclick="toggleDay(this)">2</div><div class="cal-cell day" onclick="toggleDay(this)">3</div><div class="cal-cell day" onclick="toggleDay(this)">4</div><div class="cal-cell day" onclick="toggleDay(this)">5</div><div class="cal-cell day" onclick="toggleDay(this)">6</div><div class="cal-cell day" onclick="toggleDay(this)">7</div>
           <div class="cal-cell day" onclick="toggleDay(this)">8</div><div class="cal-cell day" onclick="toggleDay(this)">9</div><div class="cal-cell day" onclick="toggleDay(this)">10</div><div class="cal-cell day" onclick="toggleDay(this)">11</div><div class="cal-cell day" onclick="toggleDay(this)">12</div><div class="cal-cell day" onclick="toggleDay(this)">13</div><div class="cal-cell day" onclick="toggleDay(this)">14</div>
           <div class="cal-cell day" onclick="toggleDay(this)">15</div><div class="cal-cell day" onclick="toggleDay(this)">16</div><div class="cal-cell day" onclick="toggleDay(this)">17</div><div class="cal-cell day" onclick="toggleDay(this)">18</div><div class="cal-cell day" onclick="toggleDay(this)">19</div><div class="cal-cell day" onclick="toggleDay(this)">20</div><div class="cal-cell day" onclick="toggleDay(this)">21</div>
           <div class="cal-cell day" onclick="toggleDay(this)">22</div><div class="cal-cell day" onclick="toggleDay(this)">23</div><div class="cal-cell day" onclick="toggleDay(this)">24</div><div class="cal-cell day" onclick="toggleDay(this)">25</div><div class="cal-cell day" onclick="toggleDay(this)">26</div><div class="cal-cell day" onclick="toggleDay(this)">27</div><div class="cal-cell day" onclick="toggleDay(this)">28</div>
        </div>
      </div>
      <button class="support-btn magnetic" onclick="window.location.href='mailto:soporte@curso.com'">💬 Soporte</button>
    </aside>
  </div>

  <div id="confetti" class="confetti-layer"></div>
  <div id="pageWipe" class="page-wipe"></div>

  <script>
    $scripts
  </script>
</body>
</html>
    ''';
  }
}

const String _premiumStyles = '''
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

:root { 
  --primary: #3B82F6; 
  --primary-dark: #1e40af;
  --bg-body: #F8FAFC; 
  --panel-bg: #ffffff;
  --nav-bg: #1E293B;
  --nav-text: rgba(255,255,255,0.7);
  --text-main: #0f172a; 
  --text-light: #64748b;
  --success: #10b981;
  --error: #ef4444;
  --border: #E2E8F0;
  --header-h: 64px;
  --halo-x: 50%;
  --halo-y: 30%;
  --halo-opacity: 0;
  --halo-color: 59,130,246;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; }

html { scroll-behavior: smooth; }
body { background: var(--bg-body); color: var(--text-main); height: 100vh; overflow: hidden; line-height: 1.6; font-weight: 400; }

.header { 
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: var(--header-h);
  background: rgba(255, 255, 255, 0.8);
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  z-index: 20;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06);
  backdrop-filter: blur(20px);
}

.brand { font-weight: 700; font-size: 18px; color: var(--primary-dark); display: flex; align-items: center; gap: 10px; }
.header-actions { display: flex; gap: 8px; }
.panel-toggle { 
  cursor: pointer; border: 1px solid var(--border); background: #ffffff; 
  color: #334155; border-radius: 10px; padding: 8px 12px; font-weight: 600; font-size: 13px;
  display: inline-flex; align-items: center; gap: 6px; transition: background 0.3s, color 0.3s, transform 0.3s;
}
.panel-toggle:hover { background: #f1f5f9; }

.layout {
  position: relative;
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  gap: 0;
  width: 100%;
  max-width: none;
  margin: 0 auto;
  padding: calc(var(--header-h) + 32px) 0 32px;
  height: calc(100vh - var(--header-h));
}

.left-nav {
  background: rgba(30, 41, 59, 0.85);
  border: 1px solid #1e293b;
  color: var(--nav-text);
  border-radius: 16px;
  padding: 16px;
  overflow-y: auto;
  box-shadow: 0 6px 16px rgba(15, 23, 42, 0.08);
  backdrop-filter: blur(12px);
  transition: transform 0.4s ease;
}

.layout.hide-left .left-nav {
  transform: translateX(-120%);
}

.center-content {
  position: relative;
  background: var(--bg-body);
  overflow-y: auto;
  padding: 0 40px 32px;
  min-height: calc(100vh - var(--header-h) - 32px);
}

.center-content::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at var(--halo-x) var(--halo-y), rgba(var(--halo-color), var(--halo-opacity)) 0%, rgba(var(--halo-color), 0) 60%);
  pointer-events: none;
  z-index: 0;
  transition: opacity 0.4s ease, background 1s ease;
}

.content-inner {
  width: min(95vw, 1600px);
  max-width: none;
  margin: 0 auto;
  padding-bottom: 40px;
  position: relative;
  z-index: 1;
}

.right-panel {
  position: fixed;
  right: 24px;
  top: calc(var(--header-h) + 24px);
  width: min(360px, 85vw);
  height: calc(100vh - var(--header-h) - 48px);
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: 20px;
  overflow-y: auto;
  box-shadow: 0 15px 35px rgba(15, 23, 42, 0.25);
  backdrop-filter: blur(16px);
  transition: transform 0.35s ease, opacity 0.35s ease;
  z-index: 22;
}

.layout.hide-right .right-panel {
  transform: translateX(120%);
  opacity: 0;
  pointer-events: none;
}

.center-content::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at var(--halo-x) var(--halo-y), rgba(var(--halo-color), var(--halo-opacity)) 0%, rgba(var(--halo-color), 0) 60%);
  pointer-events: none;
  z-index: 0;
  transition: opacity 0.4s ease, background 1s ease;
}

body::before {
  content: '';
  position: fixed;
  inset: 0;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120' viewBox='0 0 120 120'><g fill='none' stroke='%2394A3B8' stroke-width='1' opacity='0.03'><circle cx='12' cy='12' r='2'/><circle cx='60' cy='60' r='2'/><circle cx='108' cy='108' r='2'/><path d='M0 60h120M60 0v120'/></g></svg>");
  background-size: 120px 120px;
  background-position: 0 calc(var(--pattern-offset, 0) * 1px);
  z-index: 0;
  pointer-events: none;
  transition: background-position 0.3s ease;
}

.block img,
.block iframe,
.block video,
.block audio {
  width: 100%;
  max-width: 100%;
  height: auto;
  display: block;
}

.media-block img {
  object-fit: cover;
}

.layout, .header { position: relative; z-index: 1; }

.block-wrap { scroll-margin-top: 90px; position: relative; }
.block-wrap.staggered { opacity: 0; transform: translateY(16px); animation: fadeUp 0.6s ease forwards; }
.block-wrap.dimmed .card-educativa { filter: blur(1.5px); opacity: 0.9; }
.block-wrap.active .card-educativa {
  border-color: #3B82F6;
  box-shadow: 0 16px 28px rgba(59, 130, 246, 0.18), 0 0 32px rgba(59, 130, 246, 0.25);
  transform: translateY(-3px);
}
.block-wrap.active::before {
  content: '';
  position: absolute;
  inset: -30px;
  background: radial-gradient(circle, rgba(59,130,246,0.15) 0%, rgba(59,130,246,0.0) 60%);
  z-index: -1;
  pointer-events: none;
}

.fillblanks-text { line-height: 1.8; }
.blank-input { border: 1px solid #cbd5e1; border-radius: 6px; padding: 6px 8px; min-width: 120px; margin: 0 6px; }
.blank-input.right { border-color: #16a34a; background: #dcfce7; }
.blank-input.wrong { border-color: #dc2626; background: #fee2e2; }
.matching-list { display: flex; flex-direction: column; gap: 10px; }
.matching-row { display: flex; align-items: center; gap: 12px; }
.matching-row select { flex: 1; padding: 8px; border-radius: 8px; border: 1px solid #cbd5e1; }
.match-label { flex: 1; font-weight: 600; }
.scenario-options { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }
.block-nav { display: flex; flex-direction: column; gap: 10px; }
.block-nav-btn { text-align: left; background: transparent; border: 1px solid transparent; border-radius: 10px; padding: 10px 12px; font-size: 13px; color: var(--nav-text); cursor: pointer; transition: background 0.3s, color 0.3s, transform 0.3s; }
.block-nav-btn:hover { background: rgba(59,130,246,0.2); color: #ffffff; }
.block-nav-btn.active { background: #3B82F6; color: #ffffff; border-color: #3B82F6; box-shadow: 0 8px 16px rgba(59,130,246,0.35); }

/* --- ESTILOS DE BLOQUES DE CONTENIDO --- */
.page-title { font-size: 28px; font-weight: 600; color: #1e293b; margin: 16px 0 12px; letter-spacing: -0.03em; }
.divider { border: 0; border-top: 1px solid var(--border); margin: 20px 0; }

.card-educativa {
  background: #ffffff;
  padding: 28px;
  border-radius: 16px;
  margin-bottom: 24px;
  box-shadow: 0 2px 4px rgba(15,23,42,0.04), 0 8px 16px rgba(15,23,42,0.06), 0 18px 30px rgba(15,23,42,0.06);
  border: 1px solid #E2E8F0;
  transition: transform 0.3s, box-shadow 0.3s, border-color 0.3s, filter 0.3s, opacity 0.3s;
}
.card-educativa:hover {
  transform: translateY(-5px);
  box-shadow: 0 18px 30px rgba(15, 23, 42, 0.12);
  border-color: rgba(59, 130, 246, 0.35);
}

.module-shell {
  background: #fff;
  border-radius: 28px;
  margin: 20px auto;
  padding-bottom: 32px;
  box-shadow: 0 20px 45px rgba(15, 23, 42, 0.18);
  overflow: hidden;
  border: 1px solid rgba(15, 23, 42, 0.08);
}

.module-hero {
  padding: 40px 36px 32px;
  background: var(--hero-gradient, linear-gradient(135deg,#2563EB,#9333EA));
  color: #fff;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}
.module-hero h1 {
  margin: 20px 0 10px;
  font-size: 32px;
  font-weight: 700;
}
.hero-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.2);
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.2em;
}
.hero-meta {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
  display: flex;
  gap: 16px;
  align-items: center;
}
.hero-time::before {
  content: '⏰';
  margin-right: 6px;
}
.module-body {
  padding: 0 40px;
  margin-top: -32px;
}
.hero-overlap {
  margin-top: -40px;
  background: #fff;
  border-radius: 24px;
  box-shadow: 0 14px 30px rgba(15, 23, 42, 0.08);
  padding: 28px;
  position: relative;
  z-index: 2;
}
.reference-footer {
  margin-top: 8px;
  text-align: center;
}
.reference-link {
  color: #2563eb;
  font-weight: 600;
  text-decoration: none;
}
.reference-link:hover {
  text-decoration: underline;
}
.reference-modal {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
  z-index: 99;
}
.reference-modal.visible {
  opacity: 1;
  pointer-events: auto;
}
.reference-card {
  background: #fff;
  border-radius: 24px;
  width: min(90vw, 720px);
  padding: 30px;
  position: relative;
  box-shadow: 0 20px 40px rgba(15, 23, 42, 0.25);
}
.reference-card h3 {
  margin-top: 0;
}
.reference-body {
  margin-top: 12px;
  max-height: 60vh;
  overflow-y: auto;
  background: #f8fafc;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
  padding: 18px;
}
.reference-body pre {
  margin: 0;
  font-family: 'Inter', sans-serif;
  font-size: 14px;
  white-space: pre-wrap;
  color: #0f172a;
}
.modal-close {
  position: absolute;
  top: 10px;
  right: 10px;
  background: transparent;
  border: none;
  font-size: 26px;
  cursor: pointer;
  color: #475569;
}
.objective-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin: 0;
}
.objective-card {
  background: linear-gradient(135deg, #e0f2fe, #bae6fd);
  border-radius: 18px;
  padding: 22px;
  min-height: 90px;
  border: 1px solid #93c5fd;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  font-weight: 600;
  color: #0f172a;
  box-shadow: 0 10px 25px rgba(14, 165, 233, 0.18);
}
.accordion-block details {
  border-radius: 12px;
  border: 1px solid #cbd5f5;
  margin-bottom: 12px;
  padding: 12px 18px;
  background: #fff;
}
.accordion-block details summary {
  list-style: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  font-weight: 600;
}
.accordion-block details summary::after {
  content: '▾';
  transition: transform 0.3s ease;
}
.accordion-block details[open] summary::after {
  transform: rotate(180deg);
}

.block {
  background: transparent;
  padding: 0;
  margin: 0;
  border: 0;
  box-shadow: none;
}
.block h3 { margin-bottom: 15px; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; font-weight: 600; letter-spacing: -0.03em; }
.card-educativa p { max-width: 70ch; margin-left: auto; margin-right: auto; }

/* Media */
.media-block.center { text-align: center; }
.media-block img { max-width: 100%; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
.caption { font-size: 13px; color: var(--text-light); margin-top: 10px; font-style: italic; }
.video-block iframe, .video-block video { width: 100%; border-radius: 8px; aspect-ratio: 16/9; }
.quote-block { border-left: 4px solid var(--primary); padding-left: 20px; font-style: italic; color: #555; background: #f8fafc; padding: 20px; border-radius: 0 12px 12px 0; }

/* Timeline */
.timeline-container { position: relative; padding-left: 10px; }
.timeline-item { border-left: 2px solid var(--primary); padding-left: 25px; margin-bottom: 25px; position: relative; }
.timeline-item::before { 
  content:''; position: absolute; left: -7px; top: 0; width: 12px; height: 12px; 
  background: var(--primary); border: 2px solid white; border-radius: 50%; box-shadow: 0 0 0 2px var(--primary);
}
.tl-date { font-size: 12px; font-weight: bold; color: var(--primary); text-transform: uppercase; margin-bottom: 4px; }

/* Process */
.process-step { display: flex; gap: 20px; margin-bottom: 20px; align-items: flex-start; }
.step-num { 
  width: 36px; height: 36px; background: var(--primary); color: white; 
  border-radius: 50%; display: flex; align-items: center; justify-content: center; 
  font-weight: bold; font-size: 16px; flex-shrink: 0; box-shadow: 0 2px 4px rgba(37,99,235,0.3);
}

/* Interactivos */
.flashcard-block { height: 240px; perspective: 1000px; cursor: pointer; user-select: none; }
.card-inner { position: relative; width: 100%; height: 100%; transition: transform 0.6s cubic-bezier(0.4,0,0.2,1); transform-style: preserve-3d; }
.flashcard-block.flipped .card-inner { transform: rotateY(180deg); }
.card-front, .card-back { 
  position: absolute; width: 100%; height: 100%; backface-visibility: hidden; 
  display: flex; align-items: center; justify-content: center; padding: 30px; 
  font-size: 20px; text-align: center; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
}
.card-front { background: white; border: 1px solid #e2e8f0; color: #1e293b; }
.card-back { background: #eff6ff; border: 1px solid #bfdbfe; color: var(--primary-dark); transform: rotateY(180deg); font-weight: bold; }

.sortable-list { list-style: none; padding: 0; }
.sort-item { 
  background: #f8fafc; border: 1px solid #e2e8f0; padding: 12px 16px; margin-bottom: 8px; 
  border-radius: 8px; cursor: move; display: flex; align-items: center; gap: 10px;
}
.sort-item::before { content: '☰'; color: #94a3b8; }

.nav-area { display: flex; justify-content: space-between; margin-top: 32px; padding-top: 16px; border-top: 1px solid var(--border); }
.btn-nav { 
  padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: 600; 
  font-size: 14px; border: none; cursor: pointer; transition: transform 0.3s, box-shadow 0.3s, background 0.3s;
}
.btn-nav:hover { transform: translateY(-1px); }
.btn-nav:active { transform: scale(0.98); }
.btn-nav.pri { background: var(--primary); color: white; box-shadow: 0 4px 6px -1px rgba(37,99,235,0.3); }
.btn-nav.sec { background: white; border: 1px solid #e2e8f0; color: #334155; }
.btn-nav.success { background: var(--success); color: white; }

.btn-primary { 
  display: inline-flex; align-items: center; gap: 6px;
  background: #3B82F6; color: #ffffff; border: none; border-radius: 10px;
  padding: 10px 14px; font-weight: 600; font-size: 13px; cursor: pointer;
  transition: background 0.3s, transform 0.3s, box-shadow 0.3s;
}
.btn-primary:hover { background: #2563EB; transform: translateY(-1px); box-shadow: 0 8px 16px rgba(59,130,246,0.3); }

.badge-row { display: flex; gap: 12px; }
.badge {
  width: 44px; height: 44px; border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  background: #e2e8f0; color: #94a3b8; font-size: 18px;
  transition: transform 0.3s, box-shadow 0.3s, background 0.3s, color 0.3s;
}
.badge.active {
  background: linear-gradient(135deg, #3B82F6, #8B5CF6); color: #ffffff;
  box-shadow: 0 10px 18px rgba(59,130,246,0.35);
  transform: translateY(-2px);
}

.magnetic { transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275); }

.confetti-layer {
  position: fixed; inset: 0; pointer-events: none; z-index: 999;
  overflow: hidden;
}
.confetti-piece {
  position: absolute; width: 8px; height: 12px; border-radius: 2px;
  opacity: 0.9; animation: confettiFall 1.4s ease-in forwards;
}

.page-wipe {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(90deg, rgba(59,130,246,0.0), rgba(59,130,246,0.12), rgba(59,130,246,0.0));
  transform: translateX(-120%); z-index: 998; pointer-events: none;
}
.page-wipe.active { animation: wipe 0.35s ease-in-out forwards; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes liquidFlow {
  0% { background-position: 0% 50%; }
  100% { background-position: 100% 50%; }
}

@keyframes confettiFall {
  0% { transform: translateY(-10vh) rotate(0deg); opacity: 0; }
  10% { opacity: 1; }
  100% { transform: translateY(100vh) rotate(320deg); opacity: 0; }
}

@keyframes wipe {
  0% { transform: translateX(-120%); }
  100% { transform: translateX(120%); }
}

/* Tabs */
.tabs-header { display: flex; gap: 10px; border-bottom: 2px solid #e2e8f0; margin-bottom: 20px; }
.tab-btn { background: none; border: none; padding: 10px 15px; cursor: pointer; font-weight: 600; color: #64748b; border-bottom: 2px solid transparent; margin-bottom: -2px; }
.tab-btn:hover { color: var(--primary); border-bottom-color: var(--primary); }

.panel-title { font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.6px; margin-bottom: 12px; display: flex; align-items: center; gap: 6px; }
.progress-card { background: #f1f5f9; padding: 16px; border-radius: 12px; }
.progress-track { height: 8px; background: #cbd5e1; border-radius: 4px; overflow: hidden; margin: 10px 0; }
.progress-fill { 
  height: 100%; 
  background: linear-gradient(90deg, #3B82F6, #60A5FA, #93C5FD); 
  background-size: 200% 100%;
  width: {{PROGRESS}}%; 
  transition: width 1s ease-out;
  animation: liquidFlow 2.4s linear infinite;
  box-shadow: 0 0 12px rgba(var(--halo-color), 0.25);
}

.widget-card { background: white; border: 1px solid var(--border); border-radius: 12px; padding: 16px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
.widget-title { font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 12px; display: flex; align-items: center; gap: 6px; }

.cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 6px; text-align: center; font-size: 11px; }
.cal-cell { width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; color: #475569; cursor: pointer; transition: background 0.3s, color 0.3s, box-shadow 0.3s; }
.cal-cell:hover { background: #e2e8f0; }
.cal-head { font-weight: bold; color: #94a3b8; font-size: 10px; cursor: default; }
.cal-head:hover { background: none; }
.cal-active { background: var(--primary); color: white; font-weight: bold; }
.cal-active:hover { background: var(--primary-dark); }
.cal-today { box-shadow: 0 0 0 2px #3B82F6; }

/* Widget: Chat/Mensajes */
.msg-list { display: flex; flex-direction: column; gap: 10px; max-height: 150px; overflow-y: auto; margin-bottom: 10px; }
.msg-bubble { background: #f1f5f9; padding: 8px 12px; border-radius: 8px; font-size: 12px; color: #334155; }
.msg-input-area { display: flex; gap: 6px; }
.msg-input { flex: 1; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px; font-size: 12px; }

/* Widget: Hitos */
.milestone { display: flex; align-items: center; gap: 12px; padding: 8px 0; border-bottom: 1px dashed #e2e8f0; }
.milestone:last-child { border-bottom: none; }
.ms-dot { width: 10px; height: 10px; background: var(--success); border-radius: 50%; box-shadow: 0 0 0 2px #d1fae5; }

.support-btn { 
  margin-top: 12px;
  display: inline-flex; align-items: center; justify-content: center; gap: 8px;
  padding: 10px 16px; border-radius: 999px; border: 1px solid #3B82F6; 
  background: #3B82F6; color: #ffffff; font-weight: 600; font-size: 13px;
  cursor: pointer; transition: transform 0.3s, box-shadow 0.3s, background 0.3s;
}
.support-btn:hover { transform: translateY(-2px); box-shadow: 0 10px 18px rgba(59,130,246,0.35); background: #2563EB; }

.layout.hide-left { grid-template-columns: 1fr 300px; }
.layout.hide-left .left-nav { display: none; }
.layout.hide-right { grid-template-columns: 260px 1fr; }
.layout.hide-right .right-panel { display: none; }

@media (max-width: 1100px) {
  .layout { grid-template-columns: 1fr; height: auto; }
  .left-nav, .right-panel { order: 2; }
  .center-content { order: 1; }
  body { overflow: auto; }
}
''';
