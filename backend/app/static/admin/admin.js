// ==========================================================================
// RETAILZA SUPER ADMIN CONTROL CENTER | TECHMASTERS INNOVATIONS
// Client Application Architecture & Reactive State
// ==========================================================================

const API_BASE = '/api';
let authToken = localStorage.getItem('retailza_admin_token') || null;
let currentShopsData = [];
let currentFilter = 'ALL';
let searchDebounce = null;

// Initialization on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
  localStorage.removeItem('retailza_admin_theme');
  document.documentElement.removeAttribute('data-theme');

  initLiveClock();
  initGlobalShortcuts();

  if (authToken) {
    verifySession();
  } else {
    showLoginModal();
  }
});

// Live IST Clock Ticker
function initLiveClock() {
  const clockEl = document.getElementById('liveClockDisplay');
  function tick() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('en-IN', {
      timeZone: 'Asia/Kolkata',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false
    });
    if (clockEl) clockEl.innerText = `${timeStr} IST`;
  }
  tick();
  setInterval(tick, 1000);
}

// Global Keyboard Shortcuts (Ctrl+K to search)
function initGlobalShortcuts() {
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      focusSearch();
    }
  });
}

function focusSearch() {
  switchTab('stores');
  const searchInput = document.getElementById('storeSearchInput');
  if (searchInput) {
    searchInput.focus();
    searchInput.select();
  }
}

// Toast Notification Engine
function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer') || document.body;
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${escapeHtml(message)}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Clipboard Copy Helper
function copyTextToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    showToast(`Copied ${text} to clipboard`);
  }).catch(() => {
    showToast(text);
  });
}

function copySupportEmail() {
  copyTextToClipboard('support@covenantnest.techmaster.space');
}

// ==========================================================================
// AUTHENTICATION & SESSION MANAGEMENT
// ==========================================================================

async function verifySession() {
  try {
    const res = await fetch(`${API_BASE}/admin/metrics`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    if (res.ok) {
      hideLoginModal();
      document.getElementById('commandSubnav').style.display = 'block';
      document.getElementById('mainDashboard').style.display = 'block';
      loadAllDashboardData();
    } else {
      handleLogout();
    }
  } catch (err) {
    handleLogout();
  }
}

function setLoginMode(mode) {
  const btnPass = document.getElementById('authTabPassword');
  const btnOtp = document.getElementById('authTabOtp');
  const formPass = document.getElementById('passwordLoginForm');
  const formOtp = document.getElementById('otpLoginForm');

  if (mode === 'password') {
    btnPass.classList.add('active');
    btnOtp.classList.remove('active');
    formPass.style.display = 'block';
    formOtp.style.display = 'none';
  } else {
    btnOtp.classList.add('active');
    btnPass.classList.remove('active');
    formOtp.style.display = 'block';
    formPass.style.display = 'none';
  }
}

function showLoginModal() {
  document.getElementById('loginModal').style.display = 'flex';
  document.getElementById('commandSubnav').style.display = 'none';
  document.getElementById('mainDashboard').style.display = 'none';
}

function hideLoginModal() {
  document.getElementById('loginModal').style.display = 'none';
}

function handleLogout() {
  localStorage.removeItem('retailza_admin_token');
  authToken = null;
  showLoginModal();
}

async function handlePasswordLogin(e) {
  e.preventDefault();
  const identifier = document.getElementById('loginIdentifier').value.trim();
  const password = document.getElementById('loginPassword').value;

  try {
    const res = await fetch(`${API_BASE}/auth/login-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier, password })
    });

    const data = await res.json();
    if (!res.ok) {
      showToast(data.detail || 'Login failed', 'error');
      return;
    }

    if (data.user?.role !== 'SUPER_ADMIN') {
      showToast('Access denied: Account is not a Super Admin', 'error');
      return;
    }

    authToken = data.access_token;
    localStorage.setItem('retailza_admin_token', authToken);

    updateUserDisplay(data.user);
    showToast('Signed in successfully');
    hideLoginModal();
    document.getElementById('commandSubnav').style.display = 'block';
    document.getElementById('mainDashboard').style.display = 'block';
    loadAllDashboardData();
  } catch (err) {
    showToast('Network error during login', 'error');
  }
}

async function requestAdminOtp() {
  const identifier = document.getElementById('otpIdentifier').value.trim();
  if (!identifier) {
    showToast('Please enter your email or mobile number', 'error');
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/auth/request-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier })
    });

    const data = await res.json();
    if (res.ok) {
      document.getElementById('otpInputGroup').style.display = 'block';
      document.getElementById('btnRequestOtp').style.display = 'none';
      document.getElementById('btnVerifyOtp').style.display = 'block';

      if (data.debug_otp) {
        document.getElementById('debugOtpHint').innerText = `Debug OTP: ${data.debug_otp}`;
        document.getElementById('otpCode').value = data.debug_otp;
      }
      showToast(data.message || 'OTP dispatched');
    } else {
      showToast(data.detail || 'Failed to request OTP', 'error');
    }
  } catch (err) {
    showToast('Network error while requesting OTP', 'error');
  }
}

async function handleOtpLogin(e) {
  e.preventDefault();
  const identifier = document.getElementById('otpIdentifier').value.trim();
  const otp_code = document.getElementById('otpCode').value.trim();

  try {
    const res = await fetch(`${API_BASE}/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier, otp_code })
    });

    const data = await res.json();
    if (!res.ok) {
      showToast(data.detail || 'OTP verification failed', 'error');
      return;
    }

    if (data.user?.role !== 'SUPER_ADMIN') {
      showToast('Access denied: Account is not a Super Admin', 'error');
      return;
    }

    authToken = data.access_token;
    localStorage.setItem('retailza_admin_token', authToken);

    updateUserDisplay(data.user);
    showToast('Verified and signed in successfully');
    hideLoginModal();
    document.getElementById('commandSubnav').style.display = 'block';
    document.getElementById('mainDashboard').style.display = 'block';
    loadAllDashboardData();
  } catch (err) {
    showToast('Network error while verifying OTP', 'error');
  }
}

function updateUserDisplay(user) {
  const email = user.email || user.mobile_number || 'Super Admin';
  const displayEl = document.getElementById('adminEmailDisplay');
  if (displayEl) displayEl.innerText = email;

  const avatarEl = document.getElementById('userAvatar');
  if (avatarEl) {
    const initials = email.substring(0, 2).toUpperCase();
    avatarEl.innerText = initials;
  }
}

// ==========================================================================
// TAB NAVIGATION
// ==========================================================================

function switchTab(tabId) {
  document.querySelectorAll('.nav-tab-item').forEach(btn => btn.classList.remove('active'));
  ['overview', 'stores', 'reminders', 'broadcast'].forEach(id => {
    const sec = document.getElementById(`tab-${id}`);
    if (sec) sec.style.display = 'none';
  });

  const activeBtn = document.getElementById(`tabBtn-${tabId}`);
  if (activeBtn) activeBtn.classList.add('active');

  const activeSec = document.getElementById(`tab-${tabId}`);
  if (activeSec) activeSec.style.display = 'block';

  if (tabId === 'stores') loadShops();
  if (tabId === 'reminders') loadReminders();
  if (tabId === 'broadcast') loadAnnouncements();
}

// ==========================================================================
// DATA FETCHING & METRICS ENGINE
// ==========================================================================

async function loadAllDashboardData() {
  await Promise.all([
    loadMetrics(),
    loadShops(false),
    loadAnnouncements()
  ]);
}

async function loadMetrics() {
  try {
    const res = await fetch(`${API_BASE}/admin/metrics`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    if (!res.ok) return;

    const data = await res.json();

    // Financials
    animateCounter('kpiRevenue', `₹${parseFloat(data.total_revenue).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`);
    animateCounter('kpiMRR', `₹${parseFloat(data.monthly_recurring_revenue).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`);
    animateCounter('kpiStores', data.total_shops);
    animateCounter('kpiActiveSubs', data.active_subscriptions);

    // Growth
    const todayEl = document.getElementById('kpiTodaySignups');
    if (todayEl) todayEl.innerText = data.new_registrations_today;
    const weekEl = document.getElementById('kpiWeekSignups');
    if (weekEl) weekEl.innerText = data.new_registrations_this_week;

    // Portfolio Status
    const statActive = document.getElementById('statActive');
    if (statActive) statActive.innerText = data.active_subscriptions;
    const statExpiring = document.getElementById('statExpiring');
    if (statExpiring) statExpiring.innerText = data.expiring_soon_subscriptions;
    const statExpired = document.getElementById('statExpired');
    if (statExpired) statExpired.innerText = data.expired_subscriptions;
    const statPending = document.getElementById('statPending');
    if (statPending) statPending.innerText = data.pending_subscriptions;

    // Badges in subnav
    const storesBadge = document.getElementById('tabStoresCount');
    if (storesBadge) storesBadge.innerText = data.total_shops;

    const expiringBadge = document.getElementById('tabExpiringCount');
    if (expiringBadge) expiringBadge.innerText = data.expiring_soon_subscriptions;

    // Multi-segment Bar Calculation
    const totalSubs = Math.max(1, (data.active_subscriptions + data.expiring_soon_subscriptions + data.expired_subscriptions + data.pending_subscriptions));
    const pctActive = Math.round((data.active_subscriptions / totalSubs) * 100);
    const pctExpiring = Math.round((data.expiring_soon_subscriptions / totalSubs) * 100);
    const pctExpired = Math.round((data.expired_subscriptions / totalSubs) * 100);
    const pctPending = 100 - (pctActive + pctExpiring + pctExpired);

    const barActive = document.getElementById('barSegActive');
    if (barActive) barActive.style.width = `${pctActive}%`;
    const barExpiring = document.getElementById('barSegExpiring');
    if (barExpiring) barExpiring.style.width = `${pctExpiring}%`;
    const barExpired = document.getElementById('barSegExpired');
    if (barExpired) barExpired.style.width = `${pctExpired}%`;
    const barPending = document.getElementById('barSegPending');
    if (barPending) barPending.style.width = `${pctPending}%`;

  } catch (err) {
    console.error('Failed to load metrics', err);
  }
}

function animateCounter(elementId, targetValue) {
  const el = document.getElementById(elementId);
  if (el) el.innerText = targetValue;
}

// ==========================================================================
// STORE DIRECTORY
// ==========================================================================

async function loadShops(renderTable = true) {
  try {
    const searchVal = document.getElementById('storeSearchInput')?.value || '';
    let url = `${API_BASE}/admin/shops?status_filter=${currentFilter}`;
    if (searchVal.trim()) {
      url += `&q=${encodeURIComponent(searchVal.trim())}`;
    }

    const res = await fetch(url, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    if (!res.ok) return;

    currentShopsData = await res.json();

    if (renderTable) {
      renderShopsTable();
    }
  } catch (err) {
    console.error('Failed to load shops', err);
  }
}

function renderShopsTable() {
  const tbody = document.getElementById('shopsTableBody');
  const countEl = document.getElementById('tableResultsCount');
  if (!tbody) return;

  if (currentShopsData.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="8" class="table-state-cell">
          No stores found matching the criteria.
        </td>
      </tr>
    `;
    if (countEl) countEl.innerText = 'Showing 0 stores';
    return;
  }

  tbody.innerHTML = currentShopsData.map(shop => {
    const statusClass = (shop.subscription_status || 'PENDING').toLowerCase();
    const expiryStr = shop.subscription_end_date 
      ? new Date(shop.subscription_end_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
      : 'N/A';
    const regStr = new Date(shop.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
    const contactDisplay = shop.mobile_number || shop.email || 'N/A';

    return `
      <tr>
        <td>
          <div class="store-name-cell">${escapeHtml(shop.shop_name)}</div>
          <div class="store-meta-cell">ID #${shop.id}</div>
        </td>
        <td>
          <div style="font-weight: 600; color: var(--text-main); font-size: 13px;">${escapeHtml(shop.owner_name)}</div>
          <div class="contact-pill-box" title="Click to copy" onclick="copyTextToClipboard('${contactDisplay}')">
            ${escapeHtml(contactDisplay)}
          </div>
        </td>
        <td>
          <div>${escapeHtml(shop.city || 'N/A')}</div>
          <div class="store-meta-cell">${escapeHtml(shop.state || 'India')}</div>
        </td>
        <td class="store-meta-cell">${regStr}</td>
        <td>
          <span class="badge-sub ${statusClass}">
            <span>●</span> ${shop.subscription_status}
          </span>
        </td>
        <td style="font-weight: 600;">${expiryStr}</td>
        <td>
          <div style="font-weight: 700; color: var(--text-main);">₹${parseFloat(shop.total_sales_amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</div>
          <div class="store-meta-cell">${shop.sales_count} sales</div>
        </td>
        <td style="text-align: right;">
          <div class="table-btn-group">
            <button class="btn-table-action extend" onclick="extendSubscriptionPrompt(${shop.id}, '${escapeHtml(shop.shop_name)}')">
              +30 Days
            </button>
            <button class="btn-table-action remind" onclick="sendReminderPrompt(${shop.id}, '${escapeHtml(shop.shop_name)}', 'WHATSAPP')">
              Remind
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');

  if (countEl) {
    countEl.innerText = `Showing ${currentShopsData.length} of ${currentShopsData.length} stores`;
  }
}

function handleSearchInput(e) {
  const val = e.target.value;
  const btnClear = document.getElementById('btnClearSearch');
  if (btnClear) btnClear.style.display = val ? 'block' : 'none';

  clearTimeout(searchDebounce);
  searchDebounce = setTimeout(() => {
    loadShops(true);
  }, 250);
}

function clearSearch() {
  const input = document.getElementById('storeSearchInput');
  if (input) input.value = '';
  document.getElementById('btnClearSearch').style.display = 'none';
  loadShops(true);
}

function setFilter(filter) {
  currentFilter = filter;
  document.querySelectorAll('.filter-pill').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('data-filter') === filter);
  });
  loadShops(true);
}

// ==========================================================================
// RENEWAL REMINDER ENGINE
// ==========================================================================

async function loadReminders() {
  const container = document.getElementById('remindersList');
  if (!container) return;

  const targetShops = currentShopsData.filter(s => 
    s.subscription_status === 'EXPIRING_SOON' || s.subscription_status === 'EXPIRED'
  );

  if (targetShops.length === 0) {
    container.innerHTML = `
      <div class="table-state-cell">
        <div style="font-size: 14px; font-weight: 600; color: var(--text-main);">All Store Licenses Active</div>
        <div style="color: var(--text-muted); margin-top: 4px;">No stores currently require renewal alerts.</div>
      </div>
    `;
    return;
  }

  container.innerHTML = targetShops.map(shop => {
    const isExpired = shop.subscription_status === 'EXPIRED';
    const urgencyClass = isExpired ? 'urgent' : 'warning';
    const expiryStr = shop.subscription_end_date 
      ? new Date(shop.subscription_end_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
      : 'N/A';

    return `
      <div class="reminder-card-item">
        <div class="reminder-info-col">
          <div class="reminder-store-name">${escapeHtml(shop.shop_name)}</div>
          <div class="reminder-detail-text">
            Owner: <strong>${escapeHtml(shop.owner_name)}</strong> • Contact: ${escapeHtml(shop.mobile_number || shop.email || 'N/A')} • Location: ${escapeHtml(shop.city || 'N/A')}
          </div>
          <div style="margin-top: 4px;">
            <span class="reminder-urgency-badge ${urgencyClass}">
              ${isExpired ? 'EXPIRED' : 'EXPIRING SOON'} • Due ${expiryStr}
            </span>
          </div>
        </div>

        <div class="reminder-actions-col">
          <button class="btn-dispatch-channel whatsapp" onclick="sendReminderPrompt(${shop.id}, '${escapeHtml(shop.shop_name)}', 'WHATSAPP')">
            <span>WhatsApp</span>
          </button>
          <button class="btn-dispatch-channel sms" onclick="sendReminderPrompt(${shop.id}, '${escapeHtml(shop.shop_name)}', 'SMS')">
            <span>SMS</span>
          </button>
          <button class="btn-table-action extend" onclick="extendSubscriptionPrompt(${shop.id}, '${escapeHtml(shop.shop_name)}')">
            <span>+30 Days</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

async function sendReminderPrompt(shopId, storeName, channel) {
  try {
    const res = await fetch(`${API_BASE}/admin/reminders/send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ shop_id: shopId, channel })
    });

    const data = await res.json();
    if (res.ok) {
      showToast(`Sent ${channel} reminder to ${storeName}`);
    } else {
      showToast(data.detail || 'Failed to dispatch reminder', 'error');
    }
  } catch (err) {
    showToast('Failed to dispatch reminder', 'error');
  }
}

async function sendBulkReminders() {
  const targetShops = currentShopsData.filter(s => 
    s.subscription_status === 'EXPIRING_SOON' || s.subscription_status === 'EXPIRED'
  );

  if (targetShops.length === 0) {
    showToast('No expiring stores to send reminders to');
    return;
  }

  showToast(`Dispatching reminders to ${targetShops.length} stores...`);
  for (const s of targetShops) {
    await sendReminderPrompt(s.id, s.shop_name, 'WHATSAPP');
  }
  showToast('Bulk reminders dispatched successfully');
}

async function extendSubscriptionPrompt(shopId, storeName) {
  const days = prompt(`Extend subscription for ${storeName} by how many days?`, '30');
  if (!days || isNaN(days)) return;

  try {
    const res = await fetch(`${API_BASE}/admin/subscriptions/extend`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ shop_id: shopId, days: parseInt(days) })
    });

    const data = await res.json();
    if (res.ok) {
      showToast(`Extended ${storeName} subscription by ${days} days`);
      loadMetrics();
      loadShops(true);
    } else {
      showToast(data.detail || 'Extension failed', 'error');
    }
  } catch (err) {
    showToast('Network error while extending', 'error');
  }
}

// ==========================================================================
// BROADCAST ANNOUNCEMENTS
// ==========================================================================

async function handleCreateAnnouncement(e) {
  e.preventDefault();
  const title = document.getElementById('annTitle').value.trim();
  const tag = document.getElementById('annTag').value;
  const message = document.getElementById('annMessage').value.trim();
  const action_url = document.getElementById('annUrl').value.trim() || null;

  try {
    const res = await fetch(`${API_BASE}/admin/announcements`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ title, tag, message, action_url })
    });

    const data = await res.json();
    if (res.ok) {
      showToast('Announcement published successfully');
      document.getElementById('announcementForm').reset();
      loadAnnouncements();
    } else {
      showToast(data.detail || 'Failed to publish announcement', 'error');
    }
  } catch (err) {
    showToast('Network error while publishing', 'error');
  }
}

async function loadAnnouncements() {
  const listEl = document.getElementById('announcementsHistoryList');
  if (!listEl) return;

  try {
    const res = await fetch(`${API_BASE}/admin/announcements`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    if (!res.ok) return;

    const list = await res.json();
    if (list.length === 0) {
      listEl.innerHTML = '<div class="table-state-cell" style="padding: 16px !important;">No announcements published yet.</div>';
      return;
    }

    listEl.innerHTML = list.map(item => `
      <div class="announcement-history-item">
        <div>
          <div style="font-weight: 600; color: var(--text-main); font-size: 13px;">${escapeHtml(item.title)}</div>
          <div style="font-size: 12px; color: var(--text-secondary); margin-top: 4px;">${escapeHtml(item.message)}</div>
          <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">
            Category: <strong style="color: var(--primary);">${item.tag}</strong> • Published ${new Date(item.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
          </div>
        </div>
        <button class="btn-action-outline" style="padding: 4px 10px; font-size: 11px;" onclick="deleteAnnouncement(${item.id})">
          Delete
        </button>
      </div>
    `).join('');
  } catch (err) {
    console.error('Failed to load announcements', err);
  }
}

async function deleteAnnouncement(id) {
  if (!confirm('Are you sure you want to delete this announcement?')) return;

  try {
    const res = await fetch(`${API_BASE}/admin/announcements/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    if (res.ok) {
      showToast('Announcement removed');
      loadAnnouncements();
    } else {
      showToast(data.detail || 'Failed to delete announcement', 'error');
    }
  } catch (err) {
    showToast('Network error while deleting', 'error');
  }
}

// Utility: HTML Escaper
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
