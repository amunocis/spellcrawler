# 📜 Game Design Document: Spell-Crawler

## 1. Visión General
**Spell-Crawler** es un RPG Roguelike de exploración de mazmorras donde el progreso no está dictado por el nivel del personaje, sino por la **expansión y versatilidad de su Grimorio**. El jugador asume el papel de un hechicero en un mundo donde la magia es errática y valiosa, explorando entornos procedurales para recolectar hechizos que sirven tanto para el combate táctico como para la resolución creativa de problemas ambientales.

---

## 2. Pilares de Diseño
* **El Grimorio como Progresión:** Tu poder es tu biblioteca. No hay puntos de fuerza o agilidad; hay páginas nuevas con efectos únicos.
* **Conocimiento > Fuerza Bruta:** Sobrevivir requiere identificar amenazas antes de activarlas. El uso de hechizos de detección es tan vital como el de bolas de fuego.
* **Sistemas Emergentes:** Los hechizos interactúan con el entorno. Un hechizo de "Crear Café Frío" podría parecer inútil hasta que necesitas despertar a un guardia o enfriar una superficie.
* **Arquitectura como Cimiento:** El juego se diseña para ser modular. Cada hechizo, enemigo y trampa es una pieza independiente que encaja en un sistema global desacoplado.

---

## 3. Estilo Artístico y Atmosférico
* **Estética Visual:** Pixel Art de alta fidelidad con una resolución interna escalada para mantener la claridad táctica.
* **Paleta de Colores (Contraste Atmosférico):**
    * **Mundo (The Background):** Tonos apagados, monocromáticos o de bajo contraste (grises, marrones, verdes profundos) para transmitir un mundo antiguo y agotado.
    * **Magia y Peligro (The Highlight):** Colores neón y vibrantes (Cian arcano, Violeta místico, Rojo lava). La magia debe "romper" visualmente la realidad del mundo.
* **Interfaz de Usuario (UI):** Inspirada en clásicos pero modernizada. Salud mediante **Corazones** y energía mediante una barra de maná cristalina.

---

## 4. El Ciclo de Juego (Core Loop)
1.  **Hub (El Pueblo):** Gestión de hechizos, identificación de pergaminos, interacción con NPCs y selección de la próxima incursión.
2.  **Incursión (La Mazmorra):** Exploración por turnos en una grilla. Gestión de recursos (maná/salud) mientras se busca el "Hechizo Maestro" de la zona.
3.  **Extracción/Muerte:** Si el jugador sobrevive, asegura los hechizos encontrados. Si muere, el Grimorio se pierde (Muerte Permanente), pero el jugador conserva el conocimiento de las mecánicas.

---

## 5. Mecánicas Core

### 5.1 Sistema de Magia (Las 4 Ramas)
* **Combate Directo:** Proyectiles, áreas de efecto (AoE) y daño elemental.
* **Control y Alteración:** Muros de piedra, congelación, creación de zonas de silencio o gravedad.
* **Utilidad y Movimiento:** Teletransporte, levitación, reparación de objetos, visión a través de paredes.
* **Hechizos de Curiosidad ("Silly Spells"):** Hechizos con usos sociales o ambientales específicos (ej. "Lavar Ropa", "Marchitar Plantas", "Invocar Tostada").

### 5.2 Estructura del Mundo Procedural
* **Navegación:** Mapa interconectado de Pueblos (Hubs) que conectan con múltiples Mazmorras (Radios).
* **Puzzles Climáticos:** Los jefes finales no son sacos de HP, sino puzzles mecánicos que requieren el uso creativo de hechizos para ser derrotados.

---

## 6. Filosofía Arquitectónica (Technical Philosophy)
Para garantizar la estabilidad y escalabilidad en LÖVE, el desarrollo se rige por:

* **Flujo MVI (Model-View-Intent):**
    * **Model (Estado):** Datos puros (posiciones, HP, inventario).
    * **View (Render):** Renderizado pixel-perfect que solo lee el estado.
    * **Intent (Lógica):** Sistemas que procesan el input y los turnos para modificar el Modelo.
* **Patrón Registry:** Un sistema centralizado donde cada módulo (Hechizo, IA, Sonido) se registra para ser invocado sin dependencias circulares.
* **Física Ligera:** Uso de `bump.lua` para manejar la resolución de colisiones AABB, permitiendo que la lógica del juego se centre en la magia y no en la simulación física compleja.