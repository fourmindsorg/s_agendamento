// Toggle Sidebar
document.getElementById("sidebarToggle").addEventListener("click", function () {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebarOverlay");
  const topbar = document.querySelector(".topbar");

  if (window.innerWidth <= 768) {
    // Mobile
    sidebar.classList.toggle("show");
    overlay.classList.toggle("show");
  } else {
    // Desktop
    sidebar.classList.toggle("collapsed");

    // Atualizar posição da topbar
    if (topbar) {
      if (sidebar.classList.contains("collapsed")) {
        topbar.style.left = "var(--sidebar-collapsed-width)";
      } else {
        topbar.style.left = "var(--sidebar-width)";
      }
    }
  }
});

// Fechar sidebar no mobile ao clicar no overlay
document
  .getElementById("sidebarOverlay")
  .addEventListener("click", function () {
    document.getElementById("sidebar").classList.remove("show");
    this.classList.remove("show");
  });

// Ajustar topbar no redimensionamento da janela
window.addEventListener("resize", function () {
  const sidebar = document.getElementById("sidebar");
  const topbar = document.querySelector(".topbar");

  if (topbar) {
    if (window.innerWidth <= 768) {
      // Mobile - topbar sempre na posição 0
      topbar.style.left = "0";
    } else {
      // Desktop - ajustar baseado no estado do sidebar
      if (sidebar.classList.contains("collapsed")) {
        topbar.style.left = "var(--sidebar-collapsed-width)";
      } else {
        topbar.style.left = "var(--sidebar-width)";
      }
    }
  }
});

// Inicializar posição da topbar
document.addEventListener("DOMContentLoaded", function () {
  const sidebar = document.getElementById("sidebar");
  const topbar = document.querySelector(".topbar");

  if (topbar && sidebar) {
    if (window.innerWidth <= 768) {
      // Mobile - topbar sempre na posição 0
      topbar.style.left = "0";
    } else {
      // Desktop - posição inicial baseada no estado do sidebar
      if (sidebar.classList.contains("collapsed")) {
        topbar.style.left = "var(--sidebar-collapsed-width)";
      } else {
        topbar.style.left = "var(--sidebar-width)";
      }
    }
  }
});

// Função para alterar tema
function alterarTema(tema, event) {
  if (event) {
    event.preventDefault();
    event.stopPropagation();
  }

  fetch("/authentication/ajax/alterar-tema/", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "X-CSRFToken": getCookie("csrftoken"),
    },
    body: `tema=${tema}`,
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        location.reload();
      }
    })
    .catch((error) => console.error("Erro:", error));
}

// Função para alterar modo
function alterarModo(isDark) {
  const modo = isDark ? "dark" : "light";

  fetch("/authentication/ajax/alterar-modo/", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "X-CSRFToken": getCookie("csrftoken"),
    },
    body: `modo=${modo}`,
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        location.reload();
      }
    })
    .catch((error) => console.error("Erro:", error));
}

// Função para pegar CSRF token
function getCookie(name) {
  let cookieValue = null;
  if (document.cookie && document.cookie !== "") {
    const cookies = document.cookie.split(";");
    for (let i = 0; i < cookies.length; i++) {
      const cookie = cookies[i].trim();
      if (cookie.substring(0, name.length + 1) === name + "=") {
        cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
        break;
      }
    }
  }
  return cookieValue;
}

// Responsividade
window.addEventListener("resize", function () {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebarOverlay");

  if (window.innerWidth > 768) {
    sidebar.classList.remove("show");
    overlay.classList.remove("show");
  }
});
