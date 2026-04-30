import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this._close = (e) => {
      if (!this.element.contains(e.target))
        this.element.removeAttribute("open");
    };
    document.addEventListener("click", this._close);
  }

  disconnect() {
    document.removeEventListener("click", this._close);
  }
}
