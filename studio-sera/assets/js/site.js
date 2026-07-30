/* Studio Sera — Interaktionen: Header-Zustand, Menü, Reveals, Akkordeon, Formular. */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------------------------------------------------------- Header */

  var header = document.querySelector(".header");

  if (header) {
    var onScroll = function () {
      header.classList.toggle("is-stuck", window.scrollY > 24);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });

    /* Panels mit data-header-tone schalten die Schriftfarbe des Headers um,
       solange sie den oberen Bildschirmrand füllen. */
    var toned = document.querySelectorAll("[data-header-tone]");
    if (toned.length && "IntersectionObserver" in window) {
      var toneObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              header.dataset.tone = entry.target.dataset.headerTone;
            }
          });
        },
        { rootMargin: "-" + (header.offsetHeight + 4) + "px 0px -85% 0px" }
      );
      toned.forEach(function (el) { toneObserver.observe(el); });
    }
  }

  /* ------------------------------------------------------------------ Menü */

  var drawer = document.querySelector(".drawer");
  var scrim = document.querySelector(".scrim");
  var openBtn = document.querySelector(".menu-btn");
  var closeBtn = document.querySelector(".drawer-close");
  var lastFocused = null;

  function setMenu(open) {
    if (!drawer || !scrim || !openBtn) return;
    drawer.classList.toggle("is-open", open);
    scrim.classList.toggle("is-open", open);
    drawer.setAttribute("aria-hidden", open ? "false" : "true");
    openBtn.setAttribute("aria-expanded", open ? "true" : "false");
    document.body.style.overflow = open ? "hidden" : "";

    if (open) {
      lastFocused = document.activeElement;
      if (closeBtn) closeBtn.focus();
    } else if (lastFocused) {
      lastFocused.focus();
    }
  }

  if (openBtn) openBtn.addEventListener("click", function () { setMenu(true); });
  if (closeBtn) closeBtn.addEventListener("click", function () { setMenu(false); });
  if (scrim) scrim.addEventListener("click", function () { setMenu(false); });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && drawer && drawer.classList.contains("is-open")) setMenu(false);
  });

  if (drawer) {
    drawer.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () { setMenu(false); });
    });

    /* Fokus im geöffneten Menü halten */
    drawer.addEventListener("keydown", function (e) {
      if (e.key !== "Tab" || !drawer.classList.contains("is-open")) return;
      var items = drawer.querySelectorAll("a[href], button:not([disabled])");
      if (!items.length) return;
      var first = items[0];
      var last = items[items.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    });
  }

  /* --------------------------------------------------------------- Reveals */

  var revealables = document.querySelectorAll("[data-reveal]");

  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealables.forEach(function (el) { el.classList.add("is-visible"); });
  } else {
    var revealObserver = new IntersectionObserver(
      function (entries, obs) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          obs.unobserve(entry.target);
        });
      },
      { threshold: 0.14, rootMargin: "0px 0px -8% 0px" }
    );
    revealables.forEach(function (el) { revealObserver.observe(el); });
  }

  /* ----------------------------------------------------------- Scroll-Cue */

  document.querySelectorAll("[data-scroll-next]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var current = btn.closest(".panel");
      var next = current && current.nextElementSibling;
      while (next && !next.classList.contains("panel")) next = next.nextElementSibling;
      if (next) next.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" });
    });
  });

  /* ------------------------------------------------------------ Akkordeon */

  document.querySelectorAll(".acc-trigger").forEach(function (trigger) {
    trigger.addEventListener("click", function () {
      var panel = document.getElementById(trigger.getAttribute("aria-controls"));
      var open = trigger.getAttribute("aria-expanded") === "true";
      trigger.setAttribute("aria-expanded", open ? "false" : "true");
      if (panel) panel.dataset.open = open ? "false" : "true";
    });
  });

  /* ------------------------------------------------------------- Formular */

  var form = document.querySelector("[data-contact-form]");

  if (form) {
    var status = form.querySelector(".form-status");

    /* Vorbelegung aus der URL, z. B. kontakt.html?talent=Fionaxhlr&anliegen=Presse */
    try {
      var params = new URLSearchParams(window.location.search);
      ["talent", "anliegen"].forEach(function (key) {
        var value = params.get(key);
        var field = form.elements[key];
        if (!value || !field) return;
        var match = Array.prototype.some.call(field.options || [], function (opt) {
          return opt.value.toLowerCase() === value.toLowerCase();
        });
        if (match) {
          field.value = Array.prototype.filter.call(field.options, function (opt) {
            return opt.value.toLowerCase() === value.toLowerCase();
          })[0].value;
        }
      });
    } catch (err) {
      /* URLSearchParams nicht verfügbar – Formular funktioniert trotzdem. */
    }

    var showError = function (field, message) {
      var wrapper = field.closest(".field") || field.closest(".consent");
      if (!wrapper) return;
      wrapper.classList.add("is-invalid");
      var slot = wrapper.querySelector(".field-error");
      if (slot) slot.textContent = message;
      field.setAttribute("aria-invalid", "true");
    };

    var clearError = function (field) {
      var wrapper = field.closest(".field") || field.closest(".consent");
      if (!wrapper) return;
      wrapper.classList.remove("is-invalid");
      var slot = wrapper.querySelector(".field-error");
      if (slot) slot.textContent = "";
      field.removeAttribute("aria-invalid");
    };

    form.querySelectorAll("input, select, textarea").forEach(function (field) {
      field.addEventListener("input", function () { clearError(field); });
    });

    form.addEventListener("submit", function (e) {
      e.preventDefault();

      var data = new FormData(form);
      var required = ["name", "unternehmen", "email", "anliegen", "nachricht"];
      var firstInvalid = null;

      required.forEach(function (key) {
        var field = form.elements[key];
        if (!field) return;
        var value = (data.get(key) || "").toString().trim();
        clearError(field);
        if (!value) {
          showError(field, "Bitte ausfüllen.");
          firstInvalid = firstInvalid || field;
        } else if (key === "email" && !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value)) {
          showError(field, "Bitte eine gültige E-Mail-Adresse angeben.");
          firstInvalid = firstInvalid || field;
        }
      });

      var consent = form.elements["datenschutz"];
      if (consent && !consent.checked) {
        showError(consent, "Bitte bestätigen, damit wir antworten dürfen.");
        firstInvalid = firstInvalid || consent;
      }

      if (firstInvalid) {
        firstInvalid.focus();
        return;
      }

      /* Statische Seite ohne Backend: die Anfrage wird als vorbereitete
         E-Mail geöffnet. Für einen echten Endpunkt (Formspree, eigener
         Server, …) genügt es, hier stattdessen zu `fetch()`en. */
      var lines = [
        "Name: " + data.get("name"),
        "Unternehmen / Agentur: " + data.get("unternehmen"),
        "E-Mail: " + data.get("email"),
        "Anliegen: " + data.get("anliegen"),
        "Talent: " + (data.get("talent") || "—"),
        "Budgetrahmen: " + (data.get("budget") || "—"),
        "Zeitraum: " + (data.get("zeitraum") || "—"),
        "",
        data.get("nachricht")
      ];

      var mailto =
        "mailto:" + (form.dataset.contactForm || "hallo@studiosera.de") +
        "?subject=" + encodeURIComponent("Anfrage über studiosera.de – " + data.get("anliegen")) +
        "&body=" + encodeURIComponent(lines.join("\n"));

      window.location.href = mailto;

      if (status) {
        status.textContent =
          "Danke. Dein E-Mail-Programm öffnet sich mit der fertigen Anfrage – " +
          "einmal senden, wir melden uns innerhalb von 48 Stunden.";
        status.classList.add("is-visible");
      }
    });
  }

  /* --------------------------------------------------------------- Jahr */

  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });
})();
