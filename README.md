# mri_Qtrucker

Job de caminhoneiro para FiveM com QBX Core. O player aluga um caminhão, acopla um trailer, faz a entrega em um ponto sorteado aleatoriamente e recebe o pagamento em dinheiro.

---

## Dependências

| Recurso | Uso |
|---|---|
| `qbx_core` | Framework principal (jogador, dinheiro, citizenid) |
| `ox_lib` | Notificações, callbacks, barra de progresso |
| `ox_target` | Interação com trailer para entregar carga |
| `oxmysql` | Banco de dados (XP, histórico, nível) |
| `mri_Qcarkeys` | Dar/remover chaves do caminhão alugado |

---

## Instalação

1. Coloque a pasta `mri_Qtrucker` dentro de `resources/[mri]/`
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qtrucker
   ```
3. Reinicie o servidor — a tabela `mri_qtrucker_players` é criada automaticamente no banco.

---

## Fluxo do Job

```
Falar com NPC despachante
  → Escolher rota + tipo de carga
    → Trailer spawna no ponto de retirada
      → Player acopla o trailer ao caminhão
        → Dirige até o ponto de entrega sorteado
          → Sai do caminhão, usa ox_target no trailer → "Entregar a carga"
            → Barra de progresso (5 s) → Pagamento em mãos → Missão concluída
```

**F6** cancela a rota ativa e devolve o caminhão de qualquer lugar.

---

## Arquivo de Configuração — `config.lua`

### Spawns

```lua
-- Onde o caminhão alugado aparece
Config.TruckSpawn = {
    coords  = vector3(1715.18, -1565.93, 112.63),
    heading = 250.53,
    radius  = 6.0,  -- raio para verificar se a vaga está ocupada
}

-- Onde o trailer aparece ao iniciar uma rota
Config.TrailerSpawn = vector4(1730.25, -1555.49, 112.66, 253.35)
```

---

### Caminhões para Locação

```lua
Config.TruckRentOptions = {
    { model = 'mule',    label = 'Mule',    price = 300,  icon = '🚐', desc = 'Leve'    },
    { model = 'hauler',  label = 'Hauler',  price = 600,  icon = '🚛', desc = 'Padrão'  },
    { model = 'phantom', label = 'Phantom', price = 1000, icon = '🚀', desc = 'Premium' },
}
```

**Para adicionar um novo caminhão:**
```lua
{ model = 'packer', label = 'Packer', price = 800, icon = '🚚', desc = 'Resistente' },
```

| Campo | Tipo | Descrição |
|---|---|---|
| `model` | string | Nome do modelo GTA V |
| `label` | string | Nome exibido na NUI |
| `price` | number | Valor do aluguel (cash ou banco) |
| `icon` | string | Emoji exibido na NUI |
| `desc` | string | Descrição curta exibida na NUI |

---

### Parâmetros de Missão

```lua
Config.MaxSafeSpeed        = 120    -- km/h máximo sem penalidade
Config.SpeedConditionLoss  = 0.002  -- perda de condição por tick acima do limite
Config.ImpactConditionLoss = 0.3    -- multiplicador de perda em colisões
Config.TimeBonusPercent    = 0.20   -- bônus de 20% ao entregar no prazo
Config.DeliveryRadius      = 100.0  -- distância máxima do trailer ao ponto (m)
Config.DeliveryDuration    = 5000   -- duração da barra de descarga (ms)
```

---

### Pontos de Entrega

```lua
Config.DeliveryPoints = {
    [1]  = { label = "Ponto de Entrega 1", coords = vector3(282.80, -3221.97, 5.80) },
    [2]  = { label = "Ponto de Entrega 2", coords = vector3(1254.19, -3192.98, 5.80) },
    -- ...
}
```

**Para adicionar um novo ponto:**
```lua
[14] = { label = "Novo Armazém", coords = vector3(X, Y, Z) },
```

Depois adicione o novo ID ao `deliveryPoints` das rotas desejadas.

---

### Tipos de Carga

```lua
Config.CargoTypes = {
    frutas = {
        label    = "Frutas e Legumes",
        icon     = "🍎",
        trailer  = { "trailers2", "trailers3" },  -- string ou table (sorteio aleatório)
        minPay   = 800,
        maxPay   = 1200,
        baseXP   = 80,
        minLevel = 1,
        company  = "transbrasil",
    },
    -- ...
}
```

**Para adicionar um novo tipo de carga:**
```lua
graodecafe = {
    label    = "Grão de Café",
    icon     = "☕",
    trailer  = "trailers2",
    minPay   = 900,
    maxPay   = 1400,
    baseXP   = 95,
    minLevel = 1,
    company  = "transbrasil",
},
```

Depois adicione a chave ao `allowedCargo` das rotas desejadas.

---

### Rotas

```lua
Config.Routes = {
    {
        id           = 1,
        label        = "Sandy Shores → Porto de LS",
        company      = "transbrasil",
        origin       = { label = "Depósito Sandy Shores", coords = vector4(...) },
        destination  = { label = "Porto de Los Santos" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },  -- sorteia um
        distance     = "82 km",
        basePay      = 2000,
        baseXP       = 150,
        difficulty   = 1,      -- 1 a 4 estrelas
        timeLimit    = 20,     -- minutos para completar com bônus
        allowedCargo = { "frutas", "graos" },
        minLevel     = 1,
    },
}
```

**Para adicionar uma nova rota:**
```lua
{
    id           = 15,
    label        = "LS → Blaine County",
    company      = "transbrasil",
    origin       = { label = "Galpão LS", coords = vector4(X, Y, Z, H) },
    destination  = { label = "Blaine County" },
    deliveryPoints = { 1, 2, 3 },  -- sorteia entre esses 3 pontos
    distance     = "60 km",
    basePay      = 1800,
    baseXP       = 130,
    difficulty   = 2,
    timeLimit    = 18,
    allowedCargo = { "graos", "gado" },
    minLevel     = 1,
},
```

---

### Níveis de XP

```lua
Config.Levels = {
    [1]  = { xp = 0,     label = "Iniciante",    multiplier = 1.00, color = "#9ca3af" },
    [2]  = { xp = 500,   label = "Aprendiz",     multiplier = 1.10, color = "#60a5fa" },
    -- ...
    [10] = { xp = 38000, label = "Caminhoneiro", multiplier = 3.50, color = "#f59e0b" },
}
```

| Campo | Descrição |
|---|---|
| `xp` | XP mínimo para atingir o nível |
| `label` | Título exibido na NUI |
| `multiplier` | Multiplicador de pagamento |
| `color` | Cor do nível na NUI (hex) |

---

### Sistema de Ranking e Bônus Top 3

O sistema conta com um painel de ranking interativo onde os jogadores competem pelo posto de melhor motorista (por XP, Nível ou Entregas). Aqueles que estiverem no Top 3 do ranking de XP ganham um bônus financeiro em **todas as entregas**. O bônus se acumula (multiplica) com o bônus do nível atual do jogador.

```lua
Config.TopRankingBuffs = {
    [1] = 1.5, -- Top 1: +50% de lucro
    [2] = 1.3, -- Top 2: +30% de lucro
    [3] = 1.1, -- Top 3: +10% de lucro
}
```

| Ranking | Bônus | Descrição |
|---|---|---|
| `[1]` | 1.5 | Multiplica o pagamento total (base + nível) por 1.5x |
| `[2]` | 1.3 | Multiplica o pagamento total (base + nível) por 1.3x |
| `[3]` | 1.1 | Multiplica o pagamento total (base + nível) por 1.1x |

---

### Despachantes (NPCs)

```lua
Config.Dispatchers = {
    {
        id     = 1,
        label  = "Central de Cargas LS",
        coords = vector4(1713.31, -1555.11, 113.94, 162.17),
        ped    = "s_m_y_construct_01",
        blip   = { sprite = 477, color = 3, label = "Central de Cargas" },
    },
}
```

---

## Teclas

| Tecla | Ação |
|---|---|
| **F6** | Cancela a rota ativa e devolve o caminhão de qualquer lugar |

Pode ser remapeada nas configurações de controles do GTA V.

---

## Banco de Dados

Tabela criada automaticamente: `mri_qtrucker_players`

| Coluna | Tipo | Descrição |
|---|---|---|
| `citizenid` | VARCHAR(50) | ID do jogador |
| `xp` | INT | XP acumulado |
| `level` | INT | Nível atual |
| `total_deliveries` | INT | Total de entregas |
| `total_earned` | BIGINT | Total ganho (R$) |
| `history` | LONGTEXT | Histórico das últimas 20 entregas (JSON) |
