import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "input", "results", "status", "summary"];

  connect() {
    if (sessionStorage.getItem("searchDrawerOpen") === "true") {
      this.panelTarget.classList.add("search-drawer--open");
      this._sidebarWasCollapsed = this.element.classList.contains(
        "app-layout--sidebar-collapsed",
      );
      if (window.innerWidth < 1200) {
        this.element.classList.add("app-layout--sidebar-collapsed");
      }
    }

    this.onMouseMove = this.onMouseMove.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);

    this._restoreResults();

    // モーダルと連動
    this._modalOpen = false;
    this._handleAppModalOpen = () => {
      this._modalOpen = true;
      this.close();
    };
    this._handleAppModalClose = () => {
      this._modalOpen = false;
    };
    document.addEventListener("app:modal-open", this._handleAppModalOpen);
    document.addEventListener("app:modal-close", this._handleAppModalClose);
  }

  disconnect() {
    document.removeEventListener("app:modal-open", this._handleAppModalOpen);
    document.removeEventListener("app:modal-close", this._handleAppModalClose);
  }

  toggle() {
    // モーダル中は無反応
    if (this._modalOpen) return;

    const isOpen = this.panelTarget.classList.toggle("search-drawer--open");
    sessionStorage.setItem("searchDrawerOpen", isOpen);
    if (isOpen) {
      this._sidebarWasCollapsed = this.element.classList.contains(
        "app-layout--sidebar-collapsed",
      );
      if (window.innerWidth < 1200) {
        this.element.classList.add("app-layout--sidebar-collapsed");
      }
      this.inputTarget.focus();
    } else {
      if (!this._sidebarWasCollapsed) {
        this.element.classList.remove("app-layout--sidebar-collapsed");
      }
      this.panelTarget.style.width = "";
    }
  }

  close() {
    this.panelTarget.classList.remove("search-drawer--open");
    sessionStorage.setItem("searchDrawerOpen", "false");
    this.panelTarget.style.width = "";
    if (!this._sidebarWasCollapsed) {
      this.element.classList.remove("app-layout--sidebar-collapsed");
    }
  }

  // ── リサイズ ──
  startResize(event) {
    event.preventDefault();
    this.dragging = true;
    this.panelTarget.style.transition = "none";
    document.body.style.userSelect = "none";
    document.body.style.cursor = "col-resize";
    document.addEventListener("mousemove", this.onMouseMove);
    document.addEventListener("mouseup", this.onMouseUp);
  }

  onMouseMove(event) {
    if (!this.dragging) return;
    const width = window.innerWidth - event.clientX;
    const maxWidth = Math.max(480, window.innerWidth - 600);
    const clamped = Math.max(280, Math.min(width, maxWidth));
    this.panelTarget.style.width = clamped + "px";
  }

  onMouseUp() {
    this.dragging = false;
    this.panelTarget.style.transition = "";
    document.body.style.userSelect = "";
    document.body.style.cursor = "";
    sessionStorage.setItem("searchDrawerWidth", this.panelTarget.style.width);
    document.removeEventListener("mousemove", this.onMouseMove);
    document.removeEventListener("mouseup", this.onMouseUp);
  }

  async search(event) {
    event.preventDefault();
    const query = this.inputTarget.value.trim();
    if (query.length < 2) {
      this.statusTarget.textContent = "2文字以上入力してください";
      this.resultsTarget.innerHTML = "";
      this.summaryTarget.innerHTML = "";
      return;
    }

    this.statusTarget.textContent = "検索中...";
    this.resultsTarget.innerHTML = "";
    this.summaryTarget.innerHTML = "";

    try {
      const response = await fetch("/semantic_search", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ query }),
      });

      const data = await response.json();
      if (!response.ok) {
        this.statusTarget.textContent = data.error || "エラーが発生しました";
        return;
      }

      if (data.results.length === 0) {
        this.statusTarget.textContent = "関連する記録が見つかりませんでした";
        return;
      }

      this.statusTarget.textContent = `${data.results.length}件の結果`;

      if (data.summary) {
        this.summaryTarget.innerHTML = this.summaryCard(data.summary);
      }

      this.resultsTarget.innerHTML = data.results
        .map((r) => this.resultCard(r))
        .join("");

      this._saveResults(query, data);
    } catch {
      this.statusTarget.textContent = "通信エラーが発生しました";
    }
  }

  summaryCard(summary) {
    return `<div class="search-summary-card">
      <div class="search-summary-label">まとめ</div>
      <div class="search-summary-text">${this.escapeHtml(summary)}</div>
    </div>`;
  }

  resultCard(log) {
    const items = log.items
      .map(
        (i) =>
          `<div class="search-result-item">
            <span class="search-result-category">[${this.escapeHtml(i.category || "未分類")}]</span>
            <span>${this.escapeHtml(i.body)}</span>
          </div>`,
      )
      .join("");

    const insights = log.insights
      ? `<div class="search-result-insights">${this.escapeHtml(log.insights)}</div>`
      : "";

    return `<a href="/monthlies/${this.escapeHtml(log.date.substring(0, 7))}?date=${this.escapeHtml(log.date)}" class="search-result-card">
      <div class="search-result-date">${this.escapeHtml(log.date)}</div>
      ${items}${insights}
    </a>`;
  }

  escapeHtml(text) {
    return String(text ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  _saveResults(query, data) {
    sessionStorage.setItem(
      "searchDrawerState",
      JSON.stringify({
        query,
        results: data.results,
        summary: data.summary,
        status: this.statusTarget.textContent,
      }),
    );
  }

  _restoreResults() {
    const saved = sessionStorage.getItem("searchDrawerState");
    if (!saved) return;

    const { query, results, summary, status } = JSON.parse(saved);
    this.inputTarget.value = query;
    this.statusTarget.textContent = status;

    if (summary) {
      this.summaryTarget.innerHTML = this.summaryCard(summary);
    }

    this.resultsTarget.innerHTML = results
      .map((r) => this.resultCard(r))
      .join("");
  }
}
