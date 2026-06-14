local function dbGetPlayer(citizenid)
    return MySQL.single.await('SELECT * FROM mri_qtrucker_players WHERE citizenid = ?', { citizenid })
end

local function dbCreatePlayer(citizenid)
    MySQL.insert.await('INSERT INTO mri_qtrucker_players (citizenid) VALUES (?)', { citizenid })
    return { citizenid = citizenid, xp = 0, level = 1, total_deliveries = 0, total_earned = 0, history = '[]' }
end

local function loadPlayer(citizenid)
    local data = dbGetPlayer(citizenid)
    if not data then data = dbCreatePlayer(citizenid) end
    data.history = json.decode(data.history or '[]')
    return data
end

local function savePlayer(data)
    MySQL.update.await(
        'UPDATE mri_qtrucker_players SET xp=?, level=?, total_deliveries=?, total_earned=?, history=? WHERE citizenid=?',
        { data.xp, data.level, data.total_deliveries, data.total_earned, json.encode(data.history), data.citizenid }
    )
end

lib.callback.register('mri_Qtrucker:getPlayerData', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)
    data.level  = level
    data.xpProgress    = GetXPProgress(data.xp)
    data.xpToNextLevel = GetXPToNextLevel(data.xp)
    data.levelData     = Config.Levels[level]
    return data
end)

lib.callback.register('mri_Qtrucker:getRoutes', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local data  = dbGetPlayer(player.PlayerData.citizenid)
    local xp    = data and data.xp or 0
    local level = GetPlayerLevel(xp)
    return GetAvailableRoutes(level)
end)

lib.callback.register('mri_Qtrucker:rentTruck', function(source, data)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, 'Jogador não encontrado' end

    local option = nil
    for _, opt in ipairs(Config.TruckRentOptions) do
        if opt.model == data.model then option = opt break end
    end
    if not option then return false, 'Modelo inválido' end

    local price = option.price
    local cash  = player.PlayerData.money['cash']
    local bank  = player.PlayerData.money['bank']

    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'mri_qtrucker-rent')
        return true
    elseif bank >= price then
        player.Functions.RemoveMoney('bank', price, 'mri_qtrucker-rent')
        return true
    end

    return false, 'Dinheiro insuficiente'
end)

RegisterNetEvent('mri_Qtrucker:completeDelivery', function(payload)
    local src    = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local routeId   = payload.routeId
    local cargoKey  = payload.cargoKey
    local condition = math.max(0, math.min(100, payload.condition))
    local elapsed   = payload.elapsed

    local route = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == routeId then route = r break end
    end
    local cargo = Config.CargoTypes[cargoKey]
    if not route or not cargo then return end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)
    local mult  = Config.Levels[level].multiplier

    -- Pagamento base (aleatório dentro da faixa do cargo + rota)
    local routeBase = math.random(route.basePay, math.floor(route.basePay * 1.3))
    local cargoBase = math.random(cargo.minPay, cargo.maxPay)
    local basePay   = math.floor(((routeBase + cargoBase) / 2) * mult)

    -- Penalidade de condição da carga
    local condMult = condition / 100
    basePay = math.floor(basePay * condMult)

    -- Bônus de tempo
    local timeBonus = 0
    if elapsed <= (route.timeLimit * 60) then
        timeBonus = math.floor(basePay * Config.TimeBonusPercent)
    end

    local totalPay = basePay + timeBonus

    -- XP
    local xpGained = route.baseXP + cargo.baseXP
    if elapsed <= (route.timeLimit * 60) then
        xpGained = math.floor(xpGained * 1.25)
    end
    if condition >= 90 then xpGained = math.floor(xpGained * 1.10) end

    -- Atualizar dados
    local oldLevel  = level
    data.xp              = data.xp + xpGained
    data.total_deliveries = data.total_deliveries + 1
    data.total_earned    = data.total_earned + totalPay
    data.level           = GetPlayerLevel(data.xp)

    -- Histórico (últimas 20)
    local entry = {
        route     = route.label,
        cargo     = cargo.label,
        pay       = totalPay,
        xp        = xpGained,
        condition = condition,
        bonus     = timeBonus,
        date      = os.date('%d/%m %H:%M'),
    }
    table.insert(data.history, 1, entry)
    if #data.history > 20 then table.remove(data.history) end

    savePlayer(data)
    player.Functions.AddMoney('cash', totalPay, 'trucker-delivery')

    TriggerClientEvent('mri_Qtrucker:deliveryResult', src, {
        pay       = totalPay,
        timeBonus = timeBonus,
        xp        = xpGained,
        condition = condition,
        leveledUp = data.level > oldLevel,
        newLevel  = data.level,
        newLevelLabel = Config.Levels[data.level] and Config.Levels[data.level].label or '',
        totalXP   = data.xp,
    })
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mri_qtrucker_players` (
            `citizenid`         VARCHAR(50) NOT NULL,
            `xp`                INT NOT NULL DEFAULT 0,
            `level`             INT NOT NULL DEFAULT 1,
            `total_deliveries`  INT NOT NULL DEFAULT 0,
            `total_earned`      BIGINT NOT NULL DEFAULT 0,
            `history`           LONGTEXT,
            `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)
