document.addEventListener('DOMContentLoaded', function () {
	// Add animation classes to elements
	const sections = document.querySelectorAll('section');
	sections.forEach(section => {
		section.classList.add('fade-in');
	});

	// Animation on scroll
	function checkVisibility() {
		const sections = document.querySelectorAll('.fade-in');
		sections.forEach(section => {
			const sectionTop = section.getBoundingClientRect().top;
			const windowHeight = window.innerHeight;

			if (sectionTop < windowHeight - 100) {
				section.classList.add('visible');
			}
		});
	}

	// Check visibility on load
	checkVisibility();

	// Check visibility on scroll
	window.addEventListener('scroll', checkVisibility);

	// Add current year to footer
	const footer = document.querySelector('footer p');
	const currentYear = new Date().getFullYear();
	footer.textContent = footer.textContent.replace('2025', currentYear);

	// Add click event to skills
	const skills = document.querySelectorAll('#skills-list li');
	skills.forEach(skill => {
		skill.addEventListener('click', function () {
			this.style.backgroundColor = getRandomColor();
		});
	});

	// Generate random color
	function getRandomColor() {
		const letters = '0123456789ABCDEF';
		let color = '#';
		for (let i = 0; i < 6; i++) {
			color += letters[Math.floor(Math.random() * 16)];
		}
		return color;
	}
});
