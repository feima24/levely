import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "content",
    "rankDisplay",
    "modal",
    "modalStatus",
    "goalInput1",
    "goalInput2",
    "goalInput3",
    "confirm",
    "confirmMessage",
    "confirmButtons",
  ];

  static values = {
    month: String,
    editable: Boolean,
    goal: Object,
  };

  connect() {
    this._render();
    document.addEventListener("keydown", this._handleKeydown);
  }

  disconnect() {
    document.removeEventListener("keydown", this._handleKeydown);
  }

  _render() {
    const goal = this.goalValue;
    if (!goal || !goal.goal1) {
      this._renderEmpty();
    } else {
      this._renderGoals(goal);
    }
  }

  _renderEmpty() {
    this.rankDisplayTarget.innerHTML = "";
    if (this.editableValue) {
      this.contentTarget.innerHTML =
        '<div class="quest-empty">' +
        '<p class="quest-empty-text">月間クエストが設定されていません</p>' +
        '<button class="quest-set-btn" data-action="click->monthly-goal#openModal">クエストを設定 ▶</button>' +
        "</div>";
    } else {
      this.contentTarget.innerHTML =
        '<p class="quest-empty-text">目標が設定されていません</p>';
    }
  }

  _renderGoals(goal) {
    const status = this._tierStatus(goal);
    const completedCount = [
      goal.completed1,
      goal.completed2,
      goal.completed3,
    ].filter(Boolean).length;

    let headerHtml = `<span class="quest-progress">${completedCount} / 3 攻略中</span>`;
    if (this.editableValue) {
      headerHtml +=
        '<button class="quest-edit-btn" data-action="click->monthly-goal#openModal">✎ 編集</button>';
    }
    this.rankDisplayTarget.innerHTML = headerHtml;

    const tiers = [
      {
        key: "gold",
        label: "GOLD QUEST",
        num: 3,
        text: goal.goal3,
        sub: "本気でいけば",
      },
      {
        key: "silver",
        label: "SILVER QUEST",
        num: 2,
        text: goal.goal2,
        sub: "あと一歩踏み込んだら",
      },
      {
        key: "bronze",
        label: "BRONZE QUEST",
        num: 1,
        text: goal.goal1,
        sub: "最低限ここまで",
      },
    ];

    let html = '<div class="quest-tiers">';
    for (const tier of tiers) {
      const st = status[tier.key];
      const clickable = this.editableValue;
      const action = clickable
        ? `data-action="click->monthly-goal#tierClick" data-goal-number="${tier.num}"`
        : "";
      const cursor = clickable ? "cursor:pointer;" : "";

      let badgeHtml = "";
      if (st === "cleared") {
        badgeHtml =
          '<span class="quest-badge quest-badge--cleared">✓ CLEARED</span>';
      } else if (st === "active") {
        badgeHtml =
          '<span class="quest-badge quest-badge--active">NOW PLAYING...</span>';
      } else {
        badgeHtml =
          '<span class="quest-badge quest-badge--locked">🔒 LOCKED</span>';
      }

      html +=
        `<div class="quest-tier quest-tier--${tier.key} quest-tier--${st}"` +
        ` style="${cursor}" ${action}>` +
        `<div class="quest-tier-medal quest-tier-medal--${tier.key}">` +
        `${tier.key[0].toUpperCase()}</div>` +
        '<div class="quest-tier-body">' +
        '<div class="quest-tier-header">' +
        `<span class="quest-tier-label">${tier.label}</span>` +
        badgeHtml +
        "</div>" +
        `<div class="quest-goal-text">${this._esc(tier.text)}</div>` +
        "</div></div>";
    }
    html += "</div>";

    this.contentTarget.innerHTML = html;
  }

  tierClick(event) {
    const num = parseInt(event.currentTarget.dataset.goalNumber);
    const goal = this.goalValue;
    const done = goal[`completed${num}`];

    if (done) {
      this._showConfirm(num, "この達成を取り消しますか？", true);
      return;
    }

    if (num === 1) {
      this._showConfirm(num, "この目標を達成しましたか？", true);
    } else if (!goal.completed1) {
      this._showConfirm(num, "まずは Bronze Quest をクリアしよう！", false);
    } else if (num === 3 && !goal.completed2) {
      this._showConfirm(num, "まずは Silver Quest をクリアしよう！", false);
    } else {
      this._showConfirm(num, "この目標を達成しましたか？", true);
    }
  }

  _showConfirm(num, message, showButtons) {
    this._pendingGoalNumber = num;
    this.confirmMessageTarget.textContent = message;
    this.confirmButtonsTarget.style.display = showButtons ? "flex" : "none";
    this.confirmTarget.style.display = "flex";
  }

  confirmYes() {
    const num = this._pendingGoalNumber;
    this.confirmTarget.style.display = "none";
    this._toggleGoal(num);
  }

  confirmCancel() {
    this.confirmTarget.style.display = "none";
  }

  confirmOverlayClick(event) {
    if (event.target === this.confirmTarget) {
      this.confirmTarget.style.display = "none";
    }
  }

  async _toggleGoal(num) {
    const field = `completed${num}`;
    const prev = this.goalValue[field];

    const updated = { ...this.goalValue, [field]: !prev };
    updated.rank = this._calcRank(updated);
    this.goalValue = updated;
    this._render();

    try {
      const res = await this._request(
        `/monthly_goals/${this.monthValue}/toggle`,
        "PATCH",
        { goal_number: num },
      );
      if (!res.ok) throw new Error();
      const data = await res.json();
      this.goalValue = data;
      this._render();
    } catch {
      this.goalValue = { ...updated, [field]: prev };
      this.goalValue.rank = this._calcRank(this.goalValue);
      this._render();
    }
  }

  openModal() {
    document.dispatchEvent(new CustomEvent("app:modal-open"));
    document.body.classList.add("modal-open");
    const goal = this.goalValue;
    if (goal && goal.goal1) {
      this.goalInput1Target.value = goal.goal1;
      this.goalInput2Target.value = goal.goal2;
      this.goalInput3Target.value = goal.goal3;
    } else {
      this.goalInput1Target.value = "";
      this.goalInput2Target.value = "";
      this.goalInput3Target.value = "";
    }
    this.modalStatusTarget.textContent = "";
    this.modalTarget.style.display = "flex";
    this.goalInput1Target.focus();
  }

  closeModal() {
    document.dispatchEvent(new CustomEvent("app:modal-close"));
    document.body.classList.remove("modal-open");
    this.modalTarget.style.display = "none";
  }

  async saveGoals() {
    const goal1 = this.goalInput1Target.value.trim();
    const goal2 = this.goalInput2Target.value.trim();
    const goal3 = this.goalInput3Target.value.trim();

    const allEmpty = !goal1 && !goal2 && !goal3;
    const allFilled = goal1 && goal2 && goal3;

    if (!allEmpty && !allFilled) {
      this.modalStatusTarget.textContent = "3つ全て入力してください";
      return;
    }

    const isNew = !this.goalValue || !this.goalValue.goal1;

    if (allEmpty) {
      if (isNew) {
        this.closeModal();
        return;
      }
      try {
        this.modalStatusTarget.textContent = "削除中...";
        const res = await this._request(
          `/monthly_goals/${this.monthValue}`,
          "DELETE",
        );
        if (!res.ok) {
          this.modalStatusTarget.textContent = "削除に失敗しました";
          return;
        }
        this.goalValue = {};
        this._render();
        this.closeModal();
      } catch {
        this.modalStatusTarget.textContent = "削除に失敗しました";
      }
      return;
    }

    const url = isNew ? "/monthly_goals" : `/monthly_goals/${this.monthValue}`;
    const method = isNew ? "POST" : "PATCH";
    const body = {
      month: this.monthValue,
      monthly_goal: { goal1, goal2, goal3 },
    };

    try {
      this.modalStatusTarget.textContent = "保存中...";
      const res = await this._request(url, method, body);
      if (!res.ok) {
        const err = await res.json();
        this.modalStatusTarget.textContent = err.errors?.join(", ") || "エラー";
        return;
      }
      const data = await res.json();
      this.goalValue = data;
      this._render();
      this.closeModal();
    } catch {
      this.modalStatusTarget.textContent = "保存に失敗しました";
    }
  }

  _calcRank(g) {
    if (g.completed1 && g.completed2 && g.completed3) return "gold";
    if (g.completed1 && g.completed2) return "silver";
    if (g.completed1) return "bronze";
    return "none";
  }

  _tierStatus(goal) {
    const c1 = goal.completed1;
    const c2 = goal.completed2;
    const c3 = goal.completed3;
    return {
      bronze: c1 ? "cleared" : "active",
      silver: c1 && c2 ? "cleared" : c1 ? "active" : "locked",
      gold: c1 && c2 && c3 ? "cleared" : c1 && c2 ? "active" : "locked",
    };
  }

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

  _esc(str) {
    const d = document.createElement("div");
    d.textContent = str;
    return d.innerHTML;
  }

  _handleKeydown = (e) => {
    if (e.key === "Escape") {
      this.confirmTarget.style.display = "none";
      this.closeModal();
    }
  };
}
