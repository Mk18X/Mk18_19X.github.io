/* 个人网站交互脚本：主题切换 + 移动端菜单 + 页脚年份 + 图片集展开收起 */
(function () {
  "use strict";

  // ---------- 主题（浅色 / 深色）----------
  var THEME_KEY = "site-theme";

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    var btn = document.querySelector(".theme-toggle");
    if (btn) {
      btn.textContent = theme === "dark" ? "☀️" : "🌙";
      btn.setAttribute(
        "aria-label",
        theme === "dark" ? "切换到浅色主题" : "切换到深色主题"
      );
    }
  }

  function initTheme() {
    var saved = null;
    try {
      saved = localStorage.getItem(THEME_KEY);
    } catch (e) {
      saved = null;
    }
    var prefersDark =
      window.matchMedia &&
      window.matchMedia("(prefers-color-scheme: dark)").matches;
    applyTheme(saved || (prefersDark ? "dark" : "light"));
  }

  function toggleTheme() {
    var current =
      document.documentElement.getAttribute("data-theme") || "light";
    var next = current === "dark" ? "light" : "dark";
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch (e) {
      /* localStorage 不可用时忽略 */
    }
    applyTheme(next);
  }

  // ---------- 移动端菜单 ----------
  function initNav() {
    var toggle = document.querySelector(".nav-toggle");
    var nav = document.querySelector(".nav");
    if (!toggle || !nav) return;

    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      toggle.textContent = open ? "✕" : "☰";
    });

    // 点击链接后自动收起
    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        nav.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
        toggle.textContent = "☰";
      });
    });
  }

  // ---------- 页脚年份 ----------
  function initYear() {
    var el = document.querySelector("[data-year]");
    if (el) el.textContent = String(new Date().getFullYear());
  }

  // ---------- Kigurumi 图片集：点击展开 / 收起 ----------
  function initGallery() {
    var toggle = document.querySelector("#gallery-toggle");
    var gallery = document.querySelector("#stack-gallery");
    if (!toggle || !gallery) return;

    toggle.addEventListener("click", function () {
      var expanded = gallery.classList.toggle("expanded");
      toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
      toggle.textContent = expanded ? "收起照片 ↑" : "查看全部照片 ↓";
      if (!expanded) {
        // 收起后页面变短，滚回图片集，避免用户“迷路”
        gallery.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    initTheme();
    initNav();
    initYear();
    initGallery();

    var themeBtn = document.querySelector(".theme-toggle");
    if (themeBtn) themeBtn.addEventListener("click", toggleTheme);
  });
})();
