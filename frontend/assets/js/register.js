document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('registerForm');
    const nombresInput = document.getElementById('nombres');
    const apellidosInput = document.getElementById('apellidos');
    const dniInput = document.getElementById('dni');
    const telefonoInput = document.getElementById('telefono');
    const correoInput = document.getElementById('correo');
    const contrasenaInput = document.getElementById('contrasena');
    const termsCheck = document.getElementById('termsCheck');
    const togglePasswordBtn = document.getElementById('togglePassword');
    const eyeIcon = document.getElementById('eyeIcon');
    const alertBox = document.getElementById('alertBox');
    const registerBtn = document.getElementById('registerBtn');
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    const themeIcon = document.getElementById('themeIcon');
    const htmlElement = document.documentElement;

    if (htmlElement.getAttribute('data-theme') === 'dark') {
        themeIcon.className = 'fa-solid fa-sun';
    } else {
        themeIcon.className = 'fa-solid fa-moon';
    }

    themeToggleBtn.addEventListener('click', () => {
        const currentTheme = htmlElement.getAttribute('data-theme');
        if (currentTheme === 'light') {
            htmlElement.setAttribute('data-theme', 'dark');
            localStorage.setItem('theme', 'dark');
            themeIcon.className = 'fa-solid fa-sun';
        } else {
            htmlElement.setAttribute('data-theme', 'light');
            localStorage.setItem('theme', 'light');
            themeIcon.className = 'fa-solid fa-moon';
        }
    });

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

    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        alertBox.style.display = 'none';

        const nombres = nombresInput.value.trim();
        const apellidos = apellidosInput.value.trim();
        const dni = dniInput.value.trim();
        const telefono = telefonoInput.value.trim();
        const correo = correoInput.value.trim();
        const contrasena = contrasenaInput.value;

        if (!nombres || !apellidos || !dni || !telefono || !correo || !contrasena) {
            showAlert('Todos los campos son obligatorios.');
            return;
        }

        if (dni.length !== 8) {
            showAlert('El DNI debe tener exactamente 8 dígitos.');
            return;
        }

        if (telefono.length !== 9) {
            showAlert('El teléfono debe tener exactamente 9 dígitos.');
            return;
        }

        if (!termsCheck.checked) {
            showAlert('Debes aceptar los términos y condiciones.');
            return;
        }

        registerBtn.disabled = true;
        registerBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Registrando...';

        try {
            const response = await fetch('../../backend/api/register.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    DNI: dni,
                    Nombres: nombres,
                    Apellidos: apellidos,
                    Correo: correo,
                    Telefono: telefono,
                    ContrasenaHash: contrasena
                })
            });

            const data = await response.json();

            if (response.ok) {
                showAlert('¡Registro exitoso! Redirigiendo al inicio de sesión...', 'success');
                setTimeout(() => {
                    window.location.href = 'login.html';
                }, 1500);
            } else {
                showAlert(data.error || 'Error al registrar la cuenta.');
                registerBtn.disabled = false;
                registerBtn.innerHTML = '<span>Crear cuenta</span> <i class="fa-solid fa-arrow-right"></i>';
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Error de conexión con el servidor.');
            registerBtn.disabled = false;
            registerBtn.innerHTML = '<span>Crear cuenta</span> <i class="fa-solid fa-arrow-right"></i>';
        }
    });
});
