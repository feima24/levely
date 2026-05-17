import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (sessionStorage.getItem("sidebarCollapsed") === "true") {
      this.element.classList.add("app-layout--sidebar-collapsed");
    }

    const sidebar = this.element.querySelector(".sidebar");
    const main = this.element.querySelector(".main-content");
    if (sidebar && main) {
      this._wheelHandler = (e) => {
        main.scrollTop += e.deltaY;
      };
      sidebar.addEventListener("wheel", this._wheelHandler, { passive: true });
    }
  }

  disconnect() {
    const sidebar = this.element.querySelector(".sidebar");
    if (sidebar && this._wheelHandler) {
      sidebar.removeEventListener("wheel", this._wheelHandler);
    }
  }

  toggle() {
    const isCollapsed = this.element.classList.toggle(
      "app-layout--sidebar-collapsed",
    );
    sessionStorage.setItem("sidebarCollapsed", isCollapsed);
  }
}
