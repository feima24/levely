import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggleButton"];

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

    this._syncButtonState();
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

    // スマホサイズ: 開閉どちらでもドロワーを閉じる（重ね表示を防ぐ）
    if (window.innerWidth < 800) {
      const drawer = document.querySelector(".search-drawer--open");
      if (drawer) {
        drawer.classList.remove("search-drawer--open");
        sessionStorage.setItem("searchDrawerOpen", "false");
        // ドロワーボタンの active を外す
        const drawerBtn = this.element.querySelector(
          '[data-search-drawer-target="toggleButton"]',
        );
        if (drawerBtn) drawerBtn.classList.remove("user-icon-btn--active");
      }
    }

    this._syncButtonState();
  }

  close() {
    if (window.innerWidth < 800) {
      this.element.classList.add("app-layout--sidebar-collapsed");
      sessionStorage.setItem("sidebarCollapsed", "true");
      this._syncButtonState();
    }
  }

  _syncButtonState() {
    if (!this.hasToggleButtonTarget) return;
    const isOpen = !this.element.classList.contains(
      "app-layout--sidebar-collapsed",
    );
    this.toggleButtonTarget.classList.toggle("user-icon-btn--active", isOpen);
    this.toggleButtonTarget.blur();
  }
}
