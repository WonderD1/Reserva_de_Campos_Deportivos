document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    const correoInput = document.getElementById('correo');
    const contrasenaInput = document.getElementById('contrasena');
    const togglePasswordBtn = document.getElementById('togglePassword');
    const eyeIcon = document.getElementById('eyeIcon');
    const alertBox = document.getElementById('alertBox');
    const loginBtn = document.getElementById('loginBtn');
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    const themeIcon = document.getElementById('themeIcon');
    const htmlElement = document.documentElement;

    // Theme Toggle
    themeToggleBtn.addEventListener('click', () => {
        const currentTheme = htmlElement.getAttribute('data-theme');
        if (currentTheme === 'light') {
            htmlElement.setAttribute('data-theme', 'dark');
            themeIcon.className = 'fa-solid fa-sun';
        } else {
            htmlElement.setAttribute('data-theme', 'light');
            themeIcon.className = 'fa-solid fa-moon';
        }
    });

    // Password Visibility Toggle
    togglePasswordBtn.addEventListener('click', () => {
        const type = contrasenaInput.getAttribute('type') === 'password' ? 'text' : 'password';
        contrasenaInput.setAttribute('type', type);
        if (type === 'text') {
            eyeIcon.className = 'fa-regular fa-eye-slash';
        } else {
            eyeIcon.className = 'fa-regular fa-eye';
        }
    });

    function showAlert(message, type = 'error') {
        alertBox.textContent = message;
        alertBox.className = `alert alert-${type}`;
        alertBox.style.display = 'block';
        alertBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        alertBox.style.display = 'none';

        const correo = correoInput.value.trim();
        const contrasena = contrasenaInput.value;

        if (!correo || !contrasena) {
            showAlert('Por favor, completa todos los campos.');
            return;
        }

        loginBtn.disabled = true;
        loginBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Iniciando sesión...';

        try {
            const response = await fetch('../../backend/api/login.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    Correo: correo,
                    ContrasenaHash: contrasena
                })
            });

            const data = await response.json();

            if (response.ok) {
                showAlert('¡Inicio de sesión exitoso! Redirigiendo...', 'success');
                localStorage.setItem('cliente', JSON.stringify(data.cliente));

                setTimeout(() => {
                    window.location.href = '../index.html'; 
                }, 1200);
            } else {
                showAlert(data.error || 'Credenciales inválidas o error en el servidor.');
                loginBtn.disabled = false;
                loginBtn.innerHTML = '<span>Iniciar sesión</span> <i class="fa-solid fa-arrow-right"></i>';
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Error de conexión con el servidor. Inténtalo de nuevo.');
            loginBtn.disabled = false;
            loginBtn.innerHTML = '<span>Iniciar sesión</span> <i class="fa-solid fa-arrow-right"></i>';
        }
    });
});
