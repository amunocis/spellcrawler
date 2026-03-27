# 📋 Resumen del Proyecto Spell-Crawler

> **Contexto de desarrollo**: Este documento sirve como referencia rápida para continuar el desarrollo después de cambiar de máquina. Contiene decisiones arquitectónicas, estado actual y próximos pasos.

---

## 1. Estado Actual del Proyecto

### ✅ Implementado (Fase 1 - Arquitectura Base)

| Sistema | Estado | Archivos Clave |
|---------|--------|----------------|
| **Registry** | ✅ Completo | `src/core/registry.lua` |
| **Event Bus** | ✅ Síncrono | `src/core/event_bus.lua` |
| **Input Manager** | ✅ Teclado/Mouse/Mando | `src/core/input_manager.lua` |
| **State Manager** | ✅ Menú/Hub/Dungeon | `src/core/state_manager.lua` |
| **Colisiones** | ✅ bump.lua integrado | `lib/bump.lua` |
| **ECS Básico** | ⚠️ Componentes definidos | `src/ecs/components/` |
| **Proyectiles** | ✅ Funcional | En `dungeon_state.lua` |
| **Cámara** | ✅ Sigue al jugador | En cada estado |

### 🎮 Game States Funcionales

1. **MenuState** (`src/states/menu_state.lua`)
   - Navegación con WASD/Flechas
   - Opciones: Nueva Partida, Cargar, Opciones, Salir

2. **HubState** (`src/states/hub_state.lua`)
   - Movimiento libre del jugador
   - 2 NPCs de prueba con indicadores de quest (punto amarillo)
   - Presiona E cerca de NPC para "interactuar" (imprime en consola)
   - ESPACIO para ir al dungeon (temporal para testing)

3. **DungeonState** (`src/states/dungeon_state.lua`)
   - Cuarto simple con paredes y obstáculos
   - Colisiones funcionando con bump.lua
   - Disparar proyectiles (aim con mouse o right stick)
   - Barras de HP y Mana en UI
   - ESC para volver al Hub

---

## 2. Arquitectura del Proyecto

### 🏗️ Patrón Registry (Inyección de Dependencias)

```lua
-- Único punto de acceso global
_G.Registry = Registry:new()

-- Registrar sistemas
_G.Registry:register('event_bus', EventBus:new())
_G.Registry:register('input', InputManager:new())

-- Recuperar en cualquier parte
local input = _G.Registry:get('input')
```

**¿Por qué?** Elimina dependencias globales directas. Todo pasa por el Registry.

### 📡 Event Bus

**Actualmente:** Síncrono (procesa inmediatamente)

```lua
local eventBus = _G.Registry:get('event_bus')

-- Suscribirse
local unsubscribe = eventBus:on('spell:cast', function(data) ... end)

-- Emitir
eventBus:emit('spell:cast', {type = 'chispa', x = 100, y = 200})
```

**Para cambiar a asíncrono:** Modificar solo `eventBus:emit()` para que use `queue()` en lugar de `_dispatch()` directo.

### 🎮 Input Manager

Abstrae completamente el dispositivo de entrada:

```lua
local input = _G.Registry:get('input')

-- Consultar acciones (no teclas)
if input:pressed('cast_spell') then ... end
if input:isDown('move_left') then ... end

-- Obtener vectores
local moveX, moveY = input:getMovementVector()  -- Normalizado
local aimX, aimY = input:getAimDirection(x, y)  -- Hacia mouse o right stick
```

**Mapeo actual (ver `setupDefaultMappings()`):**
- Movimiento: WASD / Flechas / Left Stick
- Disparar: ESPACIO / Click Izquierdo / Botón A
- Dash: LShift / Botón B
- Interactuar: E / Botón X
- Pausa: ESC / Start

### 🔄 Game State Machine

```lua
local stateManager = _G.Registry:get('state_manager')

-- Registrar estados disponibles
stateManager:register('menu', MenuState)
stateManager:register('dungeon', DungeonState)

-- Cambiar estado (llama exit() del actual, enter() del nuevo)
stateManager:switch('dungeon')
```

---

## 3. Estructura de Directorios

```
spellcrawler/
├── conf.lua                    # Configuración LÖVE 11.4
├── main.lua                    # Bootstrap: inicializa Registry y estados
├── lib/
│   ├── bump.lua               # Colisiones AABB
│   └── hump/                  # gamestate, timer, camera, vector, signal
├── src/
│   ├── core/                  # Sistemas fundamentales
│   │   ├── registry.lua       # Inyección de dependencias
│   │   ├── event_bus.lua      # Comunicación desacoplada
│   │   ├── input_manager.lua  # Abstracción de input
│   │   └── state_manager.lua  # Máquina de estados
│   ├── states/                # Estados del juego
│   │   ├── menu_state.lua
│   │   ├── hub_state.lua
│   │   └── dungeon_state.lua
│   ├── ecs/                   # Entity Component System ligero
│   │   ├── components/        # Datos puros
│   │   │   ├── transform.lua  # x, y, rotation
│   │   │   ├── health.lua     # current, max
│   │   │   └── velocity.lua   # vx, vy, maxSpeed, friction
│   │   └── systems/           # Lógica que procesa componentes
│   │       └── movement_system.lua
│   └── utils/                 # Helpers
│       ├── math_utils.lua
│       └── table_utils.lua
├── assets/                    # (Vacío - recursos visuales/sonido)
├── data/                      # (Vacío - datos JSON/Lua de hechizos/enemigos)
└── docs/                      # Documentación
    ├── spellcrawler-gdd.md    # GDD original
    ├── sephiria.md            # Referencia de estilo
    ├── initial-content.md     # Lista de hechizos/enemigos planificados
    └── CONTEXT.md             # ESTE ARCHIVO
```

---

## 4. Decisiones Arquitectónicas Clave

### ECS: ¿Cómo implementarlo?

**Decisión:** Tablas Lua planas (no UUIDs ni entidades complejas)

```lua
-- Entidad = tabla simple con componentes
local player = {
    transform = Transform:new(100, 200),
    velocity = Velocity:new(0, 0, 300),
    health = Health:new(100),
    -- collider opcional para bump
    collider = {w = 20, h = 20, offsetX = -10, offsetY = -10}
}

-- Sistema procesa entidades que tienen los componentes necesarios
movementSystem:update(entities, dt)
```

**¿Por qué?** Más rápido en Lua, más fácil de debuggear.

### Colisiones: ¿bump es suficiente?

**Decisión:** bump.lua para todo + raycasting para proyectiles muy rápidos

**Implementación actual:** Cada entidad con collider se registra en `bump.newWorld()`. El mundo de colisiones es local a cada estado (Menu no tiene, Dungeon sí).

### Serialización: ¿Qué se guarda?

**Decisión:** Por ahora nada. Cada dungeon es nueva (roguelike puro).

**Futuro:** Guardar:
- Grimorio desbloqueado (hechizos conocidos)
- Bestiario (enemigos vistos)
- Meta-progresión (puntos para mejoras entre runs)
- Configuración y preferencias

### MVI: ¿Dónde aplica?

**Decisión:** Solo dentro del gameplay (DungeonState)

- **Model:** Tablas de entidades (posiciones, HP, etc.)
- **View:** Método `draw()` del estado
- **Intent:** Método `update()` + input → modifica model

Los estados de UI (Menu) no necesitan MVI completo.

---

## 5. Sistemas Pendientes (Por Prioridad)

### 🔥 ALTA PRIORIDAD - Core Loop

1. **Sistema de Hechizos Completo**
   - Definiciones de hechizos como datos (archivos en `data/spells/`)
   - Efectos modulares (daño, congelar, purificar, etc.)
   - Grimorio del jugador (qué hechizos conoce)
   - UI para seleccionar hechizos equipados

2. **Enemigos Básicos**
   - IA simple: persecución, patrulla, flee
   - Bestiario con stats
   - Sistema de spawn

3. **Generación Procedural del Dungeon**
   - Salas conectadas (no solo un cuarto)
   - Puertas/llaves
   - Tipos de sala: combate, tesoro, jefe

### ⚡ MEDIA PRIORIDAD - Polish

4. **Sistema de Misiones**
   - Definición de quests en `data/quests/`
   - NPCs que otorgan misiones
   - Condiciones de completado (obtener hechizo X, matar Y, etc.)
   - Recompensas

5. **UI Mejorada**
   - Dialog system para NPCs
   - Inventario/Grimorio visual
   - Menú de pausa con opciones

6. **Sistema de Daño y Efectos**
   - Tipos de daño (fuego, hielo, arcano)
   - Estados alterados (quemadura, congelado, silenciado)
   - Partículas/efectos visuales

### 🎨 BAJA PRIORIDAD - Contenido

7. **Meta-progresión**
   - Persistencia entre runs
   - Árbol de mejoras
   - Desbloqueos

8. **Sonido y Música**
   - Sistema de audio con buses (SFX, música, UI)
   - Efectos de sonido para hechizos
   - Música por estado

9. **Assets Visuales**
   - Sprites de personajes
   - Tilesets para dungeons
   - Animaciones

---

## 6. Próximos Pasos Sugeridos

### Opción A: Sistema de Hechizos (Recomendado)

Empezar definindo 3-4 hechizos básicos como datos:

```lua
-- data/spells/chispa.lua
return {
    id = 'chispa',
    name = 'Chispa',
    description = 'Proyectil básico de energía arcana',
    mana_cost = 5,
    cast_time = 0.2,
    effects = {
        {type = 'projectile', speed = 400, lifetime = 2},
        {type = 'damage', amount = 10, element = 'arcane'}
    }
}
```

Crear `SpellSystem` que:
- Lea definiciones
- Instancie proyectiles/effectos según el hechizo
- Consuma mana
- Maneje cooldowns

### Opción B: Enemigos

Crear `EnemyFactory` y 2 tipos básicos:
- **Murciélago**: Rápido, poco HP, melee
- **Golem**: Lento, mucho HP, requiere estrategia

### Opción C: Generación Procedural

Reemplazar el cuarto simple de DungeonState con:
- Algoritmo de generación de salas
- Conexiones entre salas (puertas)
- Spawn de enemigos por sala

---

## 7. Notas Técnicas

### LÖVE Versión
- Target: **11.4**
- Módulos desactivados: `physics` (usamos bump.lua)
- Módulos activados: `joystick`

### Convenciones de Código

1. **Módulos:** Siempre retornar tabla con métodos
2. **Clases/OOP:** Usar `__index` pattern de Lua
3. **Registry:** Prefijo `_G.` solo en main.lua, después usar variable local
4. **Eventos:** Usar formato `'sistema:acción'` (ej: `'spell:cast'`, `'entity:died'`)

### Debugging

```lua
-- Imprimir eventos en consola
local eventBus = _G.Registry:get('event_bus')
eventBus:on('*', function(event, data)
    print("[EVENT]", event, data)
end)
```

### Performance Consideraciones

- Máximo ~100 entidades con bump.lua (collisiones)
- Proyectiles destruirse automáticamente (no quedar en memoria)
- Pool de objetos para proyectiles si hay muchos (futuro)

---

## 8. Ideas de Diseño Pendientes

### Sistema de Magia Emergente

El GDD menciona que "Crear Café Frío" puede tener usos inesperados. ¿Cómo implementar esto?

**Opción 1: Tags y Reacciones**
- Hechizos tienen tags: `{'water', 'cold', 'liquid'}`
- Objetos del mundo reaccionan a tags: "objeto sucio + agua = limpio"

**Opción 2: Sistema de Propiedades Físicas**
- Hechizos cambian propiedades del entorno: temperatura, humedad, estado
- El mundo reacciona a cambios de propiedades

**Recomendación:** Empezar con Opción 1 (más simple), expandir a Opción 2.

### Contraste Visual

Del GDD:
- **Mundo:** Tonos apagados, grises, marrones, verdes profundos
- **Magia:** Neón vibrante (Cian #00FFFF, Violeta #FF00FF, Rojo #FF3333)

Implementación: shader simple o multiplicación de color en sprites de hechizos.

---

## 9. Recursos Útiles

### Librerías Incluidas (hump)
- `gamestate.lua` - Máquina de estados (alternativa a nuestro StateManager)
- `timer.lua` - Tweening y delayed callbacks
- `camera.lua` - Cámara con smooth follow
- `vector.lua` - Operaciones vectoriales 2D
- `signal.lua` - Otro sistema de eventos (no usado, tenemos el nuestro)

### Documentación Referencia
- bump.lua: https://github.com/kikito/bump.lua
- hump: https://hump.readthedocs.io/
- LÖVE Wiki: https://love2d.org/wiki/Main_Page

---

## 10. Comandos Útiles

```bash
# Ejecutar juego
love .

# Crear .love para distribuir
zip -9 -r spellcrawler.love . -x "*.git*" -x "*.md" -x "docs/*"

# Ver logs de LÖVE
love . --console
```

---

## Resumen Ejecutivo

**Tienes:** Arquitectura sólida con Registry, Event Bus, Input abstracto, y 3 estados navegables.

**Siguiente decisión:** ¿Por cuál sistema empezar?
1. Hechizos (core mechanic)
2. Enemigos (gameplay loop)
3. Generación procedural (replayability)

**Cada sistema está desacoplado.** Cambiar uno no afecta a los otros gracias al Registry y Event Bus.

---

*Última actualización: 2024-03-27*
*Commit inicial: 658975a*
