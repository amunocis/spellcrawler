# 🤖 Kimi Code - Reglas de Comportamiento

> **Este archivo configura cómo Kimi Code debe comportarse en todas las sesiones de este proyecto.**
> 
> Lee este archivo PRIMERO antes de cualquier otra acción.

---

## 📖 Checklist Obligatorio al Empezar

- [ ] Leer `docs/HANDOVER.md` completamente (estado actual del proyecto)
- [ ] Verificar tests: `busted` debe dar 107/107 pasando
- [ ] Confirmar con el usuario qué feature de la lista de pendientes va a trabajar
- [ ] **NUNCA asumir** - Siempre preguntar si algo no está claro

---

## ⚠️ Reglas de Oro (INQUEBRANTABLES)

### 1. Test Driven Development (TDD) - OBLIGATORIO
```
1. Escribir test primero → 2. Hacerlo pasar → 3. Refactorizar
```
- **Cada nuevo sistema DEBE tener tests**
- **Ningún código de producción sin tests**
- Ejecutar `busted` después de CADA cambio significativo
- Si tests fallan, ARREGLAR ANTES de continuar

### 2. Clean Architecture
```
CAPAS (nunca mezclar):
┌─────────────────────┐
│ Presentación (UI)   │ ← Estados, Draw
├─────────────────────┤
│ Aplicación (Use)    │ ← Loaders, Systems
├─────────────────────┤
│ Dominio (Data)      │ ← Components, Registry
├─────────────────────┤
│ Infraestructura     │ ← Registry, EventBus, bump
└─────────────────────┘
```

### 3. Principios SOLID

#### S - Single Responsibility
```lua
-- ✅ CORRECTO: Una clase = Una razón para cambiar
SpellDataLoader:loadSpell()    -- Solo carga
SpellRegistry:register()       -- Solo almacena
DungeonState:castSpell()       -- Solo orquesta

-- ❌ PROHIBIDO: Clases que hacen todo
function GodObject:update()     -- input + lógica + render + guardar
```

#### O - Open/Closed
```lua
-- ✅ Extender sin modificar
-- Para nuevo hechizo: Crear archivo en data/spells/ + agregar a lista
-- NO tocar código existente
```

#### L - Liskov Substitution
```lua
-- ✅ Interfaz consistente
function miSistema:update(dt)   -- Todos los sistemas usan esta firma
```

#### I - Interface Segregation
```lua
-- ✅ Componentes pequeños y específicos
Transform {x, y}              -- Solo posición
Health {current, max}         -- Solo vida
Velocity {vx, vy}             -- Solo movimiento
```

#### D - Dependency Inversion
```lua
-- ✅ Depender de abstracciones, no implementaciones
if input:pressed('cast') then   -- Bien (acción abstracta)
if love.keyboard.isDown('space') then  -- MAL (acoplado a LÖVE)
```

### 4. NADA HARDCODEADO
```lua
-- ❌ PROHIBIDO:
if spellId == 'chispa' then damage = 15 end  -- Hardcode

-- ✅ OBLIGATORIO:
local spellData = require('data/spells/' .. spellId)  -- Data-driven
```

### 5. Documentación Actualizada
- **Siempre** actualizar `docs/HANDOVER.md` después de implementar
- Mover features de "Pendiente" → "Implementado"
- Actualizar contador de tests
- Agregar notas sobre cambios arquitectónicos

---

## 🔧 Convenciones de Código

### Módulos
```lua
local MiModulo = {}
MiModulo.__index = MiModulo

function MiModulo:new(params)
    local instance = {}
    setmetatable(instance, self)
    -- inicialización
    return instance
end

function MiModulo:metodoPublico()
    -- código
end

local function funcionPrivada()  -- local = privado
    -- código
end

return MiModulo
```

### Eventos
- Formato: `'sistema:accion'`
- ✅ `'spell:cast'`, `'entity:died'`, `'player:damage'`
- ❌ `'spell cast'`, `'entity_died'`

### Variables
- Locales siempre que sea posible
- `self` para métodos de instancia
- `_G.Registry` solo en main.lua, después usar variable local

---

## 🧪 Flujo de Trabajo TDD

```bash
# 1. ANTES de escribir código de producción:
→ Crear spec/nuevo_modulo_spec.lua
→ Escribir tests que fallen
→ Ejecutar busted (debe fallar)

# 2. Implementar mínimo:
→ Crear src/nuevo_modulo.lua
→ Hacer que tests pasen
→ Ejecutar busted (debe pasar)

# 3. Refactorizar:
→ Limpiar código
→ Verificar busted sigue pasando

# 4. Integrar:
→ Conectar con sistemas existentes
→ Ejecutar busted (debe pasar 107+)
→ Probar con love .

# 5. Documentar:
→ Actualizar docs/HANDOVER.md
```

---

## 🚫 Anti-Patrones PROHIBIDOS

### ❌ God Object
```lua
-- NUNCA:
local Game = {
    player = {}, enemies = {}, world = {},
    update = function() -- 500 líneas
    draw = function()   -- 500 líneas
}
```

### ❌ Global State
```lua
-- NUNCA:
_G.player = {x = 100}  -- Cualquiera puede modificar
_G.gameState = 'playing'  -- Acoplamiento global

-- USAR Registry:
local player = Registry:get('player')
```

### ❌ Singleton Abuse
```lua
-- NUNCA:
local Audio = require('audio_manager')  -- Singleton global

-- USAR:
local audio = Registry:get('audio')  -- Inyectado
```

### ❌ Feature Envy
```lua
-- NUNCA:
if entity.health.current < 20 then  -- Sabe demasiado

-- USAR:
if entity.health:isLow() then  -- Encapsulamiento
```

### ❌ Premature Abstraction
```lua
-- NUNCA para algo simple:
local Factory = require('...')
local Pool = require('...')
local Behavior = require('...')

-- ✅ Empezar simple:
local proyectiles = {}
function spawn(x, y) table.insert(proyectiles, {x=x, y=y}) end
```

---

## 📁 Arquitectura del Proyecto

### Estructura de Directorios
```
spellcrawler/
├── data/              ← Datos puros (NO código)
│   └── spells/
├── src/
│   ├── core/          ← Sistemas fundamentales (Registry, EventBus, Input)
│   ├── states/        ← Estados del juego
│   ├── spells/        ← Sistema de hechizos
│   ├── enemies/       ← Sistema de enemigos
│   ├── combat/        ← Sistema de combate
│   ├── ecs/           ← Components
│   └── utils/         ← Helpers
├── spec/              ← Tests (mirror de src/)
└── docs/              ← Documentación
```

### Patrones Actuales
- **ECS Lite**: Entidades = tablas con componentes
- **Event Bus**: Comunicación desacoplada
- **State Pattern**: Estados del juego completos
- **Factory Pattern**: Creación de enemigos
- **Data-Driven**: Hechizos en archivos Lua

---

## 🎯 Prioridades de Implementación

### Siempre preguntar al usuario:
1. ¿Qué feature de `docs/HANDOVER.md` sección "Pendiente" vamos a hacer?
2. ¿Hay algo específico que quiera primero?
3. ¿Alguna restricción especial para esta sesión?

### NO hacer sin confirmar:
- Cambiar arquitectura existente
- Refactorizar código que funciona sin motivo claro
- Agregar dependencias externas
- Modificar comportamiento de features existentes

---

## 📝 Comandos Útiles

```bash
# Verificar estado
busted                          # Debe pasar 107/107+
love .                          # Probar gameplay

# Crear .love para distribuir
zip -9 -r spellcrawler.love . -x "*.git*" -x "*.md" -x "docs/*"

# Logs
love . --console               # Ver prints en consola
```

---

## 🎮 Testing Manual Rápido

Después de cambios, verificar:
1. Menú → Hub → Dungeon (transiciones funcionan)
2. Movimiento WASD (jugador se mueve)
3. Disparar click/espacio (proyectiles spawn en punta del marcador)
4. Cambiar hechizos 1-2-3 (colores diferentes)
5. Enemigos te siguen/atacan (recibes daño, flash rojo)
6. Matas enemigos (desaparecen)
7. Morir (Game Over → vuelve a Hub)
8. Tests pasan: `busted`

---

## ⚡ Recordatorio Final

> **Este es un proyecto de aprendizaje y crecimiento.**
> 
> Cada sesión debe dejar el código:
> - ✅ Mejor testeado
> - ✅ Mejor documentado
> - ✅ Mejor arquitecturado
> - ✅ Más mantenible
> 
> **Calidad sobre velocidad.**
> 
> **Tests antes que código.**
> 
> **Datos antes que hardcode.**

---

## 📋 Checklist de Cierre de Feature

### Git Flow Workflow

**Nunca trabajar directamente en `main`.** Para cada desarrollo:

```
1. Crear rama desde main:
   - feature/nombre-descriptivo (nuevas features)
   - bugfix/nombre-del-bug (correcciones)
   - chore/nombre (tareas de mantenimiento)

2. Desarrollar en la rama con TDD

3. Cuando esté listo:
   □ Tests pasando (busted)
   □ Probar manualmente (love .)
   □ Actualizar documentación
   □ Commit por separado (un commit por feature/fix)
   □ Push de la rama
   □ Merge a main (después de confirmación del usuario)
```

**REGLAS DE ORO:**
- Un feature = Un commit
- Nunca mezclar múltiples features en un solo commit
- Nunca pushear directo a main
- Todo pasa por PR/merge con aprobación

---

## 📝 Planes de Implementación

**Los planes se muestran DIRECTAMENTE en el chat.**

- NO se crean archivos de plan (.md en .kimi/plans/)
- El plan se escribe en la conversación para que el usuario lo vea inmediatamente
- Se confirma con el usuario antes de proceder
- Luego se ejecuta directamente

---

**Archivos de referencia obligatorios:**
- `docs/HANDOVER.md` - Estado actual del proyecto
- `docs/spellcrawler-gdd.md` - Game Design Document
- `KIMI.md` - Este archivo (reglas de comportamiento)

*Leer estos 3 archivos al inicio de CADA sesión.*
