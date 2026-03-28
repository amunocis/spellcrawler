# 📋 Handover - Estado del Proyecto Spell-Crawler

> **Documento de transferencia para sesiones futuras de Kimi Code**
> 
> Este documento describe el estado ACTUAL del proyecto, lo que ya está implementado,
> y lo que falta por hacer. **Leer esto antes de empezar a trabajar.**

---

## 🎯 Resumen Ejecutivo (Estado Actual)

**Última actualización:** 2026-03-28  
**Tests:** 148/148 pasando ✅

### Sistema Core Completamente Funcional
- ✅ Arquitectura Clean con Registry, EventBus, InputManager, StateManager
- ✅ 3 Estados navegables: Menu → Hub → Dungeon
- ✅ Sistema de hechizos data-driven (archivos en `data/spells/`)
- ✅ Enemigos con IA (Murciélagos con chase, Golems con patrol)
- ✅ Combate funcional: proyectiles, daño, muerte, game over
- ✅ Feedback visual: partículas, flash de daño, cooldowns visuales
- ✅ Límites del mundo, spawn seguro, autofire

---

## ✅ Implementado (NO volver a hacer)

### Arquitectura Base
| Sistema | Estado | Archivos |
|---------|--------|----------|
| Registry (DI) | ✅ Completo | `src/core/registry.lua` |
| Event Bus | ✅ Síncrono | `src/core/event_bus.lua` |
| Input Manager | ✅ Teclado/Mouse/Gamepad Completo | `src/core/input_manager.lua` |
| State Manager | ✅ Completo | `src/core/state_manager.lua` |
| Colisiones | ✅ bump.lua integrado | `lib/bump.lua` |

### Game States
| Estado | Funcionalidad | Notas |
|--------|---------------|-------|
| **MenuState** | ✅ Navegación WASD/Flechas | 4 opciones: Nueva Partida, Cargar, Opciones, Salir |
| **HubState** | ✅ Movimiento + 2 NPCs | ESPACIO para ir al dungeon (testing) |
| **DungeonState** | ✅ Combate completo | Ver detalles abajo |

### Sistema de Hechizos (DATA-DRIVEN)
```
data/spells/
├── chispa.lua           # Daño 15, speed 400, cooldown 0.3s
├── dardo_magico.lua     # Daño 8, speed 600, cooldown 0.2s  
└── rafaga_viento.lua    # Daño 25, speed 350, cooldown 0.5s
```

**Loader:** `src/spells/spell_data_loader.lua` - Carga dinámica con validación  
**Registry:** `src/spells/spell_registry.lua` - Almacenamiento central  
**Caster:** `src/spells/spell_caster.lua` - Cooldowns y cast logic

### Enemigos
| Tipo | HP | Speed | Comportamiento | Daño |
|------|-----|-------|----------------|------|
| Murciélago | 20 | 110 | Chase (detect 150px → focus 400px) | 8 |
| Golem | 80 | 50 | Patrol (radio 80px) | 20 |

**Factory:** `src/enemies/enemy_factory.lua`  
**Behaviors:** 
- `chase_behavior.lua` - Sistema de detección en 2 fases:
  - **Fase 1 (Detection):** Rango corto (150px) para detectar al jugador inicialmente
  - **Fase 2 (Focus):** Una vez detectado, persigue a mayor distancia (400px)
  - El enemigo "recuerda" al jugador y no pierde el objetivo fácilmente
- `patrol_behavior.lua` - Patrullaje de área

### DungeonState - Features Completas
- ✅ **Límites del mundo** - Jugador y enemigos no pueden salir
- ✅ **Spawn seguro** - Enemigos aparecen a 150px+ del jugador
- ✅ **Proyectiles** - Spawn en punta del marcador de dirección (40px)
- ✅ **Autofire** - Mantener click dispara cada 0.1s (respeta cooldowns)
- ✅ **Game Over** - Pantalla "HAS MUERTO", vuelve al Hub en 3s
- ✅ **Feedback visual:**
  - Flash rojo al recibir daño (0.3s)
  - Partículas al impactar proyectil (8 partículas)
  - Cooldowns visuales en slots de hechizos
  - HP bars sobre enemigos
- ✅ **Colisiones:** Proyectiles atraviesan jugador/enemigos, chocan paredes

### InputManager - Soporte Completo de Gamepad + Autoaim
Nueva API implementada (TDD completo):
```lua
InputManager:isGamepadConnected()     → boolean
InputManager:getActiveGamepad()       → joystick|nil
InputManager:getAnalogMovement()      → x, y (-1 a 1, con curva)
InputManager:getAnalogAim()           → x, y (right stick)
InputManager:setVibration(left, right) → activa vibración
```

**Mapeos agregados:**
- D-Pad: movimiento (arriba/abajo/izquierda/derecha)
- spell_3: botón Y
- spell_4: click stick derecho
- menu_back: botón B

**Autoaim (DungeonState):**
- Cuando se usa gamepad y el right stick está inactivo
- Apunta automáticamente al enemigo más cercano
- Indicador visual amarillo cuando el autoaim está activo
- Se desactiva cuando se usa el right stick manualmente
- Ignora enemigos muertos automáticamente

**Arquitectura de Colisiones (Limpia):**
```
┌─────────────────────────────────────────────┐
│  bump (Física)                              │
│  - Jugador, Enemigos, Paredes               │
│  - Resolución física de colisiones          │
└─────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ↓                           ↓
┌──────────────────┐      ┌────────────────────┐
│ CombatSystem     │      │ updateProjectiles  │
│ (Proyectil-      │      │ (Proyectil-Paredes)│
│  Enemigo)        │      │ - AABB manual      │
│ - AABB lógica    │      │ - Sin bump         │
└──────────────────┘      └────────────────────┘
```

**Principio aplicado:** Los proyectiles NO están en bump. Las colisiones son puramente lógicas:
- `CombatSystem`: Proyectil-enemigo (daño)
- `updateProjectiles`: Proyectil-paredes/límites (AABB simple)

**Tests:** 
- `spec/core/input_manager_spec.lua` - 24 tests
- `spec/states/autoaim_spec.lua` - 9 tests

### Testing
- ✅ **148 tests pasando** (107 originales + 41 de features nuevos)
- `spec/core/` - Tests de sistema (incluye InputManager completo)
- `spec/spells/` - Tests de hechizos y loader
- `spec/enemies/` - Tests de factory y behaviors (incluye focus system)
- `spec/states/` - Tests de dungeon_state y autoaim
- `spec/ecs/` - Tests de componentes

---

## 📋 Pendiente (Próximas Sesiones)

### 🔥 Alta Prioridad (Core Loop)
1. **Generación Procedural del Dungeon**
   - Actual: 1 cuarto estático (800x600)
   - Objetivo: Múltiples salas conectadas, puertas, llaves
   - Tipos de sala: combate, tesoro, jefe

2. **Sistema de Daño y Efectos Elementales**
   - Tipos de daño: fuego, hielo, arcano, físico
   - Estados alterados: quemadura (DoT), congelado (stun), silenciado
   - Resistencias/Debilidades de enemigos

3. **Sistema de Misiones**
   - Definición en `data/quests/`
   - NPCs que otorgan misiones en el Hub
   - Condiciones: matar X enemigos, obtener hechizo Y, sobrevivir Z segundos
   - Recompensas: nuevo hechizo, aumento de stats, desbloqueos

### ⚡ Media Prioridad (Polish)
4. **UI Mejorada**
   - Dialog system para NPCs (conversaciones tipo visual novel)
   - Inventario/Grimorio visual (drag & drop hechizos)
   - Menú de pausa con opciones (volumen, controles, salir)

5. **Meta-progresión**
   - Guardar grimorio desbloqueado entre runs
   - Bestiario (enemigos descubiertos)
   - Árbol de mejoras permanente (HP+, mana+, speed+)

### 🎨 Baja Prioridad (Contenido)
6. **Sonido y Música**
   - Sistema de audio con buses (SFX, música, UI)
   - Efectos para cada hechizo
   - Música por estado (ambiente dungeon, tranquilo hub)

7. **Assets Visuales**
   - Sprites para personajes (reemplazar rectángulos)
   - Tilesets para dungeons
   - Animaciones (idle, walk, cast, death)

---

## 🏛️ Arquitectura (IMPORTANTE - Seguir Estas Reglas)

### Clean Architecture - Capas
```
┌─────────────────────────────────────────┐
│  CAPA DE PRESENTACIÓN (UI, Render)     │  ← MenuState, HubState, DungeonState
├─────────────────────────────────────────┤
│  CAPA DE APLICACIÓN (Use Cases)        │  ← SpellDataLoader, CombatSystem
├─────────────────────────────────────────┤
│  CAPA DE DOMINIO (Entities, Data)      │  ← Components, SpellRegistry
├─────────────────────────────────────────┤
│  CAPA DE INFRAESTRUCTURA               │  ← Registry, EventBus, InputManager, bump
└─────────────────────────────────────────┘
```

### Principios SOLID (OBLIGATORIOS)

#### S - Single Responsibility
```lua
-- ✅ CORRECTO: Cada clase hace UNA cosa
SpellDataLoader:loadSpell()      -- Solo carga datos
SpellRegistry:register()         -- Solo almacena
DungeonState:castSpell()         -- Solo orquesta
```

#### O - Open/Closed
```lua
-- ✅ CORRECTO: Extender sin modificar
-- Para nuevo hechizo:
-- 1. Crear data/spells/nuevo_hechizo.lua
-- 2. Agregar a SpellDataLoader.SPELL_FILES
-- 3. Listo, no tocar código existente
```

#### D - Dependency Inversion
```lua
-- ✅ CORRECTO: Depender de abstracciones
-- DungeonState NO hace:
if love.keyboard.isDown('space') then  -- ❌ Mal
-- DungeonState SÍ hace:
if input:pressed('cast_spell') then     -- ✅ Bien
```

### Reglas de Oro
1. **NADA HARDCODEADO** - Todo en archivos de datos (`data/`)
2. **Tests obligatorios** - Todo nuevo sistema debe tener tests
3. **Event Bus para comunicación** - No acoplar sistemas directamente
4. **Registry para dependencias** - No globals excepto `_G.Registry`
5. **Component Pattern** - Composición sobre herencia

---

## 📁 Estructura de Directorios Actual

```
spellcrawler/
├── conf.lua
├── main.lua                    # Bootstrap: inicializa Registry y estados
├── data/
│   └── spells/                 # ✅ Archivos de datos de hechizos
│       ├── chispa.lua
│       ├── dardo_magico.lua
│       └── rafaga_viento.lua
├── lib/
│   ├── bump.lua               # Colisiones AABB
│   └── hump/                  # Timer, Camera, Vector, Signal
├── src/
│   ├── core/                  # Sistemas fundamentales
│   │   ├── registry.lua
│   │   ├── event_bus.lua
│   │   ├── input_manager.lua
│   │   └── state_manager.lua
│   ├── states/                # Estados del juego
│   │   ├── menu_state.lua
│   │   ├── hub_state.lua
│   │   └── dungeon_state.lua  # ✅ Combate completo implementado
│   ├── spells/                # Sistema de hechizos
│   │   ├── spell_registry.lua
│   │   ├── spell_caster.lua
│   │   └── spell_data_loader.lua  # ✅ Carga desde data/spells/
│   ├── enemies/               # Sistema de enemigos
│   │   ├── enemy_factory.lua
│   │   └── behaviors/
│   │       ├── chase_behavior.lua
│   │       └── patrol_behavior.lua
│   ├── combat/                # Sistema de combate
│   │   └── combat_system.lua
│   ├── ecs/                   # Components
│   │   ├── components/
│   │   │   ├── transform.lua
│   │   │   ├── health.lua
│   │   │   └── velocity.lua
│   │   └── systems/
│   │       └── movement_system.lua
│   └── utils/                 # Helpers
│       ├── math_utils.lua
│       └── table_utils.lua
├── spec/                      # Tests (107 pasando)
│   ├── core/
│   ├── spells/
│   ├── enemies/
│   ├── combat/
│   ├── states/
│   └── ecs/
└── docs/
    ├── spellcrawler-gdd.md    # Game Design Document original
    ├── sephiria.md            # Referencia de estilo
    ├── initial-content.md     # Lista de hechizos/enemigos planificados
    └── HANDOVER.md            # ESTE ARCHIVO
```

---

## 🚀 Cómo Empezar una Nueva Sesión

### 1. Verificar Estado Actual
```bash
cd spellcrawler
busted                          # Deben pasar 107/107
love .                          # Probar que el juego funciona
```

### 2. Elegir Qué Hacer
- Ver sección "📋 Pendiente" arriba
- Consultar con el usuario qué prioridad quiere trabajar
- **NO empezar algo sin confirmar primero**

### 3. Seguir TDD (Test Driven Development)
```bash
# 1. Escribir test primero
spec/nuevo_sistema/nuevo_test_spec.lua

# 2. Implementar mínimo para que pase
src/nuevo_sistema/nuevo_modulo.lua

# 3. Refactorizar si es necesario

# 4. Verificar que todo sigue pasando
busted                          # 107+ tests deben pasar
```

### 4. Actualizar Este Documento
Después de implementar algo:
- Mover de "📋 Pendiente" a "✅ Implementado"
- Actualizar contador de tests
- Agregar notas si cambió la arquitectura

---

## 🎮 Controles del Juego (Referencia)

| Acción | Teclado | Mouse | Mando |
|--------|---------|-------|-------|
| Mover | WASD / Flechas | - | Left Stick / D-Pad |
| Apuntar | - | Posición mouse | Right Stick |
| Disparar | ESPACIO | Click Izq | Botón A |
| Hechizo 1 | 1 | - | LB |
| Hechizo 2 | 2 | - | RB |
| Hechizo 3 | 3 | - | Botón Y |
| Hechizo 4 | 4 | - | Click Stick Derecho |
| Dash | LShift | - | Botón B |
| Interactuar (Hub) | E | - | Botón X |
| Menú Confirmar | Enter | - | Botón A |
| Menú Atrás | ESC | - | Botón B / Start |
| Pausa | ESC | - | Start |

---

## 📝 Notas para Desarrolladores

### Problemas Conocidos / Deuda Técnica
- Ninguno crítico actualmente
- Sistema de hechizos ahora es data-driven ✅
- Todos los tests pasan ✅

### Decisiones Arquitectónicas Activas
1. **ECS "Lite"** - Tablas Lua simples, no UUIDs complejos
2. **bump.lua** - Colisiones AABB, sin física compleja
3. **Sin serialización** - Cada dungeon es nueva run (roguelike)
4. **MVI solo en DungeonState** - Otros estados usan MVC simple

### Convenciones de Código
- Módulos: `MiModulo.__index = MiModulo`
- Métodos públicos: `function MiModulo:metodo()`
- Funciones privadas: `local function metodo()`
- Eventos: formato `'sistema:accion'` (ej: `'spell:cast'`)

---

## 🔗 Referencias Rápidas

- **GDD:** `docs/spellcrawler-gdd.md`
- **Style Guide:** `docs/sephiria.md`  
- **Contenido Planificado:** `docs/initial-content.md`
- **bump.lua docs:** https://github.com/kikito/bump.lua
- **hump docs:** https://hump.readthedocs.io/
- **LÖVE wiki:** https://love2d.org/wiki/Main_Page

---

**Recuerda:** Este es un proyecto en crecimiento. Cada sesión debe dejar el código mejor de lo que lo encontró. Documentar decisiones. Escribir tests. Mantener la arquitectura limpia.

*Última actualización: 2026-03-27*  
*Estado: MVP de combate funcional, listo para expandir features*
