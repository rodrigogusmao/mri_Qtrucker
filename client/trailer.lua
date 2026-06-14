local activeTrailer = nil
local activeTruck   = nil

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        t = t + 100
        if t > 10000 then return nil end
    end
    return hash
end

local TRAILER_SPAWN = Config.TrailerSpawn

function SpawnAndAttachTrailer(trailerModel)
    -- suporte a múltiplos modelos: escolhe aleatoriamente
    if type(trailerModel) == 'table' then
        trailerModel = trailerModel[math.random(#trailerModel)]
    end

    local hash = loadModel(trailerModel)
    if not hash then
        lib.notify({ title = 'Erro', description = 'Modelo de trailer não encontrado: ' .. trailerModel, type = 'error' })
        return false
    end

    local trailer = CreateVehicle(hash, TRAILER_SPAWN.x, TRAILER_SPAWN.y, TRAILER_SPAWN.z, TRAILER_SPAWN.w, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    SetVehicleOnGroundProperly(trailer)
    SetModelAsNoLongerNeeded(hash)

    activeTrailer = trailer
    activeTruck   = nil

    lib.notify({ title = 'Carga Pronta', description = 'Seu trailer foi posicionado. Acople-o ao caminhão e siga para o destino.', type = 'info', duration = 6000 })
    return true
end

function DetachAndDeleteTrailer()
    if activeTrailer and DoesEntityExist(activeTrailer) then
        exports.ox_target:removeLocalEntity(activeTrailer)
        DetachVehicleFromTrailer(activeTruck)
        Wait(200)
        DeleteEntity(activeTrailer)
    end
    activeTrailer = nil
    activeTruck   = nil
end

function GetActiveTrailer()  return activeTrailer  end
function GetActiveTruck()    return activeTruck    end
function IsTrailerAttached() return activeTrailer ~= nil and DoesEntityExist(activeTrailer) end
