# Documento de Referencia de Diseño (Estilo "Sephiria")

## 1. Premisa y Core Loop (El Ciclo de Juego)

**Género:** Action Rogue-lite.

**El "Twist" de Diseño:** A diferencia de muchos roguelikes donde escalas una mazmorra, aquí desciendes por una torre (el pueblo seguro está en la cima).

**Temática:** Protagonistas y NPCs son animales antropomórficos (en Sephiria eres un conejo). Mezcla un tono de fantasía con una sensación de aventura clásica.

**Core Loop:**
Explorar piso → Limpiar salas de enemigos → Recolectar botín (artefactos/tabletas) → Gestionar inventario para crear sinergias → Vencer al jefe → Morir/Volver a la cima → Meta-progresión → Repetir.

---

## 2. Estilo Gráfico y Perspectiva

**Cámara:** Top-Down 2D (Vista cenital). Similar a los Zelda clásicos de 2D, Enter the Gungeon o The Binding of Isaac.

**Arte:** Pixel art con estética cute (adorable) y colorida.

**Contraste:** La clave visual es el contraste entre los personajes adorables y el caos de un combate muy rápido, lleno de efectos visuales (VFX) de cortes, magia y proyectiles.

---

## 3. Combate y Controles

El combate no es estático; recompensa los reflejos y el posicionamiento.

**Ritmo:** Fast-paced (acción rápida) e intuitivo. Enfocado en enfrentamientos PvE (Jugador vs Entorno).

**Mecánicas Defensivas:**
- **Dash:** Esquiva rápida con marcos de invulnerabilidad
- **Sistema de bloqueo/parry:** Para desviar ataques

**Ofensiva:**
- Armas variadas que cambian el estilo de juego (ej. espadas gigantes para daño en área, ballestas para distancia, grimorios mágicos)
- Los ataques tienen mecánicas de "combo" que aumentan el daño

---

## 4. Generación Procedural

**Diseño de Niveles:** La torre está dividida en pisos o "Tiers" (Biomas). Cada vez que el jugador baja un piso, la disposición de las salas cambia.

**Tipos de Salas:** El algoritmo procedural conecta:
- Salas de combate (encierran al jugador hasta que elimina las hordas)
- Salas de tesoros
- Tiendas
- Salas de eventos NPC
- Sala del jefe al final del piso

**Escalado:** A medida que desciendes, los enemigos escalan en daño y salud, y aparecen variantes más complejas.

---

## 5. Sistema de Progresión e Inventario (El "Gancho" Principal)

Esta es el área donde Sephiria más brilla y donde deberías enfocar la lógica de tu IA:

### Inventory Management (Gestión de Inventario)
No solo recoges objetos, tienes que organizarlos.

### Reliquias, Artefactos y Tabletas
Existen decenas de ítems pasivos (ej. reliquias de escarcha, de quemadura).

### Sintetización / Combinación
Si el jugador encuentra artefactos iguales, estos se "combinan" (suben de nivel) dentro del inventario, liberando espacio y multiplicando sus efectos (ej. más daño crítico o multiplicar los combos de ataque).

### Builds Rotas
El objetivo del diseño es que el jugador, gestionando bien su inventario y combinando efectos elementales, logre crear builds absurdamente poderosas para derretir a los jefes.
