Config = {}

Config.Debug = false

-- ─── Spawns ───────────────────────────────────────────────────────────────────
-- Ponto onde o caminhão alugado aparece (próximo ao despachante)
Config.TruckSpawn = {
    coords  = vector3(1715.18, -1565.93, 112.63),
    heading = 250.53,
    radius  = 6.0,   -- raio (m) para checar se a vaga está ocupada
}

-- Ponto onde o trailer aparece ao iniciar uma rota
Config.TrailerSpawn = vector4(1730.25, -1555.49, 112.66, 253.35)

-- ─── Caminhões para Locação ───────────────────────────────────────────────────
-- Para adicionar um novo caminhão: copie uma linha, ajuste model/label/price/icon/desc.
--   model → nome do modelo GTA (string)
--   label → nome exibido na NUI
--   price → valor cobrado (dinheiro em mãos ou banco)
--   icon  → emoji exibido na NUI
--   desc  → descrição curta exibida na NUI
Config.TruckRentOptions = {
    { model = 'hauler',  label = 'Hauler',  price = 600,  icon = '🚛', desc = 'Padrão — aceita a maioria das cargas'    },
    { model = 'phantom', label = 'Phantom', price = 1000, icon = '🚀', desc = 'Premium — melhor desempenho nas estradas' },
}

-- ─── Modelos aceitos como caminhão próprio do player ─────────────────────────
Config.TruckModels = {
    'hauler', 'hauler2', 'phantom', 'phantom2', 'phantomwedge',
    'packer', 'pounder', 'pounder2', 'mule', 'mule2', 'mule3', 'mule4',
}

-- ─── Parâmetros de Missão ─────────────────────────────────────────────────────
Config.MaxSafeSpeed        = 120    -- km/h máximo sem penalidade de condição da carga
Config.SpeedConditionLoss  = 0.002  -- perda de condição por tick acima do limite
Config.ImpactConditionLoss = 0.3    -- multiplicador de perda de condição em colisões
Config.TimeBonusPercent    = 0.20   -- bônus de pagamento (20%) ao entregar no prazo
Config.CancelPenalty       = false  -- penalidade ao cancelar (não implementado)

-- ─── Entrega ──────────────────────────────────────────────────────────────────
Config.DeliveryRadius   = 100.0  -- distância máxima (m) do trailer ao ponto de entrega
Config.DeliveryDuration = 5000   -- duração da barra de progresso de descarga (ms)

-- Níveis e títulos
Config.Levels = {
    [1]  = { xp = 0,      label = "Iniciante",     multiplier = 1.00, color = "#9ca3af" },
    [2]  = { xp = 500,    label = "Aprendiz",      multiplier = 1.10, color = "#60a5fa" },
    [3]  = { xp = 1500,   label = "Regular",       multiplier = 1.25, color = "#34d399" },
    [4]  = { xp = 3000,   label = "Experiente",    multiplier = 1.40, color = "#a78bfa" },
    [5]  = { xp = 5500,   label = "Profissional",  multiplier = 1.60, color = "#f472b6" },
    [6]  = { xp = 9000,   label = "Especialista",  multiplier = 1.85, color = "#fb923c" },
    [7]  = { xp = 14000,  label = "Mestre",        multiplier = 2.10, color = "#fbbf24" },
    [8]  = { xp = 20000,  label = "Elite",         multiplier = 2.40, color = "#f87171" },
    [9]  = { xp = 28000,  label = "Lendário",      multiplier = 2.80, color = "#c084fc" },
    [10] = { xp = 38000,  label = "Caminhoneiro",  multiplier = 3.50, color = "#f59e0b" },
}

-- Empresas de transporte
Config.Companies = {
    transbrasil = {
        label    = "TransBrasil Logística",
        desc     = "Cargas agrícolas e gerais",
        minLevel = 1,
        color    = "#10b981",
        icon     = "🌿",
    },
    petrocargo = {
        label    = "PetroCargo",
        desc     = "Combustíveis e químicos",
        minLevel = 3,
        color    = "#f59e0b",
        icon     = "⛽",
    },
    construlog = {
        label    = "ConstroLog",
        desc     = "Materiais de construção",
        minLevel = 2,
        color    = "#60a5fa",
        icon     = "🏗️",
    },
    megalog = {
        label    = "MegaLog Express",
        desc     = "Cargas de alto valor",
        minLevel = 5,
        color    = "#c084fc",
        icon     = "💎",
    },
}

-- Tipos de carga
-- trailer pode ser string (fixo) ou table (escolhe aleatoriamente)
Config.CargoTypes = {
    frutas = {
        label    = "Frutas e Legumes",
        icon     = "🍎",
        fragile  = true,
        trailer  = { "trailers2", "trailers3" },
        minPay   = 800,
        maxPay   = 1200,
        baseXP   = 80,
        minLevel = 1,
        company  = "transbrasil",
    },
    graos = {
        label    = "Grãos e Cereais",
        icon     = "🌾",
        fragile  = false,
        trailer  = "trailers2",
        minPay   = 700,
        maxPay   = 1000,
        baseXP   = 70,
        minLevel = 1,
        company  = "transbrasil",
    },
    gado = {
        label    = "Gado Vivo",
        icon     = "🐄",
        fragile  = false,
        trailer  = "trailers2",
        minPay   = 1000,
        maxPay   = 1500,
        baseXP   = 100,
        minLevel = 2,
        company  = "transbrasil",
    },
    combustivel = {
        label    = "Combustível",
        icon     = "⛽",
        fragile  = true,
        trailer  = { "tanker", "tanker2" },
        minPay   = 1500,
        maxPay   = 2500,
        baseXP   = 150,
        minLevel = 3,
        company  = "petrocargo",
    },
    quimicos = {
        label    = "Produtos Químicos",
        icon     = "⚗️",
        fragile  = true,
        trailer  = "tanker2",
        minPay   = 2000,
        maxPay   = 3500,
        baseXP   = 200,
        minLevel = 4,
        company  = "petrocargo",
    },
    construcao = {
        label    = "Material de Construção",
        icon     = "🧱",
        fragile  = false,
        trailer  = "trailers",
        minPay   = 900,
        maxPay   = 1400,
        baseXP   = 90,
        minLevel = 2,
        company  = "construlog",
    },
    madeira = {
        label    = "Madeira e Toras",
        icon     = "🪵",
        fragile  = false,
        trailer  = "trailerlogs",
        minPay   = 800,
        maxPay   = 1300,
        baseXP   = 95,
        minLevel = 2,
        company  = "construlog",
    },
    maquinario = {
        label    = "Maquinário Pesado",
        icon     = "⚙️",
        fragile  = false,
        trailer  = "armytrailer2",
        minPay   = 1800,
        maxPay   = 3000,
        baseXP   = 180,
        minLevel = 5,
        company  = "construlog",
    },
    eletronicos = {
        label    = "Eletrônicos",
        icon     = "💻",
        fragile  = true,
        trailer  = "trailers",
        minPay   = 2500,
        maxPay   = 4000,
        baseXP   = 250,
        minLevel = 5,
        company  = "megalog",
    },
    congelados = {
        label    = "Alimentos Congelados",
        icon     = "🧊",
        fragile  = true,
        trailer  = { "trailers2", "trailers3" },
        minPay   = 1200,
        maxPay   = 2000,
        baseXP   = 130,
        minLevel = 3,
        company  = "megalog",
        timeSensitive = true,
    },
    farmaceuticos = {
        label    = "Produtos Farmacêuticos",
        icon     = "💊",
        fragile  = true,
        trailer  = "trailers",
        minPay   = 3000,
        maxPay   = 5000,
        baseXP   = 300,
        minLevel = 7,
        company  = "megalog",
    },
    barcos = {
        label    = "Embarcações",
        icon     = "⛵",
        fragile  = false,
        trailer  = "tr3",
        minPay   = 2200,
        maxPay   = 3800,
        baseXP   = 220,
        minLevel = 4,
        company  = "megalog",
    },
    carros = {
        label    = "Veículos",
        icon     = "🚗",
        fragile  = true,
        trailer  = "tr4",
        minPay   = 2800,
        maxPay   = 4500,
        baseXP   = 260,
        minLevel = 4,
        company  = "megalog",
    },
}

-- ─── Pontos de entrega predeterminados ───────────────────────────────────────
-- Cada rota usa deliveryPoints = {1,2,...,13} e o jogo sorteia um ao iniciar.
Config.DeliveryPoints = {
    [1]  = { label = "Ponto de Entrega 1",  coords = vector3(  282.80, -3221.97,   5.80) },
    [2]  = { label = "Ponto de Entrega 2",  coords = vector3( 1254.19, -3192.98,   5.80) },
    [3]  = { label = "Ponto de Entrega 3",  coords = vector3( 1012.24, -2922.69,   5.90) },
    [4]  = { label = "Ponto de Entrega 4",  coords = vector3(-1265.53, -3341.48,  13.94) },
    [5]  = { label = "Ponto de Entrega 5",  coords = vector3(-2095.75,  -343.73,  13.00) },
    [6]  = { label = "Ponto de Entrega 6",  coords = vector3(-2221.21,  3303.98,  32.82) },
    [7]  = { label = "Ponto de Entrega 7",  coords = vector3( -576.81,  5330.49,  70.25) },
    [8]  = { label = "Ponto de Entrega 8",  coords = vector3( -278.51,  6054.11,  31.52) },
    [9]  = { label = "Ponto de Entrega 9",  coords = vector3( 2379.86,  4929.81,  42.54) },
    [10] = { label = "Ponto de Entrega 10", coords = vector3( 2906.86,  4381.43,  50.33) },
    [11] = { label = "Ponto de Entrega 11", coords = vector3( 3514.77,  3769.16,  29.94) },
    [12] = { label = "Ponto de Entrega 12", coords = vector3( 2810.16,  1582.28,  24.53) },
    [13] = { label = "Ponto de Entrega 13", coords = vector3(  838.47, -1976.72,  29.29) },
}

-- Rotas disponíveis
-- deliveryPoints: lista de IDs de Config.DeliveryPoints válidos para esta rota.
-- Se houver mais de um, um é escolhido aleatoriamente ao iniciar a missão.
Config.Routes = {
    {
        id           = 1,
        label        = "Sandy Shores → Porto de LS",
        company      = "transbrasil",
        origin       = { label = "Depósito Sandy Shores", coords = vector4(1813.15, 3680.85, 34.34, 245.0) },
        destination  = { label = "Porto de Los Santos" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "82 km",
        basePay      = 2000,
        baseXP       = 150,
        difficulty   = 1,
        timeLimit    = 20,
        allowedCargo = { "frutas", "graos" },
        minLevel     = 1,
    },
    {
        id           = 2,
        label        = "Paleto Bay → Los Santos",
        company      = "transbrasil",
        origin       = { label = "Fazenda Paleto",        coords = vector4(-266.83, 6330.88, 31.47, 180.0) },
        destination  = { label = "Mercado Central LS" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "110 km",
        basePay      = 2500,
        baseXP       = 200,
        difficulty   = 2,
        timeLimit    = 25,
        allowedCargo = { "frutas", "graos", "gado" },
        minLevel     = 1,
    },
    {
        id           = 3,
        label        = "Grapeseed → La Mesa",
        company      = "transbrasil",
        origin       = { label = "Armazém Grapeseed",    coords = vector4(1634.0, 4896.0, 42.0, 90.0) },
        destination  = { label = "La Mesa Industrial" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "65 km",
        basePay      = 1600,
        baseXP       = 120,
        difficulty   = 1,
        timeLimit    = 18,
        allowedCargo = { "frutas", "graos" },
        minLevel     = 1,
    },
    {
        id           = 4,
        label        = "Harmony → LS Centro",
        company      = "transbrasil",
        origin       = { label = "Depósito Harmony",     coords = vector4(568.0, 2706.0, 44.0, 180.0) },
        destination  = { label = "Distribuição Sul LS" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "58 km",
        basePay      = 1400,
        baseXP       = 110,
        difficulty   = 1,
        timeLimit    = 16,
        allowedCargo = { "frutas", "graos", "gado" },
        minLevel     = 1,
    },
    {
        id           = 5,
        label        = "LS → Refinaria Grand Senora",
        company      = "petrocargo",
        origin       = { label = "Terminal PetroCargo LS", coords = vector4(430.56, -2020.08, 21.43, 270.0) },
        destination  = { label = "Refinaria Grand Senora" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "75 km",
        basePay      = 3000,
        baseXP       = 200,
        difficulty   = 2,
        timeLimit    = 20,
        allowedCargo = { "combustivel" },
        minLevel     = 3,
    },
    {
        id           = 6,
        label        = "Refinaria → Porto de LS",
        company      = "petrocargo",
        origin       = { label = "Refinaria Grand Senora", coords = vector4(1170.0, 2650.0, 37.0, 150.0) },
        destination  = { label = "Porto de Los Santos" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "95 km",
        basePay      = 3500,
        baseXP       = 250,
        difficulty   = 3,
        timeLimit    = 22,
        allowedCargo = { "combustivel", "quimicos" },
        minLevel     = 3,
    },
    {
        id           = 7,
        label        = "LS → Chumash (Construção)",
        company      = "construlog",
        origin       = { label = "Depósito ConstroLog LS", coords = vector4(-160.0, -2020.0, 20.0, 0.0) },
        destination  = { label = "Canteiro Chumash" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "88 km",
        basePay      = 2200,
        baseXP       = 180,
        difficulty   = 2,
        timeLimit    = 22,
        allowedCargo = { "construcao", "madeira" },
        minLevel     = 2,
    },
    {
        id           = 8,
        label        = "Paleto → Fort Zancudo",
        company      = "construlog",
        origin       = { label = "Madeireira Paleto",      coords = vector4(-266.83, 6330.88, 31.47, 90.0) },
        destination  = { label = "Fort Zancudo" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "50 km",
        basePay      = 2800,
        baseXP       = 220,
        difficulty   = 2,
        timeLimit    = 16,
        allowedCargo = { "madeira", "maquinario" },
        minLevel     = 2,
    },
    {
        id           = 9,
        label        = "La Mesa → Sandy Shores",
        company      = "construlog",
        origin       = { label = "La Mesa Industrial",     coords = vector4(837.0, -1430.0, 26.0, 90.0) },
        destination  = { label = "Canteiro Sandy Shores" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "70 km",
        basePay      = 1800,
        baseXP       = 150,
        difficulty   = 1,
        timeLimit    = 18,
        allowedCargo = { "construcao", "maquinario" },
        minLevel     = 2,
    },
    {
        id           = 10,
        label        = "LS → Aeroporto (Eletrônicos)",
        company      = "megalog",
        origin       = { label = "MegaLog Warehouse LS",   coords = vector4(430.56, -2020.08, 21.43, 270.0) },
        destination  = { label = "Terminal LSIA" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "45 km",
        basePay      = 4000,
        baseXP       = 300,
        difficulty   = 3,
        timeLimit    = 15,
        allowedCargo = { "eletronicos", "farmaceuticos" },
        minLevel     = 5,
    },
    {
        id           = 11,
        label        = "Porto → Vinewood (Congelados)",
        company      = "megalog",
        origin       = { label = "Porto de Los Santos",    coords = vector4(-219.33, -2835.09, 6.00, 225.0) },
        destination  = { label = "Restaurante Vinewood" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "55 km",
        basePay      = 3200,
        baseXP       = 280,
        difficulty   = 3,
        timeLimit    = 14,
        allowedCargo = { "congelados" },
        minLevel     = 3,
    },
    {
        id           = 12,
        label        = "Grapeseed → Vinewood Hills",
        company      = "megalog",
        origin       = { label = "Armazém Grapeseed",     coords = vector4(1634.0, 4896.0, 42.0, 270.0) },
        destination  = { label = "Mansões Vinewood Hills" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "100 km",
        basePay      = 5000,
        baseXP       = 400,
        difficulty   = 4,
        timeLimit    = 25,
        allowedCargo = { "eletronicos", "farmaceuticos" },
        minLevel     = 7,
    },
    {
        id           = 13,
        label        = "Porto LS → Sandy Shores (Barcos)",
        company      = "megalog",
        origin       = { label = "Porto de Los Santos",    coords = vector4(-219.33, -2835.09, 6.00, 225.0) },
        destination  = { label = "Marina Sandy Shores" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "90 km",
        basePay      = 3500,
        baseXP       = 280,
        difficulty   = 3,
        timeLimit    = 22,
        allowedCargo = { "barcos" },
        minLevel     = 4,
    },
    {
        id           = 14,
        label        = "La Mesa → LSIA (Veículos)",
        company      = "megalog",
        origin       = { label = "Concessionária La Mesa", coords = vector4(837.0, -1430.0, 26.0, 90.0) },
        destination  = { label = "Terminal LSIA" },
        deliveryPoints = { 1,2,3,4,5,6,7,8,9,10,11,12,13 },
        distance     = "40 km",
        basePay      = 3800,
        baseXP       = 300,
        difficulty   = 3,
        timeLimit    = 14,
        allowedCargo = { "carros" },
        minLevel     = 4,
    },
}

-- Postos de despacho (NPCs no mapa)
Config.Dispatchers = {
    {
        id      = 1,
        label   = "Central de Cargas LS",
        coords  = vector4(1713.31, -1555.11, 113.94, 162.17),
        ped     = "s_m_y_construct_01",
        blip    = { sprite = 477, color = 3, label = "Central de Cargas" },
    },
    {
        id      = 2,
        label   = "Depósito Sandy Shores",
        coords  = vector4(919.59, 3655.35, 32.47, 2.49),
        ped     = "s_m_y_construct_01",
        blip    = { sprite = 477, color = 2, label = "Despacho Sandy Shores" },
    },
    {
        id      = 3,
        label   = "Terminal Paleto Bay",
        coords  = vector4(96.13, 6363.21, 31.38, 24.57),
        ped     = "s_m_y_construct_01",
        blip    = { sprite = 477, color = 2, label = "Terminal Paleto" },
    },
}
