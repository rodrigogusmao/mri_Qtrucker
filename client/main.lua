local isMenuOpen    = false
local activeJob     = nil
local dispatchPeds  = {}
local dispatchBlips = {}
local jobBlip       = nil
local conditionLoss = 0.0
local jobMonitorRunning = false
local rentedTruck      = nil  -- entidade do caminhão alugado atual
local rentedTruckPlate = nil  -- placa do caminhão alugado
local rentBlip         = nil  -- blip do caminhão alugado

local SPAWN_COORDS  = Config.TruckSpawn.coords
local SPAWN_HEADING = Config.TruckSpawn.heading
local SPAWN_RADIUS  = Config.TruckSpawn.radius

-- ─── Utilitários ──────────────────────────────────────────────────────────────

local function removeJobBlip()
    if jobBlip and DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
    jobBlip = nil
end

local function addJobBlip(coords, label)
    removeJobBlip()
    jobBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(jobBlip, 67)
    SetBlipColour(jobBlip, 5)
    SetBlipScale(jobBlip, 1.0)
    SetBlipAsShortRange(jobBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(jobBlip)
    SetBlipRoute(jobBlip, true)
    SetBlipRouteColour(jobBlip, 5)
end

-- ─── NUI ──────────────────────────────────────────────────────────────────────

local function openMenu()
    if isMenuOpen then return end
    local playerData = lib.callback.await('mri_Qtrucker:getPlayerData', false)
    local routes     = lib.callback.await('mri_Qtrucker:getRoutes', false)
    if not playerData then return end

    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type        = 'show',
        playerData  = playerData,
        routes      = routes,
        companies   = Config.Companies,
        cargo       = Config.CargoTypes,
        levels      = Config.Levels,
        accentColor = GetConvar('mri:color', '#00E699'),
        rentOptions     = Config.TruckRentOptions,
        hasRentedTruck  = rentedTruck ~= nil and DoesEntityExist(rentedTruck),
        activeJob   = activeJob and {
            routeId  = activeJob.routeId,
            cargoKey = activeJob.cargoKey,
        } or nil,
    })
end

local function closeMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
end

-- ─── HUD ──────────────────────────────────────────────────────────────────────

local function updateHUD()
    if not activeJob then
        SendNUIMessage({ type = 'hideHUD' })
        return
    end
    local elapsed   = GetGameTimer() / 1000 - activeJob.startTime
    local remaining = math.max(0, activeJob.timeLimit * 60 - elapsed)
    local mins      = math.floor(remaining / 60)
    local secs      = math.floor(remaining % 60)
    SendNUIMessage({
        type      = 'updateHUD',
        condition = math.floor(activeJob.condition),
        timeLeft  = string.format('%02d:%02d', mins, secs),
        elapsed   = elapsed,
        route     = activeJob.routeLabel,
        cargo     = activeJob.cargoLabel,
        cargoIcon = activeJob.cargoIcon,
    })
end

-- ─── Monitor de entrega ───────────────────────────────────────────────────────

local function startJobMonitor()
    if jobMonitorRunning then return end
    jobMonitorRunning = true

    CreateThread(function()
        local lastHealth = 1000.0
        while activeJob do
            local truck = GetVehiclePedIsIn(PlayerPedId(), false)
            if truck and truck ~= 0 and DoesEntityExist(truck) then
                -- Penalidade de velocidade
                local speedMs  = GetEntitySpeed(truck)
                local speedKmh = speedMs * 3.6
                if speedKmh > Config.MaxSafeSpeed then
                    activeJob.condition = math.max(0, activeJob.condition - Config.SpeedConditionLoss)
                end

                -- Penalidade de impacto
                local health = GetVehicleBodyHealth(truck)
                if health < lastHealth then
                    local diff = (lastHealth - health) / 1000.0
                    activeJob.condition = math.max(0, activeJob.condition - diff * Config.ImpactConditionLoss * 100)
                end
                lastHealth = health
            end

            updateHUD()
            Wait(500)
        end
        jobMonitorRunning = false
    end)
end

-- ─── Iniciar e completar ──────────────────────────────────────────────────────

function StartJob(routeId, cargoKey)
    if activeJob then
        lib.notify({ title = 'Atenção', description = 'Você já tem uma rota ativa.', type = 'warning' })
        return
    end

    local route = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == routeId then route = r break end
    end
    local cargo = Config.CargoTypes[cargoKey]
    if not route or not cargo then return end

    -- Escolhe ponto de entrega aleatório dentre os definidos na rota
    local pointIds = route.deliveryPoints or {}
    if #pointIds == 0 then
        lib.notify({ title = 'Erro', description = 'Rota sem pontos de entrega configurados.', type = 'error' })
        return
    end
    local point = Config.DeliveryPoints[pointIds[math.random(#pointIds)]]
    if not point then
        lib.notify({ title = 'Erro', description = 'Ponto de entrega inválido.', type = 'error' })
        return
    end

    local ok = SpawnAndAttachTrailer(cargo.trailer)
    if not ok then return end

    activeJob = {
        routeId     = routeId,
        cargoKey    = cargoKey,
        routeLabel  = route.label,
        cargoLabel  = cargo.label,
        cargoIcon   = cargo.icon,
        condition   = 100.0,
        startTime   = GetGameTimer() / 1000,
        timeLimit   = route.timeLimit,
        destination = point.coords,
        destLabel   = point.label,
    }

    addJobBlip(point.coords, point.label)

    -- Target no trailer para confirmar entrega no destino
    local trailer = GetActiveTrailer()
    if trailer and DoesEntityExist(trailer) then
        exports.ox_target:addLocalEntity(trailer, {
            {
                label    = 'Entregar a carga',
                icon     = 'fas fa-box-open',
                distance = 3.5,
                onSelect = function()
                    if not activeJob then return end

                    -- Verifica se o trailer está próximo do ponto de entrega
                    local tr      = GetActiveTrailer()
                    local tcoords = tr and DoesEntityExist(tr) and GetEntityCoords(tr) or GetEntityCoords(PlayerPedId())
                    local dest    = activeJob.destination
                    local dist    = #(vector3(tcoords.x, tcoords.y, tcoords.z) - vector3(dest.x, dest.y, dest.z))

                    if dist > Config.DeliveryRadius then
                        lib.notify({
                            title       = 'Destino incorreto',
                            description = 'Leve o trailer até ' .. activeJob.destLabel .. ' para entregar.',
                            type        = 'warning',
                        })
                        return
                    end

                    local done = lib.progressBar({
                        duration     = Config.DeliveryDuration,
                        label        = 'Descarregando carga...',
                        useWhileDead = false,
                        canCancel    = false,
                        disable      = { move = true, car = true, combat = true },
                    })
                    if done then CompleteDelivery() end
                end,
            }
        })
    end

    SendNUIMessage({
        type      = 'showHUD',
        route     = route.label,
        cargo     = cargo.label,
        cargoIcon = cargo.icon,
        condition = 100,
        timeLeft  = string.format('%02d:00', route.timeLimit),
    })

    lib.notify({
        title       = 'Rota Iniciada',
        description = string.format('Entregue: %s → %s', cargo.label, point.label),
        type        = 'info',
        duration    = 6000,
    })

    startJobMonitor()
end

function CompleteDelivery()
    if not activeJob then return end

    local elapsed = GetGameTimer() / 1000 - activeJob.startTime
    local job     = activeJob
    activeJob     = nil

    DetachAndDeleteTrailer()
    removeJobBlip()
    SendNUIMessage({ type = 'hideHUD' })

    TriggerServerEvent('mri_Qtrucker:completeDelivery', {
        routeId   = job.routeId,
        cargoKey  = job.cargoKey,
        condition = job.condition,
        elapsed   = elapsed,
    })
end

function CancelJob()
    if not activeJob then return end
    activeJob = nil
    DetachAndDeleteTrailer()
    removeJobBlip()
    SendNUIMessage({ type = 'hideHUD' })
    lib.notify({ title = 'Rota cancelada', description = 'Você abandonou a entrega.', type = 'error' })
end

-- ─── NUI Callbacks ────────────────────────────────────────────────────────────

RegisterNUICallback('closeMenu', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('startJob', function(data, cb)
    if not rentedTruck or not DoesEntityExist(rentedTruck) then
        rentedTruck = nil
        lib.notify({ title = 'Sem caminhão', description = 'Alugue um caminhão antes de iniciar uma rota.', type = 'warning' })
        cb('err'); return
    end
    closeMenu()
    Wait(300)
    StartJob(data.routeId, data.cargoKey)
    cb('ok')
end)

RegisterNUICallback('cancelJob', function(_, cb)
    closeMenu()
    CancelJob()
    cb('ok')
end)

local function clearRentBlip()
    if rentBlip and DoesBlipExist(rentBlip) then
        SetBlipRoute(rentBlip, false)
        RemoveBlip(rentBlip)
    end
    rentBlip = nil
end

RegisterNUICallback('rentTruck', function(data, cb)
    closeMenu()
    Wait(300)

    -- Condição 1: jogador já tem caminhão alugado
    if rentedTruck and DoesEntityExist(rentedTruck) then
        lib.notify({ title = 'Já alugado', description = 'Devolva seu caminhão atual antes de alugar outro.', type = 'warning' })
        cb('err'); return
    end
    rentedTruck = nil

    -- Condição 2: vaga de spawn ocupada
    local nearVeh = GetClosestVehicle(SPAWN_COORDS.x, SPAWN_COORDS.y, SPAWN_COORDS.z, SPAWN_RADIUS, 0, 70)
    if DoesEntityExist(nearVeh) then
        lib.notify({ title = 'Vaga ocupada', description = 'Há um veículo na vaga de entrega. Remova-o primeiro.', type = 'warning' })
        cb('err'); return
    end

    local model = data.model
    local price = data.price
    local hash  = GetHashKey(model)

    if not IsModelInCdimage(hash) then
        lib.notify({ title = 'Erro', description = 'Modelo inválido: ' .. model, type = 'error' })
        cb('err'); return
    end

    local ok, msg = lib.callback.await('mri_Qtrucker:rentTruck', false, { model = model })
    if not ok then
        lib.notify({ title = 'Sem dinheiro', description = msg or 'Não foi possível alugar.', type = 'error' })
        cb('err'); return
    end

    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do
        Wait(100); t = t + 100
        if t > 10000 then
            lib.notify({ title = 'Erro', description = 'Timeout ao carregar modelo.', type = 'error' })
            cb('err'); return
        end
    end

    local truck = CreateVehicle(hash, SPAWN_COORDS.x, SPAWN_COORDS.y, SPAWN_COORDS.z, SPAWN_HEADING, true, false)
    SetVehicleNumberPlateText(truck, ('TRUCK%04d'):format(math.random(1, 9999)))
    SetEntityAsMissionEntity(truck, true, true)
    SetModelAsNoLongerNeeded(hash)

    local plate = GetVehicleNumberPlateText(truck)
    SetVehicleDoorsLocked(truck, 1)
    exports['mri_Qcarkeys']:GiveTempKeys(plate)

    rentedTruck      = truck
    rentedTruckPlate = plate

    -- Blip temporário com rota, some ao entrar no caminhão
    clearRentBlip()
    rentBlip = AddBlipForEntity(truck)
    SetBlipSprite(rentBlip, 67)
    SetBlipColour(rentBlip, 3)
    SetBlipScale(rentBlip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Seu Caminhão')
    EndTextCommandSetBlipName(rentBlip)
    SetBlipRoute(rentBlip, true)
    SetBlipRouteColour(rentBlip, 3)

    CreateThread(function()
        while DoesEntityExist(truck) and GetVehiclePedIsIn(PlayerPedId(), false) ~= truck do
            Wait(500)
        end
        clearRentBlip()
    end)

    SendNUIMessage({ type = 'updateRentState', hasRentedTruck = true })

    lib.notify({
        title       = 'Caminhão Alugado!',
        description = ('R$ %d debitado — %s entregue. Placa: %s'):format(price, model, plate),
        type        = 'success',
        duration    = 6000,
    })
    cb('ok')
end)

RegisterNUICallback('returnTruck', function(_, cb)
    if not rentedTruck or not DoesEntityExist(rentedTruck) then
        rentedTruck      = nil
        rentedTruckPlate = nil
        clearRentBlip()
        SendNUIMessage({ type = 'updateRentState', hasRentedTruck = false })
        cb('ok'); return
    end

    if GetVehiclePedIsIn(PlayerPedId(), false) == rentedTruck then
        lib.notify({ title = 'Atenção', description = 'Saia do caminhão antes de devolvê-lo.', type = 'warning' })
        cb('err'); return
    end

    if rentedTruckPlate then
        exports['mri_Qcarkeys']:RemoveTempKeys(rentedTruckPlate)
        TriggerServerEvent('mm_carkeys:server:removevehiclekeys', rentedTruckPlate)
    end

    DeleteEntity(rentedTruck)
    rentedTruck      = nil
    rentedTruckPlate = nil
    clearRentBlip()

    SendNUIMessage({ type = 'updateRentState', hasRentedTruck = false })
    lib.notify({ title = 'Devolvido', description = 'Caminhão devolvido com sucesso.', type = 'success' })
    cb('ok')
end)

RegisterNUICallback('randomRoute', function(data, cb)
    local level = data.level or 1
    local route = GetRandomRoute(level)
    cb(route)
end)

RegisterNUICallback('getRanking', function(data, cb)
    local category = data.category or 'xp'
    local ranking = lib.callback.await('mri_Qtrucker:getRanking', false, category)
    cb(ranking)
end)

-- ─── Resultado da entrega (vindo do servidor) ─────────────────────────────────

RegisterNetEvent('mri_Qtrucker:deliveryResult', function(result)
    local msg = string.format(
        'Pagamento: R$ %s | XP: +%d | Condição: %d%%',
        tostring(result.pay), result.xp, result.condition
    )
    if result.timeBonus > 0 then
        msg = msg .. string.format(' | Bônus tempo: +R$ %s', tostring(result.timeBonus))
    end

    lib.notify({ title = '✅ Entrega Concluída!', description = msg, type = 'success', duration = 8000 })

    if result.leveledUp then
        Wait(1000)
        lib.notify({
            title       = '🎉 Nível Aumentado!',
            description = string.format('Você é agora %s (Nível %d)!', result.newLevelLabel, result.newLevel),
            type        = 'success',
            duration    = 6000,
        })
    end
end)

-- ─── Tecla F6: cancelar missão + devolver caminhão ───────────────────────────

RegisterCommand('mri_trucker_f6', function()
    local hasTruck = rentedTruck and DoesEntityExist(rentedTruck)
    local hasJob   = activeJob ~= nil

    if not hasTruck and not hasJob then
        lib.notify({ title = 'Trucker', description = 'Sem missão ou caminhão ativo.', type = 'inform' })
        return
    end

    if hasJob then
        activeJob = nil
        DetachAndDeleteTrailer()
        removeJobBlip()
        SendNUIMessage({ type = 'hideHUD' })
    end

    if hasTruck then
        if rentedTruckPlate then
            exports['mri_Qcarkeys']:RemoveTempKeys(rentedTruckPlate)
            TriggerServerEvent('mm_carkeys:server:removevehiclekeys', rentedTruckPlate)
        end
        DeleteEntity(rentedTruck)
        rentedTruck      = nil
        rentedTruckPlate = nil
        clearRentBlip()
        SendNUIMessage({ type = 'updateRentState', hasRentedTruck = false })
    end

    local parts = {}
    if hasJob   then parts[#parts + 1] = 'rota cancelada' end
    if hasTruck then parts[#parts + 1] = 'caminhão devolvido' end
    lib.notify({ title = 'F6 — Encerrado', description = table.concat(parts, ' · ') .. '.', type = 'inform' })
end, false)

RegisterKeyMapping('mri_trucker_f6', 'Trucker: cancelar missão e devolver caminhão', 'keyboard', 'F6')

-- ─── Despachantes ─────────────────────────────────────────────────────────────

local function spawnDispatcher(dispatcher)
    local hash = GetHashKey(dispatcher.ped)

    if not IsModelInCdimage(hash) then
        print(('[mri_Qtrucker] Modelo de ped inválido: %s'):format(dispatcher.ped))
        return
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            print(('[mri_Qtrucker] Timeout ao carregar modelo: %s'):format(dispatcher.ped))
            return
        end
    end

    local c   = dispatcher.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w, false, true)

    if not DoesEntityExist(ped) then
        print(('[mri_Qtrucker] Falha ao criar NPC em %.2f, %.2f, %.2f'):format(c.x, c.y, c.z))
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    PlaceObjectOnGroundProperly(ped)
    SetModelAsNoLongerNeeded(hash)
    dispatchPeds[#dispatchPeds + 1] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            label    = dispatcher.label,
            icon     = 'fas fa-truck',
            distance = 3.0,
            onSelect = function() openMenu() end,
        }
    })

    local c2  = dispatcher.coords
    local blip = AddBlipForCoord(c2.x, c2.y, c2.z)
    SetBlipSprite(blip, dispatcher.blip.sprite)
    SetBlipColour(blip, dispatcher.blip.color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(dispatcher.blip.label)
    EndTextCommandSetBlipName(blip)
    dispatchBlips[#dispatchBlips + 1] = blip

    print(('[mri_Qtrucker] NPC criado: %s'):format(dispatcher.label))
end

CreateThread(function()
    Wait(2000)
    for _, d in ipairs(Config.Dispatchers) do
        spawnDispatcher(d)
        Wait(200)
    end
end)

-- ─── Limpeza ──────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(dispatchPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(dispatchBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    removeJobBlip()
    clearRentBlip()
    if rentedTruck and DoesEntityExist(rentedTruck) then
        if rentedTruckPlate then
            exports['mri_Qcarkeys']:RemoveTempKeys(rentedTruckPlate)
            TriggerServerEvent('mm_carkeys:server:removevehiclekeys', rentedTruckPlate)
        end
        DeleteEntity(rentedTruck)
    end
    rentedTruck      = nil
    rentedTruckPlate = nil
    if activeJob then DetachAndDeleteTrailer() end
    closeMenu()
end)
