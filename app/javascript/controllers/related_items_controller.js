import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { date: String };
  static targets = ["button", "modal", "results"];

  async search() {
    this.buttonTarget.disabled = true;
    this.buttonTarget.textContent = "検索中...";

    try {
      const response = await fetch(
        `/daily_logs/${this.dateValue}/find_related`,
        {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
              .content,
            "Content-Type": "application/json",
          },
        },
      );

      const data = await response.json();
      this.showResults(data.results);
    } catch (error) {
      this.resultsTarget.innerHTML = "<p>エラーが発生しました</p>";
      this.modalTarget.style.display = "block";
    } finally {
      this.buttonTarget.disabled = false;
      this.buttonTarget.textContent = "関連を探す";
    }
  }

  showResults(results) {
    if (results.length === 0) {
      this.resultsTarget.innerHTML =
        "<p>関連する過去の投稿が見つかりませんでした</p>";
    } else {
      this.resultsTarget.innerHTML = results
        .map(
          (r) => `
        <div>
          <strong>${r.date}</strong>
          ${r.items.map((i) => `<p>[${i.category}] ${i.body}</p>`).join("")}
        </div>
      `,
        )
        .join("<hr>");
    }
    this.modalTarget.style.display = "block";
  }

  close() {
    this.modalTarget.style.display = "none";
  }
}
