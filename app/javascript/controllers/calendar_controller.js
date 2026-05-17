import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "cell",
    "panel",
    "panelContent",
    "modal",
    "modalTitle",
    "modalRows",
    "modalStatus",
    "insightsInput",
    "rowTemplate",
  ];

  static values = {
    today: String,
    month: String,
    streak: Number,
    weeklyMinutes: Number,
    monthlyTotalMinutes: Number,
    categories: Array,
    categoryTotals: Array,
    todayData: Object,
  };

  connect() {
    this._deletedItemIds = [];
    this._buildCategoryColors();
    document.addEventListener("keydown", this._handleKeydown);

    const todayMonth = this.todayValue.slice(0, 7);
    if (this.monthValue === todayMonth) {
      this._selectedDate = this.todayValue;
      this._currentData = this.todayDataValue;
    }

    this._scrollArea = this.panelTarget.querySelector(".panel-scroll-area");
    if (this._scrollArea)
      this._scrollArea.addEventListener("scroll", this._onPanelScroll);

    requestAnimationFrame(() => {
      if (this._scrollArea) {
        const hasOverflow =
          this._scrollArea.scrollHeight > this._scrollArea.clientHeight;
        this._scrollArea.classList.toggle(
          "panel-scroll-area--has-overflow",
          hasOverflow,
        );
      }
    });
  }

  disconnect() {
    document.removeEventListener("keydown", this._handleKeydown);
    if (this._scrollArea)
      this._scrollArea.removeEventListener("scroll", this._onPanelScroll);
  }

  // ===== 日付選択 =====

  select(e) {
    e.preventDefault();
    const date = e.currentTarget.closest("[data-date]").dataset.date;
    if (!date) return;
    this._selectDate(date);
  }

  async _selectDate(date) {
    this.cellTargets.forEach((c) => c.classList.remove("selected"));
    const cell = this.cellTargets.find((c) => c.dataset.date === date);
    if (cell) cell.classList.add("selected");
    this._selectedDate = date;

    if (date === this.todayValue && !this._todayFetched) {
      this._currentData = this.todayDataValue;
      this._renderPanel(this._currentData);
    } else {
      await this._fetchDate(date);
    }
  }

  async _fetchDate(date) {
    this._setPanelLoading();
    try {
      const res = await fetch(`/daily_logs/${date}.json`);
      if (!res.ok) throw new Error();
      this._currentData = await res.json();
      if (date === this.todayValue) this._todayFetched = true;
      this._renderPanel(this._currentData);
    } catch {
      this.panelContentTarget.innerHTML =
        '<p class="panel-empty">読み込みエラー</p>';
    }
  }

  // ===== パネル描画 =====
  _renderPanel(data) {
    const items = data.learning_items || [];
    const insights = data.insights || "";
    const hasContent = items.length > 0 || insights;
    const btnLabel = hasContent ? "編集" : "＋ 作成";
    const btnText = hasContent
      ? `${this._formatDate(this._selectedDate)} の記録を編集する`
      : `${this._formatDate(this._selectedDate)} の記録を作成する`;
    let html = `<button class="panel-edit-btn" data-action="click->calendar#openModal">${btnText}</button>`;
    html += '<div class="panel-scroll-area">';

    if (items.length > 0) {
      html += '<div class="panel-items">';
      for (const item of items) {
        html += '<div class="panel-item">';
        html += '<div class="panel-item-header">';
        // カテゴリカラー
        const color = this._categoryColors[item.category_name] || "#ffd700";
        html += `<span class="panel-item-color" style="background:${color}"></span>`;
        html += `<span class="panel-item-category">${this._esc(item.category_name || "未分類")}</span>`;
        if (item.duration_minutes) {
          const h = Math.floor(item.duration_minutes / 60);
          const m = item.duration_minutes % 60;
          const time = h > 0 ? `${h}時間${m}分` : `${m}分`;
          html += `<span class="panel-item-duration">${time}</span>`;
        }
        html += "</div>";
        if (item.summary) {
          html += `<div class="panel-item-summary">${this._esc(item.summary)}</div>`;
        }
        html += "</div>";
      }
      html += "</div>";
    }

    if (insights) {
      html += '<div class="panel-insights-label">気づき</div>';
      html += `<div class="panel-insights">${this._esc(insights)}</div>`;
    }

    if (!hasContent) {
      html += '<p class="panel-empty">記録がありません</p>';
    }

    html += "</div>";
    this.panelContentTarget.innerHTML = html;

    const scrollArea =
      this.panelContentTarget.querySelector(".panel-scroll-area");
    this.panelTarget.scrollTop = 0;
    requestAnimationFrame(() => {
      if (scrollArea) {
        const hasOverflow = scrollArea.scrollHeight > scrollArea.clientHeight;
        scrollArea.classList.toggle(
          "panel-scroll-area--has-overflow",
          hasOverflow,
        );
      }
    });
  }

  _setPanelLoading() {
    this.panelContentTarget.innerHTML =
      '<p class="panel-loading">読み込み中...</p>';
  }

  // ===== モーダル =====
  openModal() {
    this.insightsInputTarget.readOnly = false;
    this.modalTarget.dataset.viewMode = "";
    this._deletedItemIds = [];
    this._populateModal(this._currentData || { learning_items: [] });
    this.modalTarget.style.display = "flex";
  }

  closeModal() {
    this.insightsInputTarget.readOnly = false;
    this.modalTarget.dataset.viewMode = "";
    this.modalTarget.style.display = "none";
    this._setModalStatus("");
  }

  addModalRow() {
    const clone = this.rowTemplateTarget.content.cloneNode(true);
    this.modalRowsTarget.appendChild(clone);
  }

  removeModalRow(e) {
    const row = e.target.closest(".modal-row");
    const itemId = row.dataset.itemId;
    if (itemId) this._deletedItemIds.push(itemId);
    row.remove();
  }

  async saveModal() {
    this._setModalStatus("保存中...");
    const date = this._selectedDate;

    try {
      await this._request(`/daily_logs/${date}`, "PATCH", {
        insights: this.insightsInputTarget.value,
      });

      for (const id of this._deletedItemIds) {
        await this._request(`/learning_items/${id}`, "DELETE");
      }

      const rows = this.modalRowsTarget.querySelectorAll(".modal-row");
      for (const row of rows) {
        await this._saveRow(row, date);
      }

      this._request(`/daily_logs/${date}/generate_embedding`, "POST");

      await this._fetchDate(date);
      this._updateDot(date);
      this.closeModal();
    } catch {
      this._setModalStatus("エラーが発生しました");
    }
  }

  _populateModal(data) {
    this.modalTitleTarget.textContent =
      this._formatDate(this._selectedDate) + "の記録";
    this.insightsInputTarget.value = data.insights || "";
    this.modalRowsTarget.innerHTML = "";

    for (const item of data.learning_items || []) {
      const clone = this.rowTemplateTarget.content.cloneNode(true);
      const row = clone.querySelector(".modal-row");
      row.dataset.itemId = item.id;
      row.dataset.lockVersion = item.lock_version;

      const catInput = row.querySelector("[data-field='category_name']");
      catInput.value = item.category_name || "";
      if (item.id) catInput.readOnly = true;

      row.querySelector("[data-field='summary']").value = item.summary || "";
      if (item.duration_minutes) {
        const h = Math.floor(item.duration_minutes / 60);
        const m = Math.round((item.duration_minutes % 60) / 5) * 5;
        row.querySelector("[data-field='duration_hours']").value = h;
        row.querySelector("[data-field='duration_minutes_part']").value = m;
      }

      this.modalRowsTarget.appendChild(clone);
    }
  }

  async _saveRow(row, date) {
    const summary = row.querySelector("[data-field='summary']")?.value || "";
    const categoryName = row
      .querySelector("[data-field='category_name']")
      ?.value?.trim();
    const hours =
      parseInt(row.querySelector("[data-field='duration_hours']")?.value) || 0;
    const mins =
      parseInt(
        row.querySelector("[data-field='duration_minutes_part']")?.value,
      ) || 0;
    const duration = hours * 60 + mins || null;

    if (!categoryName && !summary) return;

    const itemId = row.dataset.itemId;
    if (itemId) {
      await this._request(`/learning_items/${itemId}`, "PATCH", {
        learning_item: {
          summary,
          duration_minutes: duration,
          lock_version: parseInt(row.dataset.lockVersion) || 0,
        },
      });
    } else {
      await this._request("/learning_items", "POST", {
        date,
        learning_item: {
          category_name: categoryName,
          summary,
          duration_minutes: duration,
          client_uuid: crypto.randomUUID(),
        },
      });
    }
  }

  // ===== カテゴリーカラー =====
  _buildCategoryColors() {
    const totals = this.categoryTotalsValue;
    const colors = [
      "#ffd700",
      "#4caf50",
      "#ff6b6b",
      "#87ceeb",
      "#ff9800",
      "#ab47bc",
      "#26a69a",
      "#ef5350",
    ];
    this._categoryColors = {};
    (totals || []).forEach((t, i) => {
      this._categoryColors[t.name] = colors[i % colors.length];
    });
  }

  // ===== ドット更新 =====

  _updateDot(date) {
    const items = this._currentData?.learning_items || [];
    const cell = this.cellTargets.find((c) => c.dataset.date === date);
    if (!cell) return;

    const existing = cell.querySelector(".dot");
    if (items.length > 0) {
      const level = items.some((i) => i.duration_minutes)
        ? "dot--strong"
        : "dot--weak";
      if (existing) {
        existing.className = `dot ${level}`;
      } else {
        const dot = document.createElement("div");
        dot.className = `dot ${level}`;
        dot.dataset.dotDate = date;
        cell.appendChild(dot);
      }
    } else if (existing) {
      existing.remove();
    }
  }

  // ===== ユーティリティ =====

  async _request(url, method, body = null) {
    const opts = {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
    };
    if (body) opts.body = JSON.stringify(body);
    return fetch(url, opts);
  }

  _handleKeydown = (e) => {
    if (e.key === "Escape") this.closeModal();
  };

  _onPanelScroll = () => {
    const el =
      this._scrollArea || this.panelTarget.querySelector(".panel-scroll-area");
    if (!el) return;
    const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 8;
    el.classList.toggle("panel-scroll-area--scrolled-bottom", atBottom);
  };

  _formatDate(str) {
    const [y, m, d] = str.split("-");
    return `${y}/${m}/${d}`;
  }

  _esc(str) {
    const d = document.createElement("div");
    d.textContent = str;
    return d.innerHTML;
  }

  _setModalStatus(msg) {
    if (this.hasModalStatusTarget) this.modalStatusTarget.textContent = msg;
  }
}
