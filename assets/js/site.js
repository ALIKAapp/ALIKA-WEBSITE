// Shared site behaviour: mobile nav toggle + active-link highlighting.
document.addEventListener('DOMContentLoaded', () => {
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');
  if (toggle && links) {
    toggle.addEventListener('click', () => links.classList.toggle('open'));
    links.querySelectorAll('a').forEach((a) =>
      a.addEventListener('click', () => links.classList.remove('open'))
    );
  }

  const here = (location.pathname.split('/').pop() || 'index.html');
  document.querySelectorAll('.nav-links a[data-page]').forEach((a) => {
    if (a.getAttribute('data-page') === here) a.classList.add('active');
  });
});
