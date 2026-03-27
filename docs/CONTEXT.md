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

### 🏛️ Clean Architecture: Capas y Dependencias

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ MenuState   │  │  HubState   │  │    DungeonState     │  │
│  │   (UI)      │  │  (UI + NPC) │  │ (Gameplay + Render) │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE APLICACIÓN                        │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ StateManager │  │   Systems   │  │  Spell/Quest Logic  │  │
│  │ (Orchestra)  │  │  (Process)  │  │    (Use Cases)      │  │
│  └──────┬───────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼─────────────────┼────────────────────┼─────────────┘
          │                 │                    │
          ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE DOMINIO                           │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Components  │  │  Entities   │  │   Events/Messages   │  │
│  │   (Data)     │  │ (Aggregate) │  │    (Protocol)       │  │
│  └──────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
          ▲
          │
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE INFRAESTRUCTURA                   │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Registry   │  │  EventBus   │  │   InputManager      │  │
│  │   (DI)       │  │  (Message)  │  │   (Abstraction)     │  │
│  └──────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  bump.lua    │  │  LÖVE API   │  │   File System       │  │
│  │ (Collision)  │  │  (External) │  │   (External)        │  │
│  └──────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Regla de Oro:** Las dependencias apuntan SIEMPRE hacia adentro (hacia el dominio). El dominio NO depende de LÖVE, UI, ni detalles técnicos.

---

### 🎯 Principios SOLID Aplicados

#### S - Single Responsibility Principle

Cada módulo tiene UNA razón para cambiar:

```lua
-- ❌ MAL: Una clase hace todo
local Player = {
    update = function(self, dt) ... end,  -- lógica
    draw = function(self) ... end,        -- render
    save = function(self) ... end,        -- persistencia
    handleInput = function(self) ... end  -- input
}

-- ✅ BIEN: Separado
-- PlayerComponent: solo datos
-- PlayerSystem: solo lógica de update
-- RenderSystem: solo dibujo
-- SaveManager: solo persistencia
-- InputManager: abstrae input
```

**En nuestro código:**
- `Registry` solo hace DI (no lógica de juego)
- `EventBus` solo comunica (no procesa)
- `InputManager` solo lee input (no actúa)
- Cada `System` solo procesa un aspecto

#### O - Open/Closed Principle

Abierto para extensión, cerrado para modificación:

```lua
-- ✅ Agregar un nuevo hechizo sin tocar código existente
-- Solo crear archivo: data/spells/mi_hechizo.lua

-- ✅ Agregar input sin tocar InputManager
inputManager:map('mi_accion', {'key:f', 'button:y'})

-- ✅ Agregar sistema sin tocar core
local MiSistema = require('src.ecs.systems.mi_sistema')
table.insert(systems, MiSistema)
```

**Ejemplo práctico:** Para agregar un nuevo tipo de efecto de hechizo:
1. Crear `src/spells/effects/mi_efecto.lua`
2. Registrar en `EffectRegistry`
3. Los hechizos existentes no se ven afectados

#### L - Liskov Substitution Principle

Los componentes deben ser intercambiables:

```lua
-- ✅ Todos los sistemas tienen la misma interfaz
local systems = {
    movementSystem,  -- :update(entities, dt)
    combatSystem,    -- :update(entities, dt)
    spellSystem,     -- :update(entities, dt)
}

for _, system in ipairs(systems) do
    system:update(entities, dt)  -- Mismo contrato
end
```

#### I - Interface Segregation Principle

Mejor muchas interfaces pequeñas que una grande:

```lua
-- ❌ MAL: Una interfaz gigante
local ComponentGigante = {
    x, y, rotation,     -- Transform
    hp, maxHp,          -- Health
    vx, vy,             -- Velocity
    mana, spells,       -- SpellCaster
    sprite, animation   -- Render
}

-- ✅ BIEN: Componentes separados
local Transform = {x, y, rotation}
local Health = {current, max}
local Velocity = {x, y, maxSpeed}
local SpellCaster = {mana, spells}
```

**En nuestro código:** Cada componente es opcional. Una entidad puede tener solo `Transform`, o `Transform + Health + Velocity`.

#### D - Dependency Inversion Principle

Depender de abstracciones, no de concreciones:

```lua
-- ❌ MAL: Depende de implementación específica
function Player:update(dt)
    if love.keyboard.isDown('space') then  -- Hard-coded LÖVE
        -- ...
    end
end

-- ✅ BIEN: Depende de abstracción
function Player:update(dt, inputManager)  -- Inyectado
    if inputManager:pressed('cast_spell') then  -- Acción abstracta
        -- ...
    end
end
```

**En nuestro código:** Todos los sistemas reciben dependencias vía Registry (constructor injection) o parámetros (method injection).

---

### 📋 MVI: Model-View-Intent en Gameplay

Implementación específica para el gameplay (DungeonState):

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    INPUT     │────▶│    INTENT    │────▶│    MODEL     │
│              │     │   (Systems)  │     │   (State)    │
│  - Keyboard  │     │              │     │              │
│  - Mouse     │     │  - Movement  │     │  - Entities  │
│  - Gamepad   │     │  - Combat    │     │  - World     │
└──────────────┘     │  - Spells    │     │  - Inventory │
                     └──────────────┘     └──────┬───────┘
                                                  │
                       ┌──────────────────────────┘
                       │ Solo lectura
                       ▼
              ┌─────────────────┐
              │      VIEW       │
              │    (Render)     │
              │                 │
              │  - Sprites      │
              │  - UI           │
              │  - Camera       │
              └─────────────────┘
```

**Flujo de datos unidireccional:**
1. Input → Sistema captura intención
2. Intent → Sistema modifica Model
3. Model → View renderiza estado actual
4. NUNCA: View → Model directamente

```lua
-- DungeonState:update() - INTENT
function DungeonState:update(dt)
    -- Input → Intent
    local moveX, moveY = input:getMovementVector()

    -- Intent → Model (sistema modifica estado)
    self:updatePlayerMovement(dt, moveX, moveY)
    self:updateProjectiles(dt)

    -- (View renderiza en :draw())
end

-- DungeonState:draw() - VIEW
function DungeonState:draw()
    -- SOLO LECTURA del model
    for _, entity in ipairs(self.entities) do
        drawEntity(entity)  -- Nunca modifica
    end
end
```

---

### 🧩 Patrones Específicos Usados

#### 1. Component Pattern (ECS Lite)

```lua
-- Composición sobre herencia
local entity = {}

-- Agregar comportamiento por composición
if needsMovement then
    entity.transform = Transform:new(x, y)
    entity.velocity = Velocity:new(0, 0, speed)
end

if canTakeDamage then
    entity.health = Health:new(maxHp)
end

if canCastSpells then
    entity.spellCaster = SpellCaster:new(mana, spells)
end
```

#### 2. Observer Pattern (Event Bus)

```lua
-- Desacopla emisor de receptores
-- Sistema A no sabe que existe Sistema B

-- En SpellSystem:
eventBus:emit('entity:died', {entity = enemy, killer = player})

-- En QuestSystem (en cualquier lugar):
eventBus:on('entity:died', function(data)
    questManager:checkKillObjective(data.entity.type)
end)

-- En AchievementSystem:
eventBus:on('entity:died', function(data)
    achievementManager:trackKill(data.entity.type)
end)
```

#### 3. State Pattern (Game States)

```lua
-- Cada estado es una clase completa
-- Cambio de estado = cambio de comportamiento global

local states = {
    menu = MenuState:new(),      -- Input: navegación UI
    hub = HubState:new(),        -- Input: movimiento + dialogo
    dungeon = DungeonState:new(), -- Input: combate
}

stateManager:switch('dungeon')  -- Comportamiento cambia completamente
```

#### 4. Strategy Pattern (Input Mappings)

```lua
-- Mismo input, diferentes dispositivos
inputManager:map('cast_spell', {
    'key:space',
    'mouse:1',
    'button:a'
})

-- El código del juego no sabe/care de qué dispositivo
if input:pressed('cast_spell') then ... end
```

#### 5. Factory Pattern (Entity Creation)

```lua
-- Entities no se crean directamente, pasan por factories

-- ❌ MAL:
local enemy = {x = 100, y = 200, hp = 50}  -- ¿Qué tipo? ¿Qué componentes?

-- ✅ BIEN:
local enemy = EnemyFactory:create('murcielago', {x = 100, y = 200})
-- Garantiza componentes correctos, inicialización apropiada
```

#### 6. Command Pattern (Para input y spells)

```lua
-- Encapsula acciones como objetos
local MoveCommand = {dx = 0, dy = 0, entity = nil}
function MoveCommand:execute()
    self.entity.transform:translate(self.dx, self.dy)
end

-- Permite: undo, replay, queue, macro
```

---

## 3. Anti-Patrones a EVITAR

### ❌ God Object / God Class

```lua
-- NUNCA hacer esto:
local Game = {
    player = {}, enemies = {}, world = {},
    camera = {}, ui = {}, audio = {},
    update = function() -- 500 líneas
    draw = function()   -- 500 líneas
    save = function()   -- 200 líneas
end
}
```

**Solución:** Separar en sistemas especializados.

### ❌ Global State Directo

```lua
-- NUNCA:
_G.player = {x = 100, y = 100}  -- Cualquiera puede modificar

-- NUNCA:
function update(dt)
    if _G.gameState == 'playing' then  -- Acoplamiento global
```

**Solución:** Usar Registry para acceso controlado.

### ❌ Singleton Abuse

```lua
-- NUNCA:
local AudioManager = require('src.core.audio_manager')
-- AudioManager es global singleton

-- ✅ BIEN:
local audio = Registry:get('audio')  -- Inyectado, testeable
```

### ❌ Feature Envy

```lua
-- NUNCA: Sistema A accediendo a datos internos de B
function RenderSystem:draw(entity)
    if entity.health.current < 20 then  -- Sabe demasiado de Health
        drawLowHealthEffect()
    end
end

-- ✅ BIEN:
function RenderSystem:draw(entity)
    if entity.health:isLow() then  -- Health encapsula su lógica
        drawLowHealthEffect()
    end
end
```

### ❌ Premature Abstraction

```lua
-- NUNCA: Crear sistema complejo para algo simple
local ProyectilFactory = require('...')
local ProyectilPool = require('...')
local ProyectilBehavior = require('...')

-- ✅ BIEN: Empezar simple, refactorizar cuando necesario
local proyectiles = {}
function spawnProyectil(x, y, vx, vy)
    table.insert(proyectiles, {x = x, y = y, vx = vx, vy = vy})
end
```

### ❌ Circular Dependencies

```lua
-- NUNCA:
-- player.lua require('enemy')
-- enemy.lua require('player')

-- ✅ BIEN: Dependencia común o eventos
-- player.lua y enemy.lua requieren 'damage_system'
-- O usan EventBus para comunicarse
```

---

## 4. Testing con Esta Arquitectura

### Unit Testing

```lua
-- Testear sistema aislado (sin LÖVE, sin Registry real)
local EventBus = require('src.core.event_bus')

describe('EventBus', function()
    it('should dispatch events to listeners', function()
        local bus = EventBus:new()
        local called = false

        bus:on('test', function() called = true end)
        bus:emit('test')

        assert.is_true(called)
    end)
end)
```

### Integration Testing

```lua
-- Testear interacción entre sistemas
local SpellSystem = require('src.ecs.systems.spell_system')
local HealthSystem = require('src.ecs.systems.health_system')

describe('SpellDamage', function()
    it('should reduce health on damage spell', function()
        local entity = {
            health = {current = 100, max = 100}
        }

        SpellSystem:cast(entity, {type = 'damage', amount = 20})
        HealthSystem:update({entity}, 0)

        assert.equal(80, entity.health.current)
    end)
end)
```

### Mocking Registry

```lua
-- Para testear código que usa Registry
local function mockRegistry(services)
    _G.Registry = {
        _services = services or {},
        get = function(self, name) return self._services[name] end,
        register = function(self, name, service) self._services[name] = service end
    }
end

-- Uso:
before_each(function()
    mockRegistry({
        event_bus = EventBus:new(),
        input = MockInput:new()
    })
end)
```

---

## 5. Convenciones de Código

### 1. Módulos

```lua
-- Siempre retornar tabla con métodos
local MiModulo = {}
MiModulo.__index = MiModulo

function MiModulo:new(params)
    local instance = {}
    setmetatable(instance, self)
    -- inicialización
    return instance
end

function MiModulo:metodoPublico()
    -- ...
end

local function funcionPrivada()  -- local = privado
    -- ...
end

return MiModulo
```

### 2. Clases/OOP

```lua
-- Usar __index pattern de Lua
MiClase.__index = MiClase

-- Herencia
MiSubclase = setmetatable({}, {__index = MiClase})
MiSubclase.__index = MiSubclase
```

### 3. Registry

```lua
-- Prefijo _G. solo en main.lua
_G.Registry = Registry:new()

-- Después, siempre usar variable local
local registry = _G.Registry  -- o pasar como parámetro
local input = registry:get('input')
```

### 4. Eventos

- Formato: `'sistema:acción'` (ej: `'spell:cast'`, `'entity:died'`)
- Datos: Tabla con contexto relevante, no objetos completos

```lua
-- ✅ BIEN:
eventBus:emit('entity:died', {
    entity = entity,
    killer = killer,
    damageType = 'fire'
})

-- ❌ MAL:
eventBus:emit('entity died', entity)  -- Mensaje poco estructurado
```

---

## 6. Cómo Extender el Sistema

### Agregar un Nuevo Componente

```lua
-- 1. Crear archivo: src/ecs/components/mi_componente.lua
local MiComponente = {}
MiComponente.__index = MiComponente

function MiComponente:new(params)
    local instance = {
        -- datos del componente
    }
    setmetatable(instance, self)
    return instance
end

return MiComponente

-- 2. Agregar a entidades que lo necesiten
entity.miComponente = MiComponente:new(params)

-- 3. (Opcional) Crear sistema que lo procese
local MiSistema = require('src.ecs.systems.mi_sistema')
table.insert(systems, MiSistema)
```

### Agregar un Nuevo Hechizo

```lua
-- 1. Crear definición: data/spells/mi_hechizo.lua
return {
    id = 'mi_hechizo',
    name = 'Mi Hechizo',
    mana_cost = 10,
    effects = {
        {type = 'mi_efecto', params = {...}}
    }
}

-- 2. Registrar efecto si es nuevo (src/spells/effects/mi_efecto.lua)
-- 3. Listo - SpellSystem lo cargará automáticamente
```

### Agregar un Nuevo Estado

```lua
-- 1. Crear archivo: src/states/mi_estado.lua
local MiEstado = {}
MiEstado.__index = MiEstado

function MiEstado:new()
    return setmetatable({}, self)
end

function MiEstado:enter() end
function MiEstado:exit() end
function MiEstado:update(dt) end
function MiEstado:draw() end

return MiEstado

-- 2. Registrar en main.lua:
stateManager:register('mi_estado', MiEstado)

-- 3. Cambiar a él:
stateManager:switch('mi_estado')
```

---

## 7. Estructura de Directorios

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

## 8. Decisiones Arquitectónicas Clave

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

## 9. Sistemas Pendientes (Por Prioridad)

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

## 10. Notas Técnicas

### LÖVE Versión
- Target: **11.4**
- Módulos desactivados: `physics` (usamos bump.lua)
- Módulos activados: `joystick`

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

## 11. Ideas de Diseño Pendientes

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

## 12. Recursos Útiles

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

## 13. Comandos Útiles

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
