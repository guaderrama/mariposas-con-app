<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>Controlador de Arte</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { touch-action: none; background-color: #111827; color: #E5E7EB; font-family: 'Poppins', sans-serif; display: flex; flex-direction: column; height: 100vh; margin: 0; overflow: hidden; }
        .header-container { display: flex; justify-content: space-between; align-items: center; padding: 10px 20px; background-color: rgba(0,0,0,0.2); width: 100%; flex-shrink: 0; }
        #clearBtn { background: none; border: 2px solid #4B5563; color: #9CA3AF; border-radius: 50%; width: 44px; height: 44px; cursor: pointer; transition: all 0.2s ease; display: flex; justify-content: center; align-items: center; }
        #clearBtn:hover, #clearBtn:active { border-color: #E5E7EB; color: #E5E7EB; transform: rotate(15deg); }
        #palette { display: flex; justify-content: center; align-items: center; gap: 15px; padding: 15px 20px; flex-wrap: wrap; }
        .color-box { width: 50px; height: 50px; border-radius: 50%; cursor: pointer; border: 4px solid transparent; transition: transform 0.2s, border-color 0.2s, box-shadow 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.3); }
        .color-box:hover { transform: scale(1.1); }
        .color-box.selected { border-color: #ffffff; transform: scale(1.15); box-shadow: 0 0 20px var(--glow-color, #fff); }
        #paint-area { width: 100%; flex-grow: 1; background: linear-gradient(180deg, rgba(17, 24, 39, 0) 0%, rgba(0,0,0,0.4) 100%), url('https://www.transparenttextures.com/patterns/stardust.png'); border-top: 1px solid #374151; display: flex; justify-content: center; align-items: center; text-align: center; }
        #paint-area p { font-size: 1.2rem; font-weight: 600; letter-spacing: 1px; text-shadow: 0 2px 5px rgba(0,0,0,0.5); pointer-events: none; }
    </style>
</head>
<body>
    <div class="header-container">
        <h1 class="text-2xl font-bold">Elige un Color</h1>
        <button id="clearBtn" title="Limpiar Lienzo">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18m-2 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m-6 5v6m4-6v6"/></svg>
        </button>
    </div>
    <div id="palette"></div>
    <div id="paint-area">
        <p>Toca y arrastra aquí para pintar</p>
    </div>

    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
        import { getFirestore, collection, addDoc, setLogLevel } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";
        import { getAuth, signInAnonymously } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

        // --- Configuración de Firebase (insertada directamente para pruebas) ---
        const firebaseConfig = {
          apiKey: "AIzaSyCz_du9pqA8Uye_Sgm4baekxg7ldqGRGko",
          authDomain: "instalacionmariposas.firebaseapp.com",
          projectId: "instalacionmariposas",
          storageBucket: "instalacionmariposas.appspot.com",
          messagingSenderId: "79329581996",
          appId: "1:79329581996:web:5d85cf82576073f05d3809"
        };
        const appId = firebaseConfig.appId;

        let strokesCollectionRef;
        let lastPaintTime = 0;
        let selectedColor;

        async function initializeFirebase() {
            try {
                const app = initializeApp(firebaseConfig);
                const db = getFirestore(app);
                const auth = getAuth(app);
                setLogLevel('debug');
                
                await signInAnonymously(auth);
                console.log("Controlador autenticado. UID:", auth.currentUser.uid);

                strokesCollectionRef = collection(db, `artifacts/${appId}/public/data/strokes`);
                console.log(`Controlador apuntando a: artifacts/${appId}/public/data/strokes`);

            } catch (error) {
                console.error("Fallo en la inicialización de Firebase (Controlador):", error);
                document.getElementById('paint-area').innerHTML = '<p class="text-red-500">Error de conexión</p>';
            }
        }

        function handlePaint(event) {
            event.preventDefault();
            const currentTime = Date.now();
            if (currentTime - lastPaintTime < 50) return;
            lastPaintTime = currentTime;

            if (!event.touches || event.touches.length === 0) return;
            const touch = event.touches[0];
            const x = touch.clientX / window.innerWidth;
            const y = touch.clientY / window.innerHeight;

            if (strokesCollectionRef) {
                addDoc(strokesCollectionRef, { x, y, color: selectedColor, timestamp: Date.now() })
                    .catch(error => console.error("Error al enviar trazo:", error));
            }
        }
        
        function handleClear() {
            if (strokesCollectionRef) {
                addDoc(strokesCollectionRef, { action: 'clear', timestamp: Date.now() })
                    .then(() => console.log("Comando de limpiar enviado."))
                    .catch(error => console.error("Error al enviar comando de limpiar:", error));
            }
        }

        // --- Lógica principal que se ejecuta cuando el DOM está listo ---
        document.addEventListener('DOMContentLoaded', () => {
            const paletteContainer = document.getElementById('palette');
            const paintArea = document.getElementById('paint-area');
            const clearBtn = document.getElementById('clearBtn');
            const colors = ['#EF4444', '#F97316', '#84CC16', '#22D3EE', '#3B82F6', '#A855F7', '#EC4899', '#FBBF24'];
            selectedColor = colors[0];

            colors.forEach(color => {
                const box = document.createElement('div');
                box.className = 'color-box';
                box.style.backgroundColor = color;
                box.style.setProperty('--glow-color', color);
                box.addEventListener('click', () => {
                    selectedColor = color;
                    document.querySelectorAll('.color-box').forEach(b => b.classList.remove('selected'));
                    box.classList.add('selected');
                });
                paletteContainer.appendChild(box);
            });
            if (paletteContainer.firstChild) {
                paletteContainer.firstChild.classList.add('selected');
            }

            paintArea.addEventListener('touchmove', handlePaint, { passive: false });
            paintArea.addEventListener('touchstart', handlePaint, { passive: false });
            clearBtn.addEventListener('click', handleClear);

            initializeFirebase();
        });
    </script>
</body>
</html>
