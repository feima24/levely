import "@hotwired/turbo-rails";
import "controllers";

function setupFlashes() {
  const flashes = document.querySelectorAll(".notice, .alert");
  flashes.forEach((el) => {
    if (el.dataset.flashSetup) return; // 二重実行防止
    el.dataset.flashSetup = "true";

    const btn = document.createElement("button");
    btn.textContent = "✕";
    btn.style.cssText =
      "float:right; background:none; border:none; color:inherit; cursor:pointer; font-size:1rem; padding:0 0 0 1rem;";
    btn.addEventListener("click", () => el.remove());
    el.prepend(btn);

    setTimeout(() => {
      el.style.transition = "opacity 0.5s";
      el.style.opacity = "0";
      setTimeout(() => el.remove(), 500);
    }, 10000);
  });
}

document.addEventListener("DOMContentLoaded", setupFlashes);
document.addEventListener("turbo:load", setupFlashes);
