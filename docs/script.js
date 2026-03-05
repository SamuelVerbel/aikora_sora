document.addEventListener('DOMContentLoaded', () => {
  /* =========================================
     1. SCROLL SUAVE (Manejo de errores y offset)
     ========================================= */
  const smoothScrollLinks = document.querySelectorAll("a[href^='#']");
  
  smoothScrollLinks.forEach(anchor => {
    anchor.addEventListener("click", function(e) {
      const targetId = this.getAttribute("href");
      
      // Ignorar si el href es solo "#" o no existe
      if (targetId === "#" || !targetId) return;
      
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        e.preventDefault();
        
        // Compensar el alto del navbar fijo (aprox 70px)
        const headerOffset = 70;
        const elementPosition = targetElement.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
  
        window.scrollTo({
          top: offsetPosition,
          behavior: "smooth"
        });
      }
    });
  });

  /* =========================================
     2. NAVBAR DINÁMICA (Optimización de rendimiento)
     ========================================= */
  const nav = document.querySelector(".nav");
  let lastScrollY = window.scrollY;
  let ticking = false;

  // Usar requestAnimationFrame evita que el evento scroll sature el hilo principal
  window.addEventListener("scroll", () => {
    lastScrollY = window.scrollY;
    
    if (!ticking) {
      window.requestAnimationFrame(() => {
        if (nav) {
          if (lastScrollY > 40) {
            nav.classList.add("nav-scrolled");
          } else {
            nav.classList.remove("nav-scrolled");
          }
        }
        ticking = false;
      });
      ticking = true;
    }
  });

  /* =========================================
     3. REVEAL ANIMATION (Intersection Observer optimizado)
     ========================================= */
  const revealElements = document.querySelectorAll(
    ".feature-card, .screen-card, .step, .tech-card, .roadmap-column" // Añadí roadmap
  );

  // Configuración del observador: el margen evita que la animación se dispare demasiado tarde
  const observerOptions = {
    root: null,
    rootMargin: '0px 0px -50px 0px', // Dispara un poco antes de que llegue al borde
    threshold: 0.1 // Dispara cuando el 10% del elemento es visible
  };

  const observer = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Añade la clase que dispara la transición en CSS
        entry.target.classList.add("reveal");
        // Deja de observar el elemento una vez animado para ahorrar recursos
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  revealElements.forEach(el => observer.observe(el));
});
