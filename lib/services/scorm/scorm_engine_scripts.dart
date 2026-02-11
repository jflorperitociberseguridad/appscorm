class ScormEngineScripts {
  static String buildScripts(int progress) {
    return _premiumScripts.replaceAll('{{PROGRESS}}', progress.toString());
  }
}

const String _premiumScripts = '''
// --- LÓGICA JAVASCRIPT ---
var scormApi = null;
function findScormApi(win) {
  while (win) {
    if (win.API && typeof win.API.LMSInitialize === 'function') {
      return win.API;
    }
    if (win.parent && win.parent !== win) {
      win = win.parent;
    } else {
      break;
    }
  }
  return null;
}

function scormInitialize() {
  if (scormApi) return true;
  scormApi = findScormApi(window);
  if (!scormApi) return false;
  try {
    scormApi.LMSInitialize('');
    return true;
  } catch (e) {
    console.log('SCORM init error', e);
    return false;
  }
}

function scormSetValue(name, value) {
  if (!scormInitialize()) return;
  try {
    scormApi.LMSSetValue(name, value);
  } catch (e) {
    console.log('SCORM set error', e);
  }
}

function scormGetValue(name) {
  if (!scormInitialize()) return '';
  try {
    return scormApi.LMSGetValue(name);
  } catch (e) {
    console.log('SCORM get error', e);
    return '';
  }
}

function scormCommit() {
  if (!scormApi) return;
  try {
    scormApi.LMSCommit('');
  } catch (e) {
    console.log('SCORM commit error', e);
  }
}

var visitedBlocks = {};
function markBlockVisited(index) {
  if (visitedBlocks[index]) return;
  visitedBlocks[index] = true;
  if (!scormInitialize()) return;
  scormSetValue('cmi.core.lesson_status', 'incomplete');
  scormSetValue('cmi.core.lesson_location', 'block_' + (index + 1));
  scormCommit();
  launchConfetti(14);
  const totalBlocks = document.querySelectorAll('.block-wrap').length;
  if (Object.keys(visitedBlocks).length === totalBlocks) {
    launchConfetti(60);
  }
}

function buildBlockNav() {
  const list = document.getElementById('blockNav');
  if (!list) return;
  list.innerHTML = '';
  const blocks = document.querySelectorAll('.block-wrap');
  blocks.forEach((el, idx) => {
    const label = el.getAttribute('data-block-label') || ('Bloque ' + (idx + 1));
    const btn = document.createElement('button');
    btn.className = 'block-nav-btn';
    btn.textContent = (idx + 1) + '. ' + label;
    btn.setAttribute('data-block-index', idx);
    btn.onclick = function() {
      smoothScrollTo(el);
      markBlockVisited(idx);
      setActiveNav(idx);
    };
    list.appendChild(btn);
  });
  if (blocks.length > 0) {
    setActiveNav(0);
  }
}

function setHaloForBlock(block) {
  const container = document.querySelector('.center-content');
  if (!container || !block) {
    document.documentElement.style.setProperty('--halo-opacity', '0');
    return;
  }
  const rect = block.getBoundingClientRect();
  const cont = container.getBoundingClientRect();
  const x = ((rect.left + rect.width / 2 - cont.left) / cont.width) * 100;
  const y = ((rect.top + rect.height / 2 - cont.top) / cont.height) * 100;
  document.documentElement.style.setProperty('--halo-x', x.toFixed(2) + '%');
  document.documentElement.style.setProperty('--halo-y', y.toFixed(2) + '%');
  document.documentElement.style.setProperty('--halo-opacity', '0.03');
  const kind = block.getAttribute('data-block-kind') || 'info';
  const colors = {
    info: '59,130,246',
    media: '6,182,212',
    quiz: '139,92,246',
    process: '16,185,129'
  };
  document.documentElement.style.setProperty('--halo-color', colors[kind] || colors.info);
}

function setActiveNav(index) {
  const buttons = document.querySelectorAll('.block-nav-btn');
  buttons.forEach(btn => {
    const btnIndex = parseInt(btn.getAttribute('data-block-index') || '-1', 10);
    btn.classList.toggle('active', btnIndex === index);
  });
  const blocks = document.querySelectorAll('.block-wrap');
  let activeBlock = null;
  blocks.forEach(block => {
    const blockIndex = parseInt(block.getAttribute('data-block-index') || '-1', 10);
    const isActive = blockIndex === index;
    block.classList.toggle('active', isActive);
    block.classList.toggle('dimmed', !isActive);
    if (isActive) activeBlock = block;
  });
  setHaloForBlock(activeBlock);
}

function observeBlocks() {
  const blocks = document.querySelectorAll('.block-wrap');
  if (!('IntersectionObserver' in window) || blocks.length === 0) return;
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const idx = parseInt(entry.target.getAttribute('data-block-index') || '0', 10);
        markBlockVisited(idx);
        setActiveNav(idx);
      }
    });
  }, { threshold: 0.6 });
  blocks.forEach(block => observer.observe(block));
}

function applyStaggered() {
  const blocks = document.querySelectorAll('.block-wrap.staggered');
  blocks.forEach((block, idx) => {
    block.style.animationDelay = (idx * 80) + 'ms';
  });
}

function updateBadges(progress) {
  const badges = document.querySelectorAll('.badge');
  badges.forEach(badge => {
    const threshold = parseInt(badge.getAttribute('data-threshold') || '0', 10);
    badge.classList.toggle('active', progress >= threshold);
  });
}

function applyMagnetism(selector) {
  const elements = document.querySelectorAll(selector);
  elements.forEach(el => {
    el.classList.add('magnetic');
    el.addEventListener('mousemove', (e) => {
      const rect = el.getBoundingClientRect();
      const dx = e.clientX - (rect.left + rect.width / 2);
      const dy = e.clientY - (rect.top + rect.height / 2);
      const damp = 0.12;
      el.style.transform = 'translate(' + (dx * damp) + 'px,' + (dy * damp) + 'px)';
    });
    el.addEventListener('mouseleave', () => {
      el.style.transform = 'translate(0,0)';
    });
  });
}

function attachPatternParallax() {
  const container = document.querySelector('.center-content');
  if (!container) return;
  container.addEventListener('scroll', () => {
    const offset = container.scrollTop * 0.06;
    document.documentElement.style.setProperty('--pattern-offset', offset.toFixed(2));
  });
}

function navigateModule(href) {
  const wipe = document.getElementById('pageWipe');
  if (wipe) {
    wipe.classList.add('active');
  }
  setTimeout(() => {
    window.location.href = href;
  }, 220);
  return false;
}

function smoothScrollTo(target) {
  const container = document.querySelector('.center-content');
  if (!container) {
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    return;
  }
  const start = container.scrollTop;
  const targetOffset = target.getBoundingClientRect().top - container.getBoundingClientRect().top + start - 12;
  const distance = targetOffset - start;
  const duration = 520;
  const startTime = performance.now();
  const ease = (t) => 1 - Math.pow(1 - t, 3);
  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    container.scrollTop = start + distance * ease(progress);
    if (progress < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

function togglePanel(side) {
  const root = document.getElementById('layoutRoot');
  if (!root) return;
  if (side === 'left') {
    root.classList.toggle('hide-left');
  } else {
    root.classList.toggle('hide-right');
  }
}

// 1. Quiz Checker (Para bloques de evaluación)
function checkQuiz(id, correctIndices) {
  const inputs = document.getElementsByName('q-' + id);
  let selected = [];
  for(let i=0; i<inputs.length; i++) {
    if(inputs[i].checked) selected.push(i);
  }
  const fb = document.getElementById('fb-' + id);
  const isCorrect = JSON.stringify(selected.sort()) === JSON.stringify(correctIndices.sort());
  
  if(isCorrect) {
    launchConfetti(30);
    fb.innerHTML = '<div style="background:#dcfce7; color:#166534; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">✅ ¡Respuesta Correcta!</div>';
  } else {
    fb.innerHTML = '<div style="background:#fee2e2; color:#991b1b; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">❌ Respuesta Incorrecta.</div>';
  }
}

function checkFillBlanks(id) {
  const container = document.getElementById('fill-' + id);
  if (!container) return;
  const inputs = container.querySelectorAll('.blank-input');
  let correct = 0;
  inputs.forEach(input => {
    const answer = (input.getAttribute('data-answer') || '').trim().toLowerCase();
    const value = (input.value || '').trim().toLowerCase();
    if (answer && value && answer === value) {
      correct++;
      input.classList.remove('wrong');
      input.classList.add('right');
    } else {
      input.classList.remove('right');
      input.classList.add('wrong');
    }
  });
  const fb = document.getElementById('fb-' + id);
  const isCorrect = inputs.length > 0 && correct === inputs.length;
  if (fb) {
    fb.innerHTML = isCorrect
      ? '<div style="background:#dcfce7; color:#166534; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">✅ ¡Correcto!</div>'
      : '<div style="background:#fee2e2; color:#991b1b; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">❌ Revisa tus respuestas.</div>';
  }
}

function checkMatching(id) {
  const container = document.getElementById('match-' + id);
  if (!container) return;
  const selects = container.querySelectorAll('select');
  let correct = 0;
  let answered = 0;
  selects.forEach(sel => {
    const expected = sel.getAttribute('data-correct') || '';
    const value = sel.value || '';
    if (value) answered++;
    if (value && value === expected) correct++;
  });
  const fb = document.getElementById('fb-' + id);
  const isCorrect = selects.length > 0 && correct === selects.length;
  if (fb) {
    if (answered < selects.length) {
      fb.innerHTML = '<div style="background:#fff7ed; color:#9a3412; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">⚠️ Completa todas las relaciones.</div>';
    } else if (isCorrect) {
      fb.innerHTML = '<div style="background:#dcfce7; color:#166534; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">✅ ¡Todo correcto!</div>';
    } else {
      fb.innerHTML = '<div style="background:#fee2e2; color:#991b1b; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">❌ Algunas relaciones no son correctas.</div>';
    }
  }
}

function selectScenario(id, isCorrect, feedback) {
  const fb = document.getElementById('scenario-fb-' + id);
  if (fb) {
    fb.innerHTML = (isCorrect ? '✅ ' : '❌ ') + (feedback || '');
  }
}

// 3. Tab System
function openTab(blockId, index) {
   const contents = document.querySelectorAll('[id^="tab-' + blockId + '-"]');
   contents.forEach(c => c.style.display = 'none');
   document.getElementById('tab-' + blockId + '-' + index).style.display = 'block';
}

// 4. Calendar System (LocalStorage Persistence)
function toggleDay(el) {
   el.classList.toggle('cal-active');
   saveCalendar();
}

function saveCalendar() {
   const activeDays = [];
   document.querySelectorAll('.cal-active').forEach(el => {
      if(el.classList.contains('day')) activeDays.push(el.innerText);
   });
   localStorage.setItem('scorm_calendar', JSON.stringify(activeDays));
}

function loadCalendar() {
   const activeDays = JSON.parse(localStorage.getItem('scorm_calendar') || '[]');
   const allDays = document.querySelectorAll('.cal-cell.day');
   allDays.forEach(day => {
      if(activeDays.includes(day.innerText)) {
         day.classList.add('cal-active');
      }
   });
}

function highlightToday() {
  const today = new Date().getDate().toString();
  const allDays = document.querySelectorAll('.cal-cell.day');
  allDays.forEach(day => {
    if (day.innerText === today) {
      day.classList.add('cal-today');
    }
  });
}

// INIT
window.onload = function() {
  scormInitialize();
  if (scormApi) {
    const status = scormGetValue('cmi.core.lesson_status');
    const location = scormGetValue('cmi.core.lesson_location');
    if (!status) scormSetValue('cmi.core.lesson_status', 'incomplete');
    if (!location) scormSetValue('cmi.core.lesson_location', 'start');
    scormCommit();
  }
  buildBlockNav();
  observeBlocks();
  applyStaggered();
  // Cargar Calendario
  loadCalendar();
  highlightToday();
  updateBadges({{PROGRESS}});
  applyMagnetism('.support-btn, .btn-primary, .btn-nav, .panel-toggle');
  attachPatternParallax();
};
''';
