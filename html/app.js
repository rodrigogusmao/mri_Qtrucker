'use strict';

// ─── Estado ──────────────────────────────────────────────────────────────────
let state = {
    playerData:     null,
    routes:         [],
    companies:      {},
    cargo:          {},
    levels:         {},
    rentOptions:    [],
    hasRentedTruck: false,
    activeJob:      null,
    selectedRoute:  null,
    selectedCargo:  null,
    currentTab:     'dashboard',
    filterCompany:  'all',
};

// ─── Accent color (mri:color convar) ─────────────────────────────────────────
function applyAccentColor(hex) {
    if (!hex || !/^#[0-9a-fA-F]{6}$/.test(hex)) return;
    const r = parseInt(hex.slice(1,3),16)/255;
    const g = parseInt(hex.slice(3,5),16)/255;
    const b = parseInt(hex.slice(5,7),16)/255;
    const max = Math.max(r,g,b), min = Math.min(r,g,b);
    let h=0, s=0, l=(max+min)/2;
    if (max !== min) {
        const d = max-min;
        s = l > 0.5 ? d/(2-max-min) : d/(max+min);
        switch(max) {
            case r: h = ((g-b)/d + (g<b?6:0))/6; break;
            case g: h = ((b-r)/d + 2)/6; break;
            case b: h = ((r-g)/d + 4)/6; break;
        }
    }
    const hsl = `${Math.round(h*360)} ${Math.round(s*100)}% ${Math.round(l*100)}%`;
    document.documentElement.style.setProperty('--primary', hsl);
    document.documentElement.style.setProperty('--color-primary', hex);
    document.documentElement.style.setProperty('--ring', hsl);
}

// ─── NUI helpers ─────────────────────────────────────────────────────────────
function nuiPost(action, data = {}) {
    return fetch(`https://mri_Qtrucker/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────
function switchTab(tab) {
    state.currentTab = tab;
    document.querySelectorAll('.tab-section').forEach(s => s.classList.add('hidden'));
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.getElementById(`tab-${tab}`)?.classList.remove('hidden');
    document.querySelector(`[data-tab="${tab}"]`)?.classList.add('active');

    if (tab === 'history') renderHistory();
    if (tab === 'rent')    renderRentSection();
    if (tab === 'ranking') renderRanking();
}

// ─── Dashboard ───────────────────────────────────────────────────────────────
function renderDashboard() {
    const d = state.playerData;
    if (!d) return;

    const level     = d.level     || 1;
    const levelData = state.levels[level] || { label: 'Iniciante', multiplier: 1.0, color: '#9ca3af' };
    const xp        = d.xp        || 0;
    const progress  = d.xpProgress || 0;
    const xpNext    = d.xpToNextLevel || 0;

    // Top Rank Banner
    const topRankBanner = document.getElementById('top-rank-banner');
    if (topRankBanner) {
        if (d.rank && d.rankBuff && d.rank <= 3) {
            topRankBanner.classList.remove('hidden');
            document.getElementById('top-rank-pos').textContent = d.rank;
            document.getElementById('top-rank-buff').textContent = `+${Math.round((d.rankBuff - 1) * 100)}%`;
        } else {
            topRankBanner.classList.add('hidden');
        }
    }

    // Sidebar
    document.getElementById('sidebar-level-badge').textContent = `Nv. ${level}`;
    document.getElementById('sidebar-level-title').textContent = levelData.label;
    const xpFill = document.getElementById('sidebar-xp-fill');
    const xpText = document.getElementById('sidebar-xp-text');
    if (xpFill) xpFill.style.width = `${progress}%`;
    if (xpText) xpText.textContent = level < 10
        ? `${xp.toLocaleString('pt-BR')} / ${xpNext.toLocaleString('pt-BR')} XP`
        : 'Nível Máximo';

    // Profile card
    const profileLvl = document.getElementById('profile-level-num');
    profileLvl.textContent = level;
    profileLvl.style.color = levelData.color;
    document.getElementById('profile-level-label').textContent = levelData.label;
    document.getElementById('profile-xp').textContent = xp.toLocaleString('pt-BR');
    document.getElementById('profile-xp-next').textContent = xpNext.toLocaleString('pt-BR');
    document.getElementById('xp-fill').style.width = `${progress}%`;

    // Stats
    document.getElementById('stat-deliveries').textContent = d.total_deliveries || 0;
    document.getElementById('stat-earned').textContent     = formatMoney(d.total_earned || 0);
    document.getElementById('stat-xp').textContent         = (xp).toLocaleString('pt-BR');
    document.getElementById('stat-mult').textContent       = `x${levelData.multiplier.toFixed(1)}`;

    renderLevels(level);
    renderActiveJob();
}

function renderLevels(currentLevel) {
    const grid = document.getElementById('levels-grid');
    grid.innerHTML = '';
    Object.entries(state.levels).forEach(([lvl, data]) => {
        const l    = parseInt(lvl);
        const el   = document.createElement('div');
        el.className = 'level-item' + (l === currentLevel ? ' current' : l > currentLevel ? ' unlocked' : '');
        el.style.borderColor = l <= currentLevel ? data.color : '';
        el.innerHTML = `
            <div class="level-num" style="color:${data.color}">${l}</div>
            <div class="level-name">${data.label}</div>
            <div class="level-xp">${l > 1 ? (state.levels[l].xp / 1000).toFixed(1) + 'k XP' : '0 XP'}</div>
            <div class="level-mult">x${data.multiplier.toFixed(2)}</div>
        `;
        grid.appendChild(el);
    });
}

function renderActiveJob() {
    const card = document.getElementById('active-job-card');
    if (!state.activeJob) { card.classList.add('hidden'); return; }
    card.classList.remove('hidden');

    const route = state.routes.find(r => r.id === state.activeJob.routeId);
    const cargo = state.cargo[state.activeJob.cargoKey];
    const routeLabel = route ? route.label : `Rota ${state.activeJob.routeId}`;
    const cargoLabel = cargo ? cargo.label : state.activeJob.cargoKey;
    document.getElementById('active-job-info').textContent = `${cargoLabel} — ${routeLabel}`;
}

// ─── Aluguel de caminhão ──────────────────────────────────────────────────────
function applyRentState(hasRentedTruck) {
    state.hasRentedTruck = hasRentedTruck;

    // Card de devolução
    const card      = document.getElementById('return-card');
    const returnBtn = document.getElementById('btn-return-truck');
    const desc      = document.getElementById('return-card-desc');

    if (hasRentedTruck) {
        card.classList.add('has-truck');
        returnBtn.disabled = false;
        desc.textContent = 'Você possui um caminhão alugado. Clique para devolvê-lo.';
    } else {
        card.classList.remove('has-truck');
        returnBtn.disabled = true;
        desc.textContent = 'Nenhum caminhão alugado no momento.';
    }

    // Botões de aluguel desabilitados enquanto já tem caminhão
    document.querySelectorAll('.rent-btn').forEach(btn => {
        btn.disabled = hasRentedTruck;
        btn.style.opacity = hasRentedTruck ? '0.35' : '';
    });

    // Banner na aba de rotas
    const banner = document.getElementById('no-truck-banner');
    if (banner) banner.classList.toggle('hidden', hasRentedTruck);
}

function renderRentSection() {
    const list = document.getElementById('rent-trucks-list');
    list.innerHTML = '';

    if (!state.rentOptions.length) return;

    state.rentOptions.forEach(opt => {
        const el = document.createElement('div');
        el.className = 'rent-card';
        el.innerHTML = `
            <svg class="icon icon-rent" aria-hidden="true"><use href="#icon-truck"/></svg>
            <div class="rent-info">
                <div class="rent-name">${opt.label}</div>
                <div class="rent-desc">${opt.desc}</div>
            </div>
            <button class="btn-primary rent-btn" data-model="${opt.model}" data-price="${opt.price}">
                R$ ${opt.price.toLocaleString('pt-BR')}
            </button>
        `;
        el.querySelector('.rent-btn').addEventListener('click', () => {
            nuiPost('rentTruck', { model: opt.model, price: opt.price });
        });
        list.appendChild(el);
    });

    applyRentState(state.hasRentedTruck);
}

// ─── Rotas ───────────────────────────────────────────────────────────────────
function renderRoutes() {
    const list   = document.getElementById('route-list');
    const filter = state.filterCompany;
    list.innerHTML = '';

    const playerLevel = (state.playerData && state.playerData.level) || 1;

    state.routes
        .filter(r => filter === 'all' || r.company === filter)
        .forEach(route => {
            const company    = state.companies[route.company] || {};
            const isLocked   = playerLevel < (route.minLevel || 1);
            const stars      = '★'.repeat(route.difficulty || 1) + '☆'.repeat(Math.max(0, 4 - (route.difficulty || 1)));
            const payRange   = `R$ ${(route.basePay).toLocaleString('pt-BR')} – ${(Math.floor(route.basePay * 1.6)).toLocaleString('pt-BR')}`;

            const card = document.createElement('div');
            card.className = 'route-card' + (isLocked ? ' locked' : '');

            card.innerHTML = `
                <div class="route-company-tag" style="background:${company.color || '#555'}22;color:${company.color || '#aaa'};border:1px solid ${company.color || '#555'}55">
                    ${company.label || route.company}
                </div>
                <div class="route-info">
                    <div class="route-name">${route.label}</div>
                    <div class="route-meta">
                        <span>${route.origin.label}</span>
                        <span>→ ${route.destination.label}</span>
                        <span>${route.distance}</span>
                        <span>${route.timeLimit} min</span>
                        ${isLocked ? `<span style="color:#f87171;display:inline-flex;align-items:center;gap:3px"><svg class="icon icon-xs" aria-hidden="true"><use href="#icon-lock"/></svg> Nível ${route.minLevel}</span>` : ''}
                    </div>
                </div>
                <div class="route-right">
                    <div class="route-pay">${payRange}</div>
                    <div class="route-xp">+${route.baseXP} XP base</div>
                    <div class="difficulty-stars">${stars}</div>
                </div>
            `;

            if (!isLocked) {
                card.addEventListener('click', () => {
                    if (!state.hasRentedTruck) {
                        switchTab('rent');
                        return;
                    }
                    openCargoModal(route);
                });
            }
            list.appendChild(card);
        });

    if (list.children.length === 0) {
        list.innerHTML = '<div class="empty-state">Nenhuma rota disponível para este filtro.</div>';
    }
}

// ─── Modal de Carga ───────────────────────────────────────────────────────────
function openCargoModal(route) {
    state.selectedRoute = route;
    state.selectedCargo = null;

    document.getElementById('modal-route-name').textContent = route.label;
    document.getElementById('modal-start').disabled = true;

    const list = document.getElementById('cargo-list');
    list.innerHTML = '';

    const playerLevel = (state.playerData && state.playerData.level) || 1;

    route.allowedCargo.forEach(cargoKey => {
        const c = state.cargo[cargoKey];
        if (!c) return;
        const isLocked = playerLevel < (c.minLevel || 1);

        const el = document.createElement('div');
        el.className = 'cargo-item' + (isLocked ? ' locked' : '');
        el.innerHTML = `
            <div class="cargo-icon"><svg class="icon icon-cargo" aria-hidden="true"><use href="#icon-package"/></svg></div>
            <div class="cargo-info">
                <div class="cargo-name">${c.label}</div>
                <div class="cargo-meta">
                    ${c.fragile ? '<span class="cargo-fragile" style="display:inline-flex;align-items:center;gap:3px"><svg class="icon icon-xs" aria-hidden="true"><use href="#icon-alert-circle"/></svg> Frágil</span>' : ''}
                    ${c.timeSensitive ? '<span style="color:#fbbf24;font-size:10px;display:inline-flex;align-items:center;gap:3px"><svg class="icon icon-xs" aria-hidden="true"><use href="#icon-clock"/></svg> Tempo-sensitivo</span>' : ''}
                    ${isLocked ? `<span style="color:#f87171;font-size:10px;display:inline-flex;align-items:center;gap:3px"><svg class="icon icon-xs" aria-hidden="true"><use href="#icon-lock"/></svg> Nível ${c.minLevel}</span>` : ''}
                </div>
            </div>
            <div class="cargo-pay">R$ ${c.minPay.toLocaleString('pt-BR')} – ${c.maxPay.toLocaleString('pt-BR')}<br>
                <span style="font-size:10px;color:var(--text-muted)">+${c.baseXP} XP</span>
            </div>
        `;

        if (!isLocked) {
            el.addEventListener('click', () => {
                document.querySelectorAll('.cargo-item').forEach(x => x.classList.remove('selected'));
                el.classList.add('selected');
                state.selectedCargo = cargoKey;
                document.getElementById('modal-start').disabled = false;
            });
        }
        list.appendChild(el);
    });

    document.getElementById('cargo-modal').classList.remove('hidden');
}

function closeCargoModal() {
    document.getElementById('cargo-modal').classList.add('hidden');
    state.selectedRoute = null;
    state.selectedCargo = null;
}

// ─── Histórico ───────────────────────────────────────────────────────────────
function renderHistory() {
    const list    = document.getElementById('history-list');
    const history = (state.playerData && state.playerData.history) || [];
    list.innerHTML = '';

    if (!history.length) {
        list.innerHTML = '<div class="empty-state">Nenhuma entrega registrada ainda.</div>';
        return;
    }

    history.forEach(entry => {
        const condColor = entry.condition >= 80 ? '#2ea043' : entry.condition >= 50 ? '#f59e0b' : '#da3633';
        const el = document.createElement('div');
        el.className = 'history-item';
        el.innerHTML = `
            <div class="history-icon"><svg class="icon" aria-hidden="true"><use href="#icon-package"/></svg></div>
            <div class="history-info">
                <div class="history-route">${entry.route || '—'}</div>
                <div class="history-cargo">${entry.cargo || '—'} • Condição: <span style="color:${condColor}">${entry.condition || 0}%</span></div>
            </div>
            <div class="history-right">
                <div class="history-pay">+R$ ${(entry.pay || 0).toLocaleString('pt-BR')}</div>
                <div class="history-xp">+${entry.xp || 0} XP</div>
                <div class="history-date">${entry.date || ''}</div>
            </div>
        `;
        list.appendChild(el);
    });
}

// ─── Ranking ─────────────────────────────────────────────────────────────────
let currentRankingCategory = 'xp';

async function renderRanking() {
    const list = document.getElementById('ranking-list');
    list.innerHTML = '<div class="empty-state">Carregando ranking...</div>';

    try {
        const res = await nuiPost('getRanking', { category: currentRankingCategory });
        const ranking = await res.json();

        list.innerHTML = '';

        if (!ranking || !ranking.length) {
            list.innerHTML = '<div class="empty-state">Nenhum dado encontrado no ranking.</div>';
            return;
        }

        ranking.forEach((player, index) => {
            let metricHtml = '';
            
            if (currentRankingCategory === 'xp') {
                metricHtml = `
                    <div class="ranking-right">
                        <div class="ranking-level" style="font-size: 14px;">${player.xp} XP</div>
                    </div>`;
            } else if (currentRankingCategory === 'level') {
                metricHtml = `
                    <div class="ranking-right">
                        <div class="ranking-level" style="font-size: 14px;">Nível ${player.level}</div>
                    </div>`;
            } else if (currentRankingCategory === 'deliveries') {
                metricHtml = `
                    <div class="ranking-right">
                        <div class="ranking-level" style="font-size: 14px;">${player.total_deliveries} Entregas</div>
                    </div>`;
            }

            const el = document.createElement('div');
            el.className = 'ranking-item';
            el.innerHTML = `
                <div class="ranking-pos">#${index + 1}</div>
                <div class="ranking-icon"><svg class="icon" aria-hidden="true"><use href="#icon-trophy"/></svg></div>
                <div class="ranking-info">
                    <div class="ranking-name">${player.name}</div>
                </div>
                ${metricHtml}
            `;
            list.appendChild(el);
        });
    } catch (e) {
        list.innerHTML = '<div class="empty-state">Erro ao carregar o ranking.</div>';
    }
}

// ─── HUD ─────────────────────────────────────────────────────────────────────
function showHUD(data) {
    const hud = document.getElementById('job-hud');
    hud.classList.remove('hidden');
    document.getElementById('hud-route').textContent = data.route || '—';
    document.getElementById('hud-cargo').textContent = data.cargo || '—';
    updateHUD(data);
}

function updateHUD(data) {
    const cond    = data.condition ?? 100;
    const bar     = document.getElementById('hud-condition-bar');
    const valEl   = document.getElementById('hud-condition-val');
    const timeEl  = document.getElementById('hud-time');

    bar.style.width = `${cond}%`;
    bar.style.background = cond >= 70 ? 'var(--color-primary)'
                         : cond >= 40 ? '#fbbf24'
                         :              '#f87171';

    valEl.style.color = cond >= 70 ? 'var(--color-fg)'
                      : cond >= 40 ? '#fbbf24'
                      :              '#f87171';
    valEl.textContent = `${Math.floor(cond)}%`;

    timeEl.textContent = data.timeLeft || '--:--';
}

function hideHUD() {
    document.getElementById('job-hud').classList.add('hidden');
}

// ─── Formatação ───────────────────────────────────────────────────────────────
function formatMoney(val) {
    return 'R$ ' + Number(val).toLocaleString('pt-BR');
}

// ─── Mensagens do Lua ────────────────────────────────────────────────────────
window.addEventListener('message', e => {
    const { type, ...data } = e.data;

    if (type === 'show') {
        state.playerData  = data.playerData;
        state.routes      = data.routes      || [];
        state.companies   = data.companies   || {};
        state.cargo       = data.cargo       || {};
        state.levels      = data.levels      || {};
        state.rentOptions    = data.rentOptions    || [];
        state.hasRentedTruck = data.hasRentedTruck || false;
        state.activeJob      = data.activeJob      || null;

        if (data.accentColor) applyAccentColor(data.accentColor);

        document.getElementById('app').classList.remove('hidden');
        switchTab('dashboard');
        renderDashboard();
        renderRoutes();
        return;
    }

    if (type === 'hide') {
        document.getElementById('app').classList.add('hidden');
        closeCargoModal();
        return;
    }

    if (type === 'showHUD')   { showHUD(data);   return; }
    if (type === 'updateHUD') { updateHUD(data);  return; }
    if (type === 'hideHUD')   { hideHUD();        return; }

    if (type === 'updatePlayer') {
        state.playerData = data;
        if (state.currentTab === 'dashboard') renderDashboard();
        return;
    }

    if (type === 'updateRentState') {
        applyRentState(data.hasRentedTruck);
        return;
    }
});

// ─── Event Listeners ─────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {

    // Tema claro/escuro
    const themeToggle = document.getElementById('theme-toggle');
    const savedTheme  = localStorage.getItem('mri_trucker_theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
    themeToggle.addEventListener('click', () => {
        const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('mri_trucker_theme', next);
    });

    // Tabs
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', () => switchTab(btn.dataset.tab));
    });

    // Fechar
    document.getElementById('close-btn').addEventListener('click', () => {
        nuiPost('closeMenu');
    });

    document.getElementById('overlay').addEventListener('click', () => {
        nuiPost('closeMenu');
    });

    // Filtros de empresa
    document.querySelectorAll('.filter-btn:not(.ranking-filter-btn)').forEach(btn => {
        btn.addEventListener('click', () => {
            if (btn.id === 'btn-random-route') return;
            document.querySelectorAll('.filter-btn:not(.ranking-filter-btn):not(.filter-btn-random)').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            state.filterCompany = btn.dataset.company;
            renderRoutes();
        });
    });

    // Filtros de ranking
    document.querySelectorAll('.ranking-filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.ranking-filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentRankingCategory = btn.dataset.ranking;
            renderRanking();
        });
    });

    // Rota aleatória
    document.getElementById('btn-random-route').addEventListener('click', async () => {
        const level = (state.playerData && state.playerData.level) || 1;
        const res   = await nuiPost('randomRoute', { level });
        const route = await res.json();
        if (route && route.id) {
            openCargoModal(route);
        }
    });

    // Modal — cancelar
    document.getElementById('modal-cancel').addEventListener('click', closeCargoModal);

    // Modal — iniciar
    document.getElementById('modal-start').addEventListener('click', () => {
        if (!state.selectedRoute || !state.selectedCargo) return;
        const routeId  = state.selectedRoute.id;
        const cargoKey = state.selectedCargo;
        closeCargoModal();
        nuiPost('startJob', { routeId, cargoKey });
    });

    // Devolver caminhão alugado
    document.getElementById('btn-return-truck').addEventListener('click', () => {
        nuiPost('returnTruck');
    });

    // Banner de rotas → ir para aba de aluguel
    document.getElementById('btn-go-rent').addEventListener('click', () => {
        switchTab('rent');
    });

    // Cancelar rota ativa (dashboard)
    document.getElementById('btn-cancel-job-dash').addEventListener('click', () => {
        nuiPost('cancelJob');
    });

    // ESC fecha
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') nuiPost('closeMenu');
    });
});
