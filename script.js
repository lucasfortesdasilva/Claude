'use strict';

/* ===========================
   Navbar: scroll + mobile
   =========================== */
const navbar    = document.getElementById('navbar');
const navToggle = document.getElementById('navToggle');
const navLinks  = document.getElementById('navLinks');

// Add scrolled class to navbar when page is scrolled
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 20);
}, { passive: true });

// Mobile menu toggle
navToggle.addEventListener('click', () => {
  const isOpen = navToggle.classList.toggle('open');
  navLinks.classList.toggle('open', isOpen);
  document.body.style.overflow = isOpen ? 'hidden' : '';
  navToggle.setAttribute('aria-expanded', isOpen);
});

// Close mobile menu when a link is clicked
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navToggle.classList.remove('open');
    navLinks.classList.remove('open');
    document.body.style.overflow = '';
    navToggle.setAttribute('aria-expanded', 'false');
  });
});

/* ===========================
   Scroll reveal animation
   =========================== */
const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
);

// Add reveal class and observe relevant elements
const revealTargets = document.querySelectorAll(
  '.about__grid, .skill-card, .project-card, .contact__container'
);

revealTargets.forEach((el, i) => {
  el.classList.add('reveal');
  // Stagger cards slightly
  if (el.classList.contains('skill-card') || el.classList.contains('project-card')) {
    el.style.transitionDelay = `${(i % 4) * 0.08}s`;
  }
  revealObserver.observe(el);
});

/* ===========================
   Active nav link highlight
   =========================== */
const sections = document.querySelectorAll('section[id]');
const navAnchors = document.querySelectorAll('.nav__links a');

const sectionObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id');
        navAnchors.forEach(a => {
          a.style.color = a.getAttribute('href') === `#${id}`
            ? 'var(--color-accent)'
            : '';
        });
      }
    });
  },
  { threshold: 0.4 }
);

sections.forEach(s => sectionObserver.observe(s));

/* ===========================
   Smooth typing cursor in hero
   =========================== */
const greetingEl = document.querySelector('.hero__greeting');
if (greetingEl) {
  greetingEl.style.cursor = 'default';
}
