import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { date: String };

  connect() {
    this._timers = new Map();
  }

  disconnect() {
    this._timers.forEach((timer) => clearTimeout(timer));
    this._timers.clear();
  }

  schedule(event) {
    const row = event.target.closest("[data-autosave-row]");
    if (!row) return;
    const rowId = row.dataset.autosaveRow;
    clearTimeout(this._timers.get(rowId));
    this._setStatus(row, "入力中...");
    this._timers.set(
      rowId,
      setTimeout(() => this._save(row), 1000),
    );
  }

  addRow() {
    const template = this.element.querySelector("#new-row-template");
    const clone = template.content.cloneNode(true);
    const row = clone.querySelector("[data-autosave-row]");
    const uuid = crypto.randomUUID();
    row.dataset.autosaveRow = uuid;
    row.dataset.clientUuid = uuid;
    template.before(clone);
  }

  async destroy(event) {
    event.preventDefault();
    const row = event.target.closest("[data-autosave-row]");
    const itemId = row?.dataset.itemId;
    if (!itemId) {
      row.remove();
      return;
    }

    try {
      const res = await fetch(`/learning_items/${itemId}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": this._csrfToken() },
      });
      if (res.ok) row.remove();
      else this._setStatus(row, "削除エラー");
    } catch {
      this._setStatus(row, "通信エラー");
    }
  }

  async _save(row, force = false) {
    const body = this._buildBody(row, force);
    if (!body) return;

    const itemId = row.dataset.itemId;
    const url = itemId ? `/learning_items/${itemId}` : "/learning_items";
    const method = itemId ? "PATCH" : "POST";

    this._setStatus(row, "保存中...");
    try {
      const res = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this._csrfToken(),
        },
        body: JSON.stringify(body),
      });

      if (res.status === 409) {
        this._setConflictUI(row);
        return;
      }
      if (!res.ok) {
        const data = await res.json();
        this._setStatus(row, data.errors?.join(", ") || "エラー");
        return;
      }

      const data = await res.json();
      row.dataset.itemId = data.id;
      row.dataset.lockVersion = data.lock_version;
      this._setStatus(row, "保存済み");
    } catch {
      this._setStatus(row, "通信エラー");
    }
  }

  _buildBody(row, force = false) {
    const categoryName = row
      .querySelector("[data-field='category_name']")
      ?.value?.trim();
    if (!categoryName) return null;
    return {
      date: this.dateValue,
      force,
      learning_item: {
        category_name: categoryName,
        body_markdown:
          row.querySelector("[data-field='body_markdown']")?.value || "",
        duration_minutes:
          row.querySelector("[data-field='duration_minutes']")?.value || null,
        client_uuid: row.dataset.clientUuid,
        lock_version: parseInt(row.dataset.lockVersion) || 0,
      },
    };
  }

  _setStatus(row, message) {
    const el = row.querySelector("[data-autosave-status]");
    if (el) el.textContent = message;
  }

  _csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }

  async forceSave(event) {
    const row = event.target.closest("[data-autosave-row]");
    await this._save(row, true);
  }

  reloadPage() {
    location.reload();
  }

  _setConflictUI(row) {
    const el = row.querySelector("[data-autosave-status]");
    el.innerHTML = `
      別の場所で変更されています。
      <button data-action="click->autosave#forceSave">このまま保存</button>
      <button data-action="click->autosave#reloadPage">最新を読み込む</button>
    `;
  }
}
