-- ============================================================================
-- MOON PAYLOAD - CODE COMPLET ET UNIFIÉ DE A À Z (Luraph v15.1 -> Luau Clair)
-- ============================================================================

-- ============================================================================
-- [1] SERVICES & UTILITAIRES DE BASE (zVJ[75], zVJ[56], zVJ[125], zVJ[8810]...)
-- ============================================================================

-- zVJ[75] : Récupération sécurisée d'un service Roblox via cloneref
local function GetService(serviceName)
    return cloneref(game:GetService(serviceName))
end

local Services = {
    Players = GetService("Players"),
    UserInputService = GetService("UserInputService"),
    SoundService = GetService("SoundService"),
    Debris = GetService("Debris"),
    TweenService = GetService("TweenService"),
    HttpService = GetService("HttpService"),
    Lighting = GetService("Lighting"),
    RunService = GetService("RunService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Lighting = Services.Lighting

-- Structures globales partagées entre les fermetures (Upvalues)
local UI = {
    Flags = {},
    Theme = { Accent = Color3.fromRGB(126, 192, 255) },
}
local Flags = UI.Flags
local Client = {
    Snapshot = nil,
    Static = nil,
    WeaponData = nil,
    PrevSim = nil,
    SilentPoint = nil,
}
local ESP = {
    Drawings = {},
}

local CurrentCamera = workspace.CurrentCamera
local CameraConnections = {}

-- zVJ[56] : Création d'instance Roblox avec application d'une table de propriétés
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, val in pairs(properties) do
        instance[prop] = val
    end
    return instance
end

-- zVJ[125] : Vérifie si une valeur est présente dans une table
local function TableContains(tbl, value)
    local found = type(tbl) == "table" and table.find(tbl, value) ~= nil
    return found
end

-- zVJ[10716] : Détruit toutes les instances d'une table et la vide
local function DestroyAllInstancesInTable(instanceTable)
    for key, inst in pairs(instanceTable) do
        inst:Destroy()
        instanceTable[key] = nil
    end
end

-- zVJ[8810] : Conversion d'une chaîne "Enum.Category.Item" en Enum Roblox avec mise en cache
local EnumCache = {}
local function ParseEnum(enumString)
    if type(enumString) ~= "string" then
        return nil
    end
    local cached = EnumCache[enumString]
    if cached ~= nil then
        return cached or nil
    end
    local category, item = enumString:match("^Enum%.(%a+)%.(%w+)$")
    local success, result = pcall(function()
        return Enum[category][item]
    end)
    EnumCache[enumString] = success and result or false
    return success and result or nil
end

-- zVJ[22] : Nettoyage inversé d'une liste avant l'appel d'un callback final
local function CleanupAndFinish(cleanupList, cleanupFn, finalCallback)
    return function(arg)
        local count = #cleanupList
        for i = count, 1, -1 do
            cleanupFn(cleanupList[i])
        end
        return finalCallback(arg)
    end
end

-- zVJ[57], zVJ[590], zVJ[15705] : Wrappers d'exécution de fonctions internes
local function CallWrappedFunction(fnRef)
    return function()
        fnRef()
    end
end

local function InvokeCallbackWrapper1(fnRef, argRef)
    return function()
        fnRef(argRef)
    end
end

local function InvokeCallbackWrapper2(fnRef, argRef)
    return function()
        fnRef(argRef)
    end
end

-- zVJ[1003] : Générateur congruentiel linéaire (PRNG interne)
local prngInitialized = false
local prngCounter = 0
local prngSeed = 0
local function AdvancePRNGState()
    prngInitialized = true
    prngCounter = prngCounter - (prngCounter % 2) + 1
    prngSeed = (845713 * prngSeed + 219367747) % 268435456
    prngSeed = (886037 * prngSeed + 248922623) % 268435456
end

-- zVJ[14780] : Permutation ChaCha20 utilisée par le déchiffrage interne
local function ChaChaQuarterRoundCore(scheduleTable)
    return function(state, rounds)
        for _ = 1, rounds, 2 do
            for i = 1, 32, 4 do
                local aIdx = scheduleTable[i]
                local bIdx = scheduleTable[i + 1]
                local cIdx = scheduleTable[i + 2]
                local dIdx = scheduleTable[i + 3]

                local a, b, c, d = state[aIdx], state[bIdx], state[cIdx], state[dIdx]

                a = (a + b) % 4294967296
                local x = bit32.bxor(d, a)
                d = bit32.bor(bit32.lshift(x, 16), bit32.rshift(x, 16)) % 4294967296

                c = (c + d) % 4294967296
                x = bit32.bxor(b, c)
                b = bit32.bor(bit32.lshift(x, 12), bit32.rshift(x, 20)) % 4294967296

                a = bit32.band(a + b, 4294967295)
                x = bit32.bxor(d, a)
                d = bit32.bor(bit32.lshift(x, 8), bit32.rshift(x, 24)) % 4294967296

                c = (c + d) % 4294967296
                x = bit32.bxor(b, c)
                b = bit32.bor(bit32.lshift(x, 7), bit32.rshift(x, 25)) % 4294967296

                state[aIdx], state[bIdx], state[cIdx], state[dIdx] = a, b, c, d
            end
        end
    end
end

-- ============================================================================
-- [2] GESTION DES TOUCHES (KEYBINDS), CURSEUR & CAMÉRA (zVJ[46], zVJ[5167]...)
-- ============================================================================

-- zVJ[46] : Connexion des événements UserInputService pour un Keybind (Hold / Toggle)
local function BindKey(keybindObject, flagName)
    local UserInputService = Services.UserInputService

    local function MatchesKey(input)
        return keybindObject.Value ~= "None"
            and UI.Flags[flagName]
            and (tostring(input.KeyCode) == keybindObject.Key or tostring(input.UserInputType) == keybindObject.Key)
    end

    local function OnInputBegan(input, isRelevant)
        if isRelevant and MatchesKey(input) then
            if keybindObject.Mode == "Hold" then
                keybindObject:Press(true)
            elseif keybindObject.Mode == "Toggle" then
                keybindObject:Press()
            end
        end
    end
    UI:Connect(UserInputService.InputBegan, OnInputBegan)

    local function OnInputEnded(input, isRelevant)
        if isRelevant and keybindObject.Mode == "Hold" and MatchesKey(input) then
            keybindObject:Press(false)
        end
    end
    UI:Connect(UserInputService.InputEnded, OnInputEnded)
end

-- zVJ[4616] : Vérifie si une option et son raccourci clavier associé sont actifs
local function IsFeatureAndKeyActive(flagName, keybindFlagName)
    return Flags[flagName] == true and Client.KeyOn ~= nil and Client.KeyOn(keybindFlagName) == true
end

-- zVJ[6603] : Vérifie si une option mappée et son raccourci "<nom>kb" sont actifs
local KeybindFeatureMap = {}
local function IsMappedKeybindActive(key)
    local flagName = KeybindFeatureMap[key]
    return Flags[flagName] == true and Client.KeyOn ~= nil and Client.KeyOn(flagName .. "kb") == true
end

local function IsKeybindActive(keybindFlagName)
    return Client.KeyOn == nil or Client.KeyOn(keybindFlagName) == true
end

-- zVJ[7696] : Met à jour la position du curseur personnalisé
local CustomCursorOuter, CustomCursorDot
local function UpdateCustomCursorPosition()
    local mousePos = Services.UserInputService:GetMouseLocation()
    if CustomCursorOuter then
        CustomCursorOuter.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
    end
end

-- zVJ[5167] : Affiche ou masque le curseur personnalisé de l'interface
local savedMouseIconEnabled = true
local cursorMoveConnection = nil
local function SetCustomCursorVisible(visible)
    if CustomCursorOuter then CustomCursorOuter.Visible = visible end
    if CustomCursorDot then CustomCursorDot.Visible = visible end
    if visible then
        savedMouseIconEnabled = Services.UserInputService.MouseIconEnabled
        Services.UserInputService.MouseIconEnabled = false
        if CustomCursorDot then
            CustomCursorDot.BackgroundColor3 = UI.Theme.Accent
        end
        UpdateCustomCursorPosition()
        cursorMoveConnection = cursorMoveConnection or Services.UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateCustomCursorPosition()
            end
        end)
    else
        Services.UserInputService.MouseIconEnabled = savedMouseIconEnabled
        if cursorMoveConnection then
            cursorMoveConnection:Disconnect()
            cursorMoveConnection = nil
        end
    end
end

-- zVJ[8552] : Abonnement aux changements de caméra (FieldOfView, ViewportSize)
local function BindCameraSignals(onCameraUpdated)
    for _, conn in ipairs(CameraConnections) do
        conn:Disconnect()
    end
    table.clear(CameraConnections)
    CurrentCamera = workspace.CurrentCamera
    if CurrentCamera then
        local watchedProperties = { "FieldOfView", "ViewportSize" }
        for _, prop in ipairs(watchedProperties) do
            table.insert(CameraConnections, CurrentCamera:GetPropertyChangedSignal(prop):Connect(onCameraUpdated))
        end
    end
    onCameraUpdated()
end

-- ============================================================================
-- [3] FONCTIONS D'ÉTAT DU JOUEUR & SKINS (zVJ[16], zVJ[108], zVJ[91], zVJ[53]...)
-- ============================================================================

-- zVJ[16] : Nom du joueur local
local function GetLocalPlayerName()
    return Services.Players.LocalPlayer.Name
end

-- zVJ[108] : Vérifie si une entité correspond au joueur local
local function IsLocal(entity)
    return entity.UserId == LocalPlayer.UserId
end
Client.IsLocal = IsLocal

-- zVJ[91] : Vérifie si une entité est un ennemi
local function IsEnemy(entity)
    local myTeam, theirTeam = LocalPlayer:GetAttribute("Team"), entity.Team
    return not (myTeam and theirTeam and myTeam == theirTeam)
end
Client.IsEnemy = IsEnemy

-- zVJ[96] : Vérifie si une entité est cachée ou sous la carte (Y < -100000)
local function IsHidden(entity, rootPart)
    return entity.Hidden or rootPart.Position.Y < -100000
end
Client.IsHidden = IsHidden

-- zVJ[28] : Vérifie si une BasePart est suffisamment opaque
local function IsPartOpaque(part)
    if part.Transparency >= 0.5 then
        return false
    end
    return true
end

-- zVJ[6299] : Vérifie si le joueur tient une arme à feu
local function HoldingGun()
    local snap = Client.Snapshot
    return snap ~= nil and snap.isGun == true
end
Client.HoldingGun = HoldingGun

-- zVJ[53] : Rafraîchit la liste des skins de couteau dans le menu
local WeaponSkinsTable = {}
local isRefreshingSkins = false
local SkinDropdownControl = nil
local function RefreshKnifeSkinList(knifeType)
    local options = { "Default" }
    local availableSkins = WeaponSkinsTable[knifeType ~= "Default" and knifeType or "T Knife"] or {}
    for _, skinName in ipairs(availableSkins) do
        options[#options + 1] = skinName
    end
    isRefreshingSkins = true
    if SkinDropdownControl then
        SkinDropdownControl:Refresh(options)
        SkinDropdownControl:Set("Default")
    end
    isRefreshingSkins = false
end

-- ============================================================================
-- [4] FONCTIONS MATHÉMATIQUES 3D, RAYCAST OBB & PONT CLIENT
-- ============================================================================

local WallRaycastParams = RaycastParams.new()
WallRaycastParams.FilterType = Enum.RaycastFilterType.Include
local currentMapGeometry = nil

local ChamsBodyPartNames = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function NormalizeYawDelta(angleDeg)
    return (angleDeg + 180) % 360 - 180
end

-- Intersection analytique Rayon / Boîte englobante orientée (OBB)
local function IntersectRayOBB(boxCFrame, halfExtents, rayOrigin, rayDirection)
    local localOrigin = boxCFrame:PointToObjectSpace(rayOrigin)
    local localDir = boxCFrame:VectorToObjectSpace(rayDirection)
    local tMin, tMax = 0, 1

    if math.abs(localDir.X) < 1e-6 then
        if localOrigin.X < -halfExtents.X or localOrigin.X > halfExtents.X then return nil end
    else
        local invD = 1 / localDir.X
        local t1 = (-halfExtents.X - localOrigin.X) * invD
        local t2 = (halfExtents.X - localOrigin.X) * invD
        if t1 > t2 then t1, t2 = t2, t1 end
        tMin, tMax = math.max(tMin, t1), math.min(tMax, t2)
        if tMin > tMax then return nil end
    end

    if math.abs(localDir.Y) < 1e-6 then
        if localOrigin.Y < -halfExtents.Y or localOrigin.Y > halfExtents.Y then return nil end
    else
        local invD = 1 / localDir.Y
        local t1 = (-halfExtents.Y - localOrigin.Y) * invD
        local t2 = (halfExtents.Y - localOrigin.Y) * invD
        if t1 > t2 then t1, t2 = t2, t1 end
        tMin, tMax = math.max(tMin, t1), math.min(tMax, t2)
        if tMin > tMax then return nil end
    end

    if math.abs(localDir.Z) < 1e-6 then
        if localOrigin.Z < -halfExtents.Z or localOrigin.Z > halfExtents.Z then return nil end
    else
        local invD = 1 / localDir.Z
        local t1 = (-halfExtents.Z - localOrigin.Z) * invD
        local t2 = (halfExtents.Z - localOrigin.Z) * invD
        if t1 > t2 then t1, t2 = t2, t1 end
        tMin, tMax = math.max(tMin, t1), math.min(tMax, t2)
        if tMin > tMax then return nil end
    end

    return tMin
end

local function RefreshGeometryFilter()
    local map = workspace:FindFirstChild("Map")
    local geo = map and map:FindFirstChild("Geometry")
    if currentMapGeometry ~= geo then
        currentMapGeometry = geo
        WallRaycastParams.FilterDescendantsInstances = geo and { geo } or {}
    end
end

local function IsLineOfSightClear(origin, targetPoint)
    RefreshGeometryFilter()
    local hit = workspace:Raycast(origin, targetPoint - origin, WallRaycastParams)
    return hit == nil
end

function Client.GetSimulation()
    return Client.Snapshot and Client.Snapshot.sim or nil
end

function Client.EyePosition(sim)
    return (sim and sim.Eye) or (CurrentCamera and CurrentCamera.CFrame.Position) or Vector3.zero
end

function Client.ShotCFrame(sim, yawDeg, pitchDeg)
    local eye = Client.EyePosition(sim)
    local rot = CFrame.Angles(0, math.rad(yawDeg or 0), 0) * CFrame.Angles(math.rad(pitchDeg or 0), 0, 0)
    return CFrame.new(eye) * rot
end

function Client.ShotLook(sim, yawDeg, pitchDeg)
    return Client.ShotCFrame(sim, yawDeg, pitchDeg).LookVector
end

function Client.SolveAngles(targetPos, eyePos)
    local dir = (targetPos - eyePos).Unit
    local yaw = math.deg(math.atan2(-dir.X, -dir.Z))
    local pitch = math.deg(math.asin(math.clamp(dir.Y, -1, 1)))
    return yaw, pitch
end

function Client.RecoilComp()
    local snap = Client.Snapshot
    if not snap then return 0, 0 end
    return (snap.aimPunchYaw or 0) * 2, (snap.aimPunchPitch or 0) * 2
end

function Client.Trans(colorFlagName, extraFade)
    local picker = Flags[colorFlagName]
    local baseAlpha = (picker and picker.Alpha) or 0
    if extraFade then
        return baseAlpha + (1 - baseAlpha) * extraFade
    end
    return baseAlpha
end

function Client.GetPlayer(entity)
    if entity.UserId then
        return Services.Players:GetPlayerByUserId(entity.UserId)
    end
    return Services.Players:FindFirstChild(entity.Name or "")
end

function Client.SendCommand(cmdName, ...)
    if Client.CommandHandler then
        Client.CommandHandler(cmdName, ...)
    end
end

local function ForEachValidEnemy(callback)
    local snap = Client.Snapshot
    if not (snap and snap.entities) then return end
    for idx, entity in ipairs(snap.entities) do
        if entity.Model and entity.Model.Parent and not entity.Hidden and not Client.IsLocal(entity) then
            local hp = entity.Health
            if hp and hp > 0 and Client.IsEnemy(entity) then
                callback(idx, entity)
            end
        end
    end
end

local function BuildTargetHitboxList(eyePos, lookVec)
    local list = {}
    ForEachValidEnemy(function(_, entity)
        local partsList = {}
        for _, partName in ipairs(ChamsBodyPartNames) do
            local part = entity.Model:FindFirstChild(partName)
            if part then
                table.insert(partsList, {
                    Name = partName,
                    Part = part,
                    Offset = Vector3.zero,
                })
            end
        end
        if #partsList > 0 then
            local plr = Client.GetPlayer(entity)
            table.insert(list, {
                Id = entity.Id,
                Armor = plr and (plr:GetAttribute("ArmorValue") or 0) or (entity.Armor or 0),
                Helmet = plr and (plr:GetAttribute("HasHelmet") == true) or (entity.Helmet == true),
                Parts = partsList,
            })
        end
    end)
    return list
end

local function ResolveHitboxList(selectedParts)
    if type(selectedParts) == "table" and #selectedParts > 0 then
        return selectedParts
    end
    return { "Head", "UpperTorso", "LowerTorso" }
end

-- ============================================================================
-- [5] BALISTIQUE, AUTOWALL & HITCHANCE (zVJ[13436], zVJ[2830], zVJ[16299], zVJ[4373], zVJ[1034])
-- ============================================================================

local forwardHitDistances = {}
local backwardHitDistances = {}
local backwardHitResults = {}
local MaterialOverrides = {}

-- zVJ[13436] : Récupère le matériau et le modificateur de pénétration d'un RaycastResult
local function GetMaterialModifier(raycastResult)
    local static = Client.Static
    local variant = static.Variants[raycastResult.Instance.MaterialVariant]
    if variant then
        return variant.Material, variant.Modifier or static.Materials[variant.Material] or static.Materials.Default
    end
    local matName = raycastResult.Material.Name
    return matName, static.Materials[matName] or static.Materials.Default
end

-- zVJ[2830] : Applique la réduction de dégâts liée au kevlar et au casque
local function ApplyArmorReduction(damage, hitboxName, armorValue, hasHelmet, weaponData, staticData)
    local armorRules = staticData.HitboxArmorApply
    local appliesArmor = armorValue > 0 and armorRules and armorRules.ApplyArmor[hitboxName]
    local isProtected = false

    if appliesArmor then
        local requiresHelmet = armorRules.RequireHelmet[hitboxName]
        isProtected = if requiresHelmet then hasHelmet else not requiresHelmet
    else
        isProtected = appliesArmor
    end

    if isProtected then
        local ratio = staticData.ArmorRatioDivisor * (weaponData.ArmorRatio or 1)
        if armorValue < (damage - damage * ratio) * staticData.ArmorBonusMultiplier then
            damage = damage - armorValue / staticData.ArmorBonusMultiplier
        else
            damage = damage * ratio
        end
    end
    return math.floor(damage)
end

-- zVJ[16299] : Détermine le point de sortie exact d'un mur lors d'une pénétration
local function TraceWallExit(entryPoint, direction, maxThickness)
    WallRaycastParams.FilterDescendantsInstances = currentMapGeometry and { currentMapGeometry } or {}
    local totalSteps = math.ceil(maxThickness / 0.2776) + 1
    local maxDistance = totalSteps * 0.2776
    local curForwardDist = 0.001
    local forwardCount = 0

    for _ = 1, 16 do
        local hit = workspace:Raycast(entryPoint + direction * curForwardDist, direction * (maxDistance - curForwardDist), WallRaycastParams)
        if not hit then
            break
        end
        local dist = curForwardDist + hit.Distance
        forwardCount += 1
        forwardHitDistances[forwardCount] = dist
        curForwardDist = dist + 0.001
        if maxDistance <= curForwardDist then
            break
        end
    end

    local curBackwardDist = maxDistance
    local backwardCount = 0
    for _ = 1, 16 do
        local hit = curBackwardDist > 0.001 and workspace:Raycast(entryPoint + direction * curBackwardDist, direction * -(curBackwardDist - 0.001), WallRaycastParams)
        if not hit then
            break
        end
        local dist = curBackwardDist - hit.Distance
        backwardCount += 1
        backwardHitDistances[backwardCount] = dist
        backwardHitResults[backwardCount] = hit
        curBackwardDist = dist - 0.001
    end

    local fIdx, solidDepth = 1, 1
    local exitHit = nil
    for step = 1, totalSteps do
        local checkDist = step * 0.2776
        while fIdx <= forwardCount and forwardHitDistances[fIdx] <= checkDist do
            solidDepth += 1
            fIdx += 1
        end
        while backwardCount >= 1 and backwardHitDistances[backwardCount] <= checkDist do
            solidDepth -= 1
            exitHit = backwardHitResults[backwardCount]
            backwardCount -= 1
        end
        if solidDepth <= 0 then
            break
        end
    end

    table.clear(backwardHitResults)
    return solidDepth <= 0 and exitHit or nil
end

-- zVJ[4373] : Simulation complète de tir avec pénétration jusqu'à 4 murs (AutoWall)
local function SimulateBulletPenetration(origin, direction, targetDist, hitboxName, targetInfo)
    local static, weapon = Client.Static, Client.WeaponData
    if not (static and weapon and weapon.Damage) then
        return nil
    end

    local currentDamage = weapon.Damage
    local penetration = weapon.Penetration or 0
    local rangeModifier = weapon.RangeModifier or 1
    local maxRange = weapon.Range or 500
    local wallsRemaining = 4
    local currentOrigin = origin
    local distanceTraveled = 0

    while wallsRemaining > 0 do
        local distToTarget = targetDist - (currentOrigin - origin).Magnitude
        local hit = workspace:Raycast(currentOrigin, direction * (maxRange - distanceTraveled), WallRaycastParams)

        if not hit or hit.Distance >= distToTarget then
            local remRange = maxRange - distanceTraveled
            local falloffDmg = currentDamage * rangeModifier ^ ((distanceTraveled + distToTarget * (remRange / (remRange + 2.776))) / static.DistanceFallOff)
            local hitboxMults = weapon.HitboxMultipliers
            local scaledDmg = falloffDmg * (hitboxMults and hitboxMults[hitboxName] or static.HitboxMultipliers[hitboxName] or 1)
            return ApplyArmorReduction(scaledDmg, hitboxName, targetInfo.Armor, targetInfo.Helmet, weapon, static)
        end

        distanceTraveled += hit.Distance
        if hit.Instance.Name == "nowallbang" or distanceTraveled > static.StartDistance or penetration <= 0 then
            return nil
        end

        local dmgAtEntry = currentDamage * rangeModifier ^ (distanceTraveled / static.DistanceFallOff)
        local exitHit = TraceWallExit(hit.Position, direction, static.MaxThickness)
        if not exitHit then
            return nil
        end

        local enterMat, enterMod = GetMaterialModifier(hit)
        local exitMat, exitMod = GetMaterialModifier(exitHit)
        if enterMod < 0.1 then
            return nil
        end

        local isGlass = enterMat == "Glass"
        local combinedMod = isGlass and 3 or (enterMod + exitMod) / 2
        if enterMat == exitMat then
            combinedMod = MaterialOverrides[enterMat] or combinedMod
        end

        local invMod = 1 / combinedMod
        local wallThickness = (exitHit.Position - hit.Position).Magnitude
        local dmgLost = dmgAtEntry * (isGlass and 0.05 or 0.16)
            + math.max(0, 3 / penetration * 1.25) * (invMod * 3)
            + invMod * wallThickness * wallThickness / static.LossDivisor

        currentDamage = dmgAtEntry - math.max(0, dmgLost)
        if currentDamage < 1 then
            return nil
        end

        currentOrigin = exitHit.Position + direction * 0.001
        wallsRemaining -= 1
    end

    return nil
end

-- zVJ[6092] : Évalue si un point cible inflige au moins le minimum de dégâts requis
local TargetVictimInfo = { Armor = 0, Helmet = false }
local function EvaluateTargetPointDamage(eyePos, targetPoint, hitboxName, allowAutowall, minDamage)
    if not allowAutowall and not IsLineOfSightClear(eyePos, targetPoint) then
        return nil
    end
    local delta = targetPoint - eyePos
    local dmg = SimulateBulletPenetration(eyePos, delta.Unit, delta.Magnitude, hitboxName, TargetVictimInfo)
    if dmg and dmg >= minDamage then
        return dmg, delta.Magnitude
    end
    return nil
end

-- zVJ[14743] : Teste si un rayon touche une hitbox ennemie valide (avec priorité d'occlusion et AutoWall)
local HitboxPriorityGroup = {
    Head = 1,
    UpperTorso = 2, LowerTorso = 2, Torso = 2,
    LeftUpperArm = 3, LeftLowerArm = 3, LeftHand = 3,
    RightUpperArm = 3, RightLowerArm = 3, RightHand = 3,
    LeftUpperLeg = 4, LeftLowerLeg = 4, LeftFoot = 4,
    RightUpperLeg = 4, RightLowerLeg = 4, RightFoot = 4,
}
local ActiveCombatSettings = {
    autowall = false,
    mindamage = 1,
    hitchance = 50,
    autostop = false,
    autoscope = false,
}

local function RayHitsTarget(targetList, rayOrigin, rayVector)
    local bestT, bestHitboxName, bestTarget
    for _, target in ipairs(targetList) do
        local minGroupT = { 1e9, 1e9, 1e9, 1e9, 1e9, 1e9 }
        local groupHitboxName = {}
        for _, partEntry in ipairs(target.Parts) do
            local part = partEntry.Part
            local hitT = IntersectRayOBB(part.CFrame + partEntry.Offset, part.Size / 2, rayOrigin, rayVector)
            local groupIdx = HitboxPriorityGroup[partEntry.Name] or 2
            if hitT and hitT < minGroupT[groupIdx] then
                minGroupT[groupIdx] = hitT
                groupHitboxName[groupIdx] = partEntry.Name
            end
        end
        if minGroupT[2] < minGroupT[1] or minGroupT[3] < minGroupT[1] then
            groupHitboxName[1] = nil
        end
        for groupIdx = 1, 6 do
            if groupHitboxName[groupIdx] then
                if not bestT or minGroupT[groupIdx] < bestT then
                    bestT = minGroupT[groupIdx]
                    bestHitboxName = groupHitboxName[groupIdx]
                    bestTarget = target
                end
                break
            end
        end
    end

    if not bestT then
        return false
    end

    local hitDistance = bestT * rayVector.Magnitude
    local wallHit = workspace:Raycast(rayOrigin, rayVector, WallRaycastParams)
    if not wallHit or wallHit.Distance >= hitDistance then
        return true
    end
    if not ActiveCombatSettings.autowall then
        return false
    end

    local dmg = SimulateBulletPenetration(rayOrigin, rayVector.Unit, hitDistance, bestHitboxName, bestTarget)
    return dmg ~= nil and dmg >= ActiveCombatSettings.mindamage
end

-- zVJ[1034] : Calcul de la probabilité de toucher (Hitchance)
local function CheckHitchance(targetList, eyePos, shotCFrame)
    local snap = Client.Snapshot
    local totalInaccuracy = (snap.inaccuracy or 0) + (snap.spread or 0)
    if totalInaccuracy <= 1e-4 then
        return true
    end

    local look, right, up = shotCFrame.LookVector, shotCFrame.RightVector, shotCFrame.UpVector
    local spreadSamples = snap.spreadSamples

    if spreadSamples and #spreadSamples >= 2 then
        local sampleCount = #spreadSamples // 2
        local neededHits = math.ceil(ActiveCombatSettings.hitchance / 100 * sampleCount - 1e-6)
        local hits = 0
        for i = 1, sampleCount do
            local dir = (look + right * spreadSamples[i * 2 - 1] + up * spreadSamples[i * 2]).Unit * 1000
            if RayHitsTarget(targetList, eyePos, dir) then
                hits += 1
                if hits >= neededHits then
                    return true
                end
            elseif hits + sampleCount - i < neededHits then
                return false
            end
        end
        return hits >= neededHits
    end

    local totalSamples, hits = 0, 0
    for ring = 0, 2 do
        local ringPoints = ring == 0 and 1 or 8
        local radius = totalInaccuracy * ring / 2
        for j = 1, ringPoints do
            local angle = (j - 1) / ringPoints * math.pi * 2
            local dir = (look + right * (math.cos(angle) * radius) + up * (math.sin(angle) * radius)).Unit * 1000
            totalSamples += 1
            if RayHitsTarget(targetList, eyePos, dir) then
                hits += 1
            end
        end
    end

    return (hits / totalSamples) >= (ActiveCombatSettings.hitchance / 100)
end

-- ============================================================================
-- [6] RAGEBOT, SILENT AIM, TRIGGERBOT, RECOIL & FOV (zVJ[5362], zVJ[8436], zVJ[4547]...)
-- ============================================================================

local lastBacktrackAmount = 0
local rageSilentPoint = nil
local currentRageTarget = nil
local lastRageScanClock = 0
local RecoilState = { yaw = 0, pitch = 0 }

local function UpdateBacktrackRecords() end

local function ScanBestRageTarget(eyePos)
    local bestCandidate = nil
    local bestDamage = -1
    local allowAutowall = Flags.rageautowall == true
    local minDmg = Flags.ragemindamage or 1
    local partsToScan = ResolveHitboxList(Flags.rageparts)

    ForEachValidEnemy(function(_, entity)
        local plr = Client.GetPlayer(entity)
        TargetVictimInfo.Armor = plr and (plr:GetAttribute("ArmorValue") or 0) or (entity.Armor or 0)
        TargetVictimInfo.Helmet = plr and (plr:GetAttribute("HasHelmet") == true) or (entity.Helmet == true)

        for _, partName in ipairs(partsToScan) do
            local part = entity.Model:FindFirstChild(partName)
            if part then
                local dmg = EvaluateTargetPointDamage(eyePos, part.Position, partName, allowAutowall, minDmg)
                if dmg and dmg > bestDamage then
                    bestDamage = dmg
                    bestCandidate = {
                        Id = entity.Id,
                        Part = part,
                        Local = Vector3.zero,
                        Shift = Vector3.zero,
                        Delta = 0,
                    }
                end
            end
        end
    end)
    return bestCandidate
end

-- zVJ[15391] : Envoie la commande de Backtrack au client
local function SetBacktrack(deltaTime)
    if deltaTime ~= lastBacktrackAmount then
        lastBacktrackAmount = deltaTime
        Client.SendCommand("backtrack", deltaTime)
    end
end

-- zVJ[5362] : Boucle principale du Ragebot
local function RagebotStep()
    rageSilentPoint = nil
    if Flags.ragebacktrack then
        UpdateBacktrackRecords()
    end
    if not (Flags.rage and IsKeybindActive("ragekb")) then
        currentRageTarget = nil
        SetBacktrack(0)
        return false
    end

    local sim = Client.GetSimulation()
    if not (sim and Client.HoldingGun()) then
        currentRageTarget = nil
        SetBacktrack(0)
        return false
    end

    RefreshGeometryFilter()
    local eyePos = Client.EyePosition(sim)
    local now = os.clock()

    if not currentRageTarget or not currentRageTarget.Part.Parent or (now - lastRageScanClock >= (1 / 30)) then
        lastRageScanClock = now
        currentRageTarget = ScanBestRageTarget(eyePos)
    end

    if not currentRageTarget then
        SetBacktrack(0)
        return false
    end

    SetBacktrack(currentRageTarget.Delta or 0)
    local curYaw, curPitch = Client.Snapshot.yaw, Client.Snapshot.pitch
    local worldAimPoint = currentRageTarget.Part.CFrame:PointToWorldSpace(currentRageTarget.Local)
        + (currentRageTarget.Shift or Vector3.new(0, 0, 0))

    if Flags.ragesilent then
        rageSilentPoint = worldAimPoint
        return false
    end

    local targetYaw, targetPitch = Client.SolveAngles(worldAimPoint, eyePos)
    Client.SendCommand("nudge", NormalizeYawDelta(targetYaw - curYaw), targetPitch - curPitch)

    if Flags.ragenospread then
        rageSilentPoint = worldAimPoint
    end

    local recYaw, recPitch = Client.RecoilComp()
    RecoilState.yaw = -recYaw
    RecoilState.pitch = recPitch
    return true
end

-- zVJ[14650] : Compensation fluide du recul (Recoil Control)
local function RecoilCompensationStep(dt)
    local recYaw, recPitch = Client.RecoilComp()
    local targetYaw = -recYaw
    local alpha = math.clamp(dt * 25, 0, 1)

    local nextYaw = RecoilState.yaw + (targetYaw - RecoilState.yaw) * alpha
    local nextPitch = RecoilState.pitch + (recPitch - RecoilState.pitch) * alpha

    if math.abs(targetYaw - nextYaw) < 1e-5 then
        nextYaw = targetYaw
    end
    if math.abs(recPitch - nextPitch) < 1e-5 then
        nextPitch = recPitch
    end

    local deltaYaw = nextYaw - RecoilState.yaw
    local deltaPitch = nextPitch - RecoilState.pitch
    RecoilState.yaw = nextYaw
    RecoilState.pitch = nextPitch

    if Client.GetSimulation() and (deltaYaw ~= 0 or deltaPitch ~= 0) then
        Client.SendCommand("nudge", deltaYaw, deltaPitch)
    end
end

-- zVJ[8436] : Boucle principale du Silent Aim
local wasSilentSent = false
local wasSilentSeedSent = false

local function SilentAimStep()
    local sim = Client.GetSimulation()
    local chosenPoint = rageSilentPoint
    local seedDataPayload = nil

    if (if chosenPoint then not chosenPoint else Flags.silentaim) and sim and Client.HoldingGun() then
        RefreshGeometryFilter()
        local eyePos = sim.NextEye or Client.EyePosition(sim)
        local snap = Client.Snapshot
        local shotLook = Client.ShotLook(sim, snap.yaw, snap.pitch)
        local halfFov = (Flags.silentfov or 30) / 2
        local priorityMode = Flags.silentpriority or "Closest To Crosshair"
        local allowedParts = ResolveHitboxList(Flags.silentparts)

        ActiveCombatSettings.autowall = Flags.silentautowall == true
        ActiveCombatSettings.mindamage = Flags.silentmindamage or 1
        ActiveCombatSettings.hitchance = Flags.silenthitchance or 50

        local candidates = {}
        ForEachValidEnemy(function(_, entity)
            for _, partName in ipairs(allowedParts) do
                local part = entity.Model:FindFirstChild(partName)
                if part then
                    local diff = part.Position - eyePos
                    local angle = math.deg(math.acos(math.clamp(shotLook:Dot(diff.Unit), -1, 1)))
                    if angle <= halfFov then
                        local score = if priorityMode == "Closest Distance" then diff.Magnitude
                            elseif priorityMode == "Lowest Health" then entity.Health
                            else angle
                        table.insert(candidates, { Point = part.Position, Score = score })
                    end
                end
            end
        end)

        if #candidates > 0 then
            table.sort(candidates, function(a, b)
                return a.Score < b.Score
            end)
            local targetModels = BuildTargetHitboxList(eyePos, shotLook)
            for _, candidate in ipairs(candidates) do
                local valid = RayHitsTarget(targetModels, eyePos, (candidate.Point - eyePos).Unit * 1000)
                    and (sim.Airborne or CheckHitchance(targetModels, eyePos, CFrame.lookAt(eyePos, candidate.Point)))
                if valid then
                    chosenPoint = candidate.Point
                    if Flags.silentseed and snap.seed and #snap.seed.Offsets > 0 then
                        local aimCFrame = CFrame.lookAt(eyePos, chosenPoint)
                        local seedResult = { Base = snap.seed.Count, Hits = {} }
                        for idx, offsetPair in ipairs(snap.seed.Offsets) do
                            local scales = { 1, 1.04, 0.96 }
                            local allHit = true
                            for _, s in ipairs(scales) do
                                local rayVec = (aimCFrame.LookVector + aimCFrame.RightVector * offsetPair[1] * s + aimCFrame.UpVector * offsetPair[2] * s).Unit * 1000
                                if not RayHitsTarget(targetModels, eyePos, rayVec) then
                                    allHit = false
                                    break
                                end
                            end
                            seedResult.Hits[idx] = allHit
                        end
                        seedDataPayload = seedResult
                    end
                    break
                end
            end
        end
    end

    if chosenPoint or wasSilentSent then
        Client.SendCommand("silent", chosenPoint, (rageSilentPoint and Flags.ragenospread) == true)
    end
    if seedDataPayload or wasSilentSeedSent then
        wasSilentSeedSent = seedDataPayload ~= nil
        Client.SendCommand("silentseed", wasSilentSeedSent, seedDataPayload)
    end
    wasSilentSent = chosenPoint ~= nil
    Client.SilentPoint = chosenPoint
end

-- zVJ[4547] : Triggerbot, Rage AutoFire, Seeded Trigger, AutoScope & AutoStop
local lastAutoScopeClock = 0
local isTriggerFiring = false
local wasSeedFireActive = false
local lastAutoStopState = false
local lastAutoStopSpeed = 0

local function TriggerbotAndAutoFireStep()
    local sim, snap = Client.GetSimulation(), Client.Snapshot
    local needsScope = Flags.triggerscoped and snap and snap.canScope and (snap.zoom or 0) <= 0
    local shouldAutoStop = false
    local rageAutoFire = Flags.rage and Flags.rageautofire and IsKeybindActive("ragekb")
    local safePeekActive = Flags.safepeek == true and IsKeybindActive("safepeekkb") == true
    local triggerActive = (Flags.triggerbot and IsKeybindActive("triggerkb")) or safePeekActive
    local useSeededFire = (rageAutoFire and Flags.rageseeded) or (not rageAutoFire and (Flags.triggerseeded or safePeekActive))
    local seedFirePayload, seedFireShouldShoot

    if rageAutoFire then
        ActiveCombatSettings.autowall = Flags.rageautowall == true
        ActiveCombatSettings.mindamage = Flags.ragemindamage or 1
        ActiveCombatSettings.hitchance = Flags.ragehitchance or 60
        ActiveCombatSettings.autostop = Flags.rageautostop == true
        ActiveCombatSettings.autoscope = Flags.rageautoscope == true
    else
        ActiveCombatSettings.autowall = Flags.triggerautowall == true
        ActiveCombatSettings.mindamage = Flags.triggermindamage or 1
        ActiveCombatSettings.hitchance = Flags.triggerhitchance or 80
        ActiveCombatSettings.autostop = Flags.triggerautostop == true
        ActiveCombatSettings.autoscope = Flags.triggerautoscope == true
    end

    if (triggerActive or rageAutoFire) and sim and Client.HoldingGun() and not needsScope then
        RefreshGeometryFilter()
        local eyePos = Client.EyePosition(sim)
        local shotCF = Client.ShotCFrame(sim, Client.Snapshot.yaw, Client.Snapshot.pitch)
        if rageAutoFire and rageSilentPoint then
            shotCF = CFrame.lookAt(eyePos, rageSilentPoint)
        end

        local targetList = BuildTargetHitboxList(eyePos, shotCF.LookVector)
        if rageAutoFire and currentRageTarget and currentRageTarget.Shift then
            for _, target in ipairs(targetList) do
                if target.Id == currentRageTarget.Id then
                    for _, partEntry in ipairs(target.Parts) do
                        partEntry.Offset = partEntry.Offset + currentRageTarget.Shift
                    end
                end
            end
        end

        if #targetList > 0 then
            local centerRayHits = RayHitsTarget(targetList, eyePos, shotCF.LookVector * 1000)
            local anySeedHits, computedSeedTable

            if useSeededFire and snap.seed and #snap.seed.Offsets > 0 then
                local nextEye = sim.NextEye or eyePos
                local rageNoSpreadActive = rageAutoFire and rageSilentPoint ~= nil and Flags.ragenospread == true
                local seedTable = { Base = snap.seed.Count, Hits = {} }

                for idx, offsetPair in ipairs(snap.seed.Offsets) do
                    local hitSuccess
                    if rageNoSpreadActive then
                        hitSuccess = true
                    else
                        hitSuccess = true
                        for _, scale in ipairs({ 1, 1.04, 0.96 }) do
                            local dir = (shotCF.LookVector + shotCF.RightVector * offsetPair[1] * scale + shotCF.UpVector * offsetPair[2] * scale).Unit * 1000
                            if not RayHitsTarget(targetList, nextEye, dir) then
                                hitSuccess = false
                                break
                            end
                        end
                    end
                    seedTable.Hits[idx] = hitSuccess
                    anySeedHits = anySeedHits or hitSuccess
                end
                computedSeedTable = seedTable
            end

            local performAutoScope = (centerRayHits or anySeedHits) and ActiveCombatSettings.autoscope and snap.canScope and (snap.zoom or 0) <= 0
            if performAutoScope and (os.clock() - lastAutoScopeClock > 0.6) then
                lastAutoScopeClock = os.clock()
                task.spawn(function()
                    Client.SendCommand("scope", true)
                    task.wait(0.03)
                    Client.SendCommand("scope", false)
                end)
            end

            local fireNormalShot = false
            if computedSeedTable then
                local hitchanceOk = (rageAutoFire and rageSilentPoint and Flags.ragenospread) or CheckHitchance(targetList, eyePos, shotCF)
                seedFireShouldShoot = (anySeedHits and hitchanceOk and not performAutoScope) or false
            else
                fireNormalShot = centerRayHits and ((rageAutoFire and rageSilentPoint and Flags.ragenospread) or CheckHitchance(targetList, eyePos, shotCF))
            end

            shouldAutoStop = centerRayHits or anySeedHits or (rageAutoFire and currentRageTarget ~= nil)

            if fireNormalShot and not performAutoScope and not isTriggerFiring then
                isTriggerFiring = true
                task.spawn(function()
                    pcall(function()
                        task.wait(rageAutoFire and 0 or (Flags.triggerdelay or 0) / 1000)
                        Client.SendCommand("fire", true)
                        Client.LastTriggerFire = os.clock()
                        task.wait(0.03)
                        Client.SendCommand("fire", false)
                    end)
                    isTriggerFiring = false
                end)
            end
            seedFirePayload = computedSeedTable
        end
    end

    if seedFireShouldShoot or wasSeedFireActive then
        wasSeedFireActive = seedFireShouldShoot or false
        Client.SendCommand("seedfire", seedFireShouldShoot or false, seedFirePayload)
    end

    local engageAutoStop = shouldAutoStop and ActiveCombatSettings.autostop
    if engageAutoStop and Flags.autostopready and snap and snap.fireWait and snap.fireWait > 0.3 then
        engageAutoStop = false
    end

    local stopSpeedRatio = (Flags.autostopspeed or 30) / 100
    if engageAutoStop ~= lastAutoStopState or (engageAutoStop and stopSpeedRatio ~= lastAutoStopSpeed) then
        lastAutoStopState, lastAutoStopSpeed = engageAutoStop, stopSpeedRatio
        Client.SendCommand("autostop", engageAutoStop, stopSpeedRatio)
    end
end

-- zVJ[8941] : Mise à jour du cercle de FOV de l'Aimbot
local AimbotFOVFrame, AimbotFOVStroke
local function UpdateAimbotFOVCircle()
    if not AimbotFOVFrame then return end
    local halfFov = (Flags.aimbotfov or 0) / 2
    if not (Flags.aimbotfovdraw and Flags.aimbot and halfFov > 0 and halfFov < 89 and CurrentCamera) then
        AimbotFOVFrame.Visible = false
        return
    end
    local viewport = CurrentCamera.ViewportSize
    local radiusPx = math.tan(math.rad(halfFov)) / math.tan(math.rad(CurrentCamera.FieldOfView) / 2) * (viewport.Y / 2)
    AimbotFOVFrame.Size = UDim2.fromOffset(radiusPx * 2, radiusPx * 2)
    AimbotFOVFrame.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)

    local color = Flags.aimbotfovcolor and Flags.aimbotfovcolor.Color
    if color then
        AimbotFOVStroke.Color = color
        AimbotFOVStroke.Transparency = Client.Trans("aimbotfovcolor")
        AimbotFOVFrame.BackgroundColor3 = color
    end
    AimbotFOVFrame.BackgroundTransparency = Flags.aimbotfovfilled and Client.Trans("aimbotfovcolor", 0.85) or 1
    AimbotFOVFrame.Visible = true
end

local function LegitAimbotStep(dt)
    return false
end

local function UpdateSilentFOVCircle() end

-- ============================================================================
-- [7] ESP 2D, BOUNDING BOX, CHAMS & OUT-OF-FOV ARROWS (zVJ[8693], zVJ[11896], zVJ[8], zVJ[1073]...)
-- ============================================================================

local ESPScreenGui = CreateInstance("ScreenGui", {
    Name = "MoonOverlay",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local ChamsContainer = CreateInstance("Folder", {
    Name = "MoonChams",
    Parent = ESPScreenGui,
})

local ESPState = {
    generation = 0,
    cameraPosition = Vector3.zero,
    geometry = nil,
}
local espSettingsDirty = false
local ESPVisRaycastParams = RaycastParams.new()
ESPVisRaycastParams.FilterType = Enum.RaycastFilterType.Include

-- zVJ[18] : Modifie une propriété de configuration ESP et marque le cache comme modifié
local function SetESPConfigProperty(key, value)
    if ESPState[key] ~= value then
        ESPState[key] = value
        espSettingsDirty = true
    end
end

-- zVJ[63] : Formate la casse du nom selon l'option choisie
local function FormatNameCase(nameStr)
    local mode = Flags.espnamecase
    if mode == "Lowercase" then
        return nameStr:lower()
    elseif mode == "Uppercase" then
        return nameStr:upper()
    end
    return nameStr
end
ESP.Case = FormatNameCase

-- zVJ[8693] : Synchronise toutes les options UI vers ESPState
local function SyncESPSettings()
    espSettingsDirty = false
    SetESPConfigProperty("boxes", Flags.espboxes and true or false)
    SetESPConfigProperty("filled", Flags.espboxesfilled and true or false)
    SetESPConfigProperty("outlines", Flags.espoutlines and true or false)
    SetESPConfigProperty("names", Flags.espnames and true or false)
    SetESPConfigProperty("nameCase", Flags.espnamecase or "Normal")
    SetESPConfigProperty("distance", Flags.espdistance and true or false)
    SetESPConfigProperty("hpbar", Flags.esphealthbars and true or false)
    SetESPConfigProperty("hptext", Flags.esphealthtext and true or false)
    SetESPConfigProperty("armor", TableContains(Flags.espflags, "Armor"))
    SetESPConfigProperty("weapon", TableContains(Flags.espflags, "Weapon"))
    SetESPConfigProperty("scoped", TableContains(Flags.espflags, "Scoped"))
    SetESPConfigProperty("visibleCheck", TableContains(Flags.espchecks, "Visible"))
    SetESPConfigProperty("teamCheck", TableContains(Flags.espchecks, "Team"))
    SetESPConfigProperty("staticMode", Flags.ESPBoxMode == "Static")
    SetESPConfigProperty("fogHold", Flags.espfoghold and true or false)
    SetESPConfigProperty("fogHoldTime", Flags.espfogtime or 1)
    SetESPConfigProperty("boxColor", Flags.boxColor and Flags.boxColor.Color)
    SetESPConfigProperty("boxFillColor", Flags.boxFillColor and Flags.boxFillColor.Color)
    SetESPConfigProperty("fillTransparency", Flags.boxFillColor and Flags.boxFillColor.Alpha)
    SetESPConfigProperty("boxTransparency", Client.Trans("boxColor"))
    SetESPConfigProperty("healthColor", Flags.healthColor and Flags.healthColor.Color)
    SetESPConfigProperty("healthTransparency", Client.Trans("healthColor"))
    SetESPConfigProperty("nameColor", Flags.nameColor and Flags.nameColor.Color)
    SetESPConfigProperty("nameTransparency", Client.Trans("nameColor"))
    SetESPConfigProperty("distanceColor", Flags.distanceColor and Flags.distanceColor.Color)
    SetESPConfigProperty("distanceTransparency", Client.Trans("distanceColor"))

    if espSettingsDirty then
        ESPState.generation = ESPState.generation + 1
    end
    ESPState.cameraPosition = CurrentCamera.CFrame.Position

    local mapFolder = workspace:FindFirstChild("Map")
    local geometry = mapFolder and mapFolder:FindFirstChild("Geometry")
    if ESPState.geometry ~= geometry then
        ESPState.geometry = geometry
        ESPVisRaycastParams.FilterDescendantsInstances = geometry and { geometry } or {}
    end
end

-- zVJ[1232] : Applique le fondu d'opacité (Fade) sur tous les éléments UI d'un joueur
local function ApplyESPFade(drawingEntry)
    local fade = drawingEntry.Fade or 1
    local fadeProps = drawingEntry.FadeProperties
    for _, propEntry in ipairs(fadeProps) do
        for propName, baseValue in pairs(propEntry.Values) do
            propEntry.Object[propName] = baseValue + (1 - baseValue) * fade
        end
    end
end

local function StepESPFadeAnimation(drawing, targetFade, dt, duration)
    local step = (dt or (1 / 60)) / (duration or 0.25)
    if drawing.Fade < targetFade then
        drawing.Fade = math.min(targetFade, drawing.Fade + step)
        ApplyESPFade(drawing)
    elseif drawing.Fade > targetFade then
        drawing.Fade = math.max(targetFade, drawing.Fade - step)
        ApplyESPFade(drawing)
    end
end

-- zVJ[1238] : Calcule la boîte englobante 2D dynamique en projetant les 8 coins de chaque membre
local CornerSigns = {
    Vector3.new(-1, -1, -1), Vector3.new(1, -1, -1),
    Vector3.new(-1,  1, -1), Vector3.new(1,  1, -1),
    Vector3.new(-1, -1,  1), Vector3.new(1, -1,  1),
    Vector3.new(-1,  1,  1), Vector3.new(1,  1,  1),
}

function ESP:GetBoundingBox(drawingEntry)
    local maxX, maxY = -math.huge, -math.huge
    local minX, minY = math.huge, math.huge
    local invCamCF = CurrentCamera.CFrame:Inverse()
    local viewport = CurrentCamera.ViewportSize
    local halfW, halfH = viewport.X / 2, viewport.Y / 2
    local projY = 1 / math.tan(math.rad(CurrentCamera.FieldOfView) / 2)
    local projX = projY / (viewport.X / viewport.Y)
    local parts = drawingEntry.Parts
    local allInFront = true

    for _, part in ipairs(parts) do
        if part.Parent then
            local relCF = invCamCF * part.CFrame
            local halfSize = part.Size / 2
            for i = 1, 8 do
                local localCorner = relCF * (CornerSigns[i] * halfSize)
                local depth = -localCorner.Z
                if depth <= 0 then
                    allInFront = false
                else
                    local screenX = halfW + (localCorner.X / depth) * projX * halfW
                    local screenY = halfH - (localCorner.Y / depth) * projY * halfH
                    minX = math.min(minX, screenX)
                    minY = math.min(minY, screenY)
                    maxX = math.max(maxX, screenX)
                    maxY = math.max(maxY, screenY)
                end
            end
        end
    end
    return minX, minY, maxX, maxY, allInFront
end

function ESP:GetStaticBoundingBox(worldPos, upVector)
    local topWorld = worldPos + upVector * 2.75
    local bottomWorld = worldPos - upVector * 3.0
    local topScreen, topVis = CurrentCamera:WorldToViewportPoint(topWorld)
    local botScreen, botVis = CurrentCamera:WorldToViewportPoint(bottomWorld)

    if not (topVis or botVis) or topScreen.Z <= 0 or botScreen.Z <= 0 then
        return 0, 0, 0, 0, false
    end

    local height = math.abs(botScreen.Y - topScreen.Y)
    local width = height * 0.6
    local centerX = (topScreen.X + botScreen.X) * 0.5
    local minY = math.min(topScreen.Y, botScreen.Y)
    return centerX - width * 0.5, minY, centerX + width * 0.5, minY + height, true
end

function ESP:Create(entityId, entity)
    local plr = Client.GetPlayer(entity)
    local rawName = (plr and plr.Name) or entity.Name or ("Bot " .. tostring(entityId))

    local holder = CreateInstance("Frame", {
        Name = "",
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ESPScreenGui,
    })

    local box = CreateInstance("Frame", {
        Name = "",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = holder,
    })

    local border = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Parent = box,
    })

    local outsideStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Parent = holder,
    })

    local insideFrame = CreateInstance("Frame", {
        Name = "",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        Parent = box,
    })

    local insideStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Parent = insideFrame,
    })

    local hpBar = CreateInstance("Frame", {
        Name = "",
        BackgroundColor3 = Color3.fromRGB(0, 255, 100),
        BorderSizePixel = 0,
        Parent = holder,
    })

    local hpText = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(30, 10),
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 9,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = holder,
    })

    local nameLabel = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.fromOffset(200, 14),
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.2,
        Text = rawName,
        Parent = holder,
    })

    local distanceLabel = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 2),
        Size = UDim2.fromOffset(120, 12),
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 10,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextStrokeTransparency = 0.2,
        Parent = holder,
    })

    local gunLabel = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 14),
        Size = UDim2.fromOffset(140, 12),
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.2,
        Parent = holder,
    })

    local armorLabel = CreateInstance("TextLabel", {
        Name = "",
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local scopedLabel = CreateInstance("TextLabel", {
        Name = "",
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 10,
        TextColor3 = Color3.fromRGB(120, 200, 255),
        TextStrokeTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local bodyParts = {}
    if entity.Model then
        for _, child in ipairs(entity.Model:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(bodyParts, child)
            end
        end
    end

    local fadeProperties = {
        { Object = border,        Values = { Transparency = 0 } },
        { Object = outsideStroke, Values = { Transparency = 0 } },
        { Object = insideStroke,  Values = { Transparency = 0 } },
        { Object = box,           Values = { BackgroundTransparency = 1 } },
        { Object = hpBar,         Values = { BackgroundTransparency = 0 } },
        { Object = hpText,        Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
        { Object = nameLabel,     Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
        { Object = distanceLabel, Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
        { Object = gunLabel,      Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
        { Object = armorLabel,    Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
        { Object = scopedLabel,   Values = { TextTransparency = 0, TextStrokeTransparency = 0.2 } },
    }

    local fadeOf = {}
    for _, fp in ipairs(fadeProperties) do
        fadeOf[fp.Object] = fp
    end

    local drawing = {
        holder = holder,
        Box = box,
        Border = border,
        OutsideStroke = outsideStroke,
        InsideStroke = insideStroke,
        HpBar = hpBar,
        HpText = hpText,
        NameLabel = nameLabel,
        Distance = distanceLabel,
        Gun = gunLabel,
        Armor = armorLabel,
        Scoped = scopedLabel,
        Player = plr,
        RawName = rawName,
        Parts = bodyParts,
        Health = entity.Health or 100,
        MaxHealth = entity.MaxHealth or 100,
        Fade = 1,
        Generation = -1,
        FadeProperties = fadeProperties,
        FadeOf = fadeOf,
        BoxFade = fadeOf[box],
    }

    self.Drawings[entityId] = drawing
    return drawing
end

function ESP:Remove(entityId)
    local drawing = self.Drawings[entityId]
    if drawing then
        drawing.holder:Destroy()
        self.Drawings[entityId] = nil
    end
end

function ESP:Disable()
    for id in pairs(self.Drawings) do
        self:Remove(id)
    end
end

-- zVJ[11896] : Met à jour l'affichage complet de l'ESP 2D pour une entité
function ESP:Update(entityId, entity, drawing, dt)
    local holder, rootPart = drawing.holder, entity.Root
    if not (entity.Model and entity.Model.Parent and rootPart and rootPart.Parent) then
        self:Remove(entityId)
        return
    end

    drawing.Health = entity.Health or 0
    local isHidden = Client.IsHidden(entity, rootPart)
    local worldPos, upVector

    if isHidden then
        drawing.HiddenSince = drawing.HiddenSince or os.clock()
        local holdDuration = ESPState.fogHold and ESPState.fogHoldTime or 0
        if not drawing.LastPosition or (os.clock() - drawing.HiddenSince > holdDuration) then
            holder.Visible = false
            drawing.Fade = 1
            return
        end
        worldPos, upVector = drawing.LastPosition, Vector3.new(0, 1, 0)
    else
        drawing.HiddenSince = nil
        worldPos, upVector = rootPart.Position, rootPart.CFrame.UpVector
        drawing.LastPosition = worldPos
    end

    local distance = (ESPState.cameraPosition - worldPos).Magnitude
    local minX, minY, maxX, maxY, onScreen
    if ESPState.staticMode or distance > 100 or isHidden then
        minX, minY, maxX, maxY, onScreen = self:GetStaticBoundingBox(worldPos, upVector)
    else
        minX, minY, maxX, maxY, onScreen = self:GetBoundingBox(drawing)
    end

    local viewportPoint, inViewport = CurrentCamera:WorldToViewportPoint(worldPos)
    local validBox = onScreen and minX < maxX and minY < maxY
    local isVisible = true
    if ESPState.visibleCheck and ESPState.geometry and not isHidden then
        isVisible = workspace:Raycast(ESPState.cameraPosition, worldPos - ESPState.cameraPosition, ESPVisRaycastParams) == nil
    end

    if validBox then
        if drawing.Generation ~= ESPState.generation then
            drawing.Generation = ESPState.generation
            drawing.Border.Color = ESPState.boxColor
            drawing.HpBar.BackgroundColor3 = ESPState.healthColor
            drawing.NameLabel.TextColor3 = ESPState.nameColor
            drawing.NameLabel.Text = ESP.Case(drawing.RawName)
            drawing.Distance.TextColor3 = ESPState.distanceColor
            drawing.Box.BackgroundColor3 = ESPState.boxFillColor

            local fadeOf = drawing.FadeOf
            fadeOf[drawing.Border].Values.Transparency = ESPState.boxTransparency
            fadeOf[drawing.HpBar].Values.BackgroundTransparency = ESPState.healthTransparency
            fadeOf[drawing.NameLabel].Values.TextTransparency = ESPState.nameTransparency
            fadeOf[drawing.Distance].Values.TextTransparency = ESPState.distanceTransparency
            if drawing.BoxFade then
                drawing.BoxFade.Values.BackgroundTransparency = (ESPState.boxes and ESPState.filled) and ESPState.fillTransparency or 1
            end

            drawing.Box.Visible = ESPState.boxes
            drawing.OutsideStroke.Enabled = ESPState.outlines
            drawing.InsideStroke.Enabled = ESPState.outlines
            drawing.NameLabel.Visible = ESPState.names
            drawing.Distance.Visible = ESPState.distance
            drawing.HpBar.Visible = ESPState.hpbar
            drawing.HpText.Visible = ESPState.hpbar and ESPState.hptext
            drawing.Armor.Visible = ESPState.armor
            drawing.Gun.Visible = ESPState.weapon
            drawing.Scoped.Visible = ESPState.scoped
            ApplyESPFade(drawing)
        end

        local boxWidth, boxHeight = maxX - minX, maxY - minY
        holder.Position = UDim2.fromOffset(minX, minY)
        holder.Size = UDim2.fromOffset(boxWidth, boxHeight)

        if ESPState.hpbar then
            local hpRatio = math.clamp(drawing.Health / drawing.MaxHealth, 0, 1)
            if drawing.HpTarget ~= hpRatio then
                drawing.HpFrom = drawing.HpDisplay or hpRatio
                drawing.HpTarget = hpRatio
                drawing.HpStart = os.clock()
            end
            local t = 1 - math.clamp((os.clock() - drawing.HpStart) / 0.3, 0, 1)
            local displayedRatio = hpRatio + (drawing.HpFrom - hpRatio) * t * t * t
            drawing.HpDisplay = displayedRatio
            local topOffset = boxHeight * (1 - displayedRatio)
            drawing.HpBar.Size = UDim2.fromOffset(1, boxHeight * displayedRatio)
            drawing.HpBar.Position = UDim2.fromOffset(-5, topOffset)
            if ESPState.hptext then
                drawing.HpText.Text = tostring(math.clamp(math.floor(drawing.Health + 0.5), 0, 999))
                drawing.HpText.Position = UDim2.fromOffset(-7, topOffset)
            end
        end

        if ESPState.distance then
            drawing.Distance.Text = string.format("%.0fm", distance)
        end

        if ESPState.armor or ESPState.weapon or ESPState.scoped then
            local flagTextSize = math.clamp(math.min(boxWidth, boxHeight) * 0.1, 7, 14)
            local lineHeight = flagTextSize + 1
            if ESPState.armor then
                drawing.Armor.Size = UDim2.fromOffset(80, lineHeight)
                drawing.Armor.Position = UDim2.fromOffset(boxWidth + 3, lineHeight + 1)
                drawing.Armor.TextSize = flagTextSize
                local plr = drawing.Player
                local armorVal = plr and (plr:GetAttribute("ArmorValue") or 0) or 0
                local hasHelmet = plr and plr:GetAttribute("HasHelmet")
                drawing.Armor.Text = (hasHelmet and armorVal > 0 and "H K") or (hasHelmet and "H") or (armorVal > 0 and "K") or ""
            end
            if ESPState.weapon then
                drawing.Gun.Text = entity.Weapon and tostring(entity.Weapon) or ""
            end
            if ESPState.scoped then
                drawing.Scoped.Size = UDim2.fromOffset(80, lineHeight)
                drawing.Scoped.Position = UDim2.fromOffset(boxWidth + 3, (lineHeight + 1) * 2)
                drawing.Scoped.TextSize = flagTextSize
                drawing.Scoped.Text = (entity.Zoom or 0) > 0 and "Scoped" or ""
            end
        end
    end

    local shouldShow = validBox and inViewport and viewportPoint.Z > 0 and isVisible
    if shouldShow then
        holder.Visible = true
    end
    local targetFade = shouldShow and (isHidden and 0.6 or 0) or 1
    StepESPFadeAnimation(drawing, targetFade, dt, 0.25)
    if not shouldShow and drawing.Fade >= 1 then
        holder.Visible = false
    end
end

local function GetChamsColorAndTrans(flagKey)
    local picker = Flags[flagKey]
    local col = (picker and picker.Color) or Color3.fromRGB(255, 255, 255)
    local trans = Client.Trans(flagKey)
    return col, trans
end

-- zVJ[20] : Applique ou restaure l'effet Neon sur les parties du corps (Glow Chams)
local function ApplyPartNeonGlow(chamsEntry, enableGlow, glowColor)
    local saved = chamsEntry.Saved
    for _, glowAdorn in ipairs(chamsEntry.Glows) do
        local part = glowAdorn.Adornee
        if part then
            if enableGlow then
                if not saved[part] then
                    saved[part] = { part.Material, part.Color }
                end
                if part.Material ~= Enum.Material.Neon then
                    part.Material = Enum.Material.Neon
                end
                if part.Color ~= glowColor then
                    part.Color = glowColor
                end
            elseif saved[part] then
                part.Material, part.Color = saved[part][1], saved[part][2]
                saved[part] = nil
            end
        end
    end
end

-- zVJ[99] : Met à jour les propriétés d'un objet Chams (Highlight, BoxHandleAdornment, Glow)
local function UpdateEntityChams(chamsEntry)
    local visibleOnly = TableContains(Flags.chamschecks, "Visible Only")
    local alwaysOnTop = not visibleOnly
    local fillColor, fillTrans = GetChamsColorAndTrans("chamsColor")
    local outlineColor = GetChamsColorAndTrans("chamsColorOutline")

    local highlight = chamsEntry.Highlight
    highlight.Enabled = Flags.chamsmode == "Highlight"
    highlight.FillColor = fillColor
    highlight.FillTransparency = fillTrans
    highlight.OutlineColor = outlineColor
    highlight.DepthMode = (if visibleOnly then alwaysOnTop else Enum.HighlightDepthMode.AlwaysOnTop) or Enum.HighlightDepthMode.Occluded

    local isAdornments = Flags.chamsmode == "Adornments"
    local isGlow = Flags.chamsmode == "Glow"
    local hdrColor = Color3.new(fillColor.R * 1275, fillColor.G * 1275, fillColor.B * 1275)
    ApplyPartNeonGlow(chamsEntry, isGlow, fillColor)

    local glowExpand = Flags.chamsglowsize or 0.4
    for _, box in ipairs(chamsEntry.Boxes) do
        box.Visible = isAdornments
        box.Color3 = fillColor
        box.Transparency = fillTrans
        box.AlwaysOnTop = alwaysOnTop
    end
    for _, glow in ipairs(chamsEntry.Glows) do
        glow.Visible = isGlow
        glow.Color3 = hdrColor
        glow.Transparency = fillTrans
        glow.AlwaysOnTop = alwaysOnTop
        glow.Size = glow.Adornee.Size + Vector3.new(glowExpand, glowExpand, glowExpand)
    end
end

-- zVJ[13] : Crée les instances Chams pour un joueur
local function CreateEntityChams(entity)
    local model = entity.Model
    local entry = {
        Model = model,
        Boxes = {},
        Glows = {},
        Saved = {},
        Highlight = CreateInstance("Highlight", { Name = "", Adornee = model, Parent = ChamsContainer }),
    }
    for _, partName in ipairs(ChamsBodyPartNames) do
        local part = model:FindFirstChild(partName)
        if part then
            table.insert(entry.Boxes, CreateInstance("BoxHandleAdornment", {
                Name = "",
                Adornee = part,
                Size = part.Size,
                ZIndex = 2,
                Parent = ChamsContainer,
            }))
            local glowProps = {
                Name = "",
                Adornee = part,
                Size = part.Size,
                ZIndex = 1,
                Shading = Enum.AdornShading.XRayShaded,
                Parent = ChamsContainer,
            }
            table.insert(entry.Glows, CreateInstance("BoxHandleAdornment", glowProps))
        end
    end
    UpdateEntityChams(entry)
    return entry
end

-- zVJ[102] : Supprime les Chams d'un joueur et restaure ses matériaux
local ActiveChamsEntries = {}
local function RemoveEntityChams(entityId)
    local entry = ActiveChamsEntries[entityId]
    if entry then
        ApplyPartNeonGlow(entry, false)
        entry.Highlight:Destroy()
        for _, box in ipairs(entry.Boxes) do
            box:Destroy()
        end
        for _, glow in ipairs(entry.Glows) do
            glow:Destroy()
        end
        ActiveChamsEntries[entityId] = nil
    end
end

-- zVJ[8] : Boucle de mise à jour des Chams ennemis
local chamsSettingsDirty = false
local function SetChamsProp(k, v)
    if ESPState[k] ~= v then
        ESPState[k] = v
        chamsSettingsDirty = true
    end
end

local function ChamsStep(snapshot)
    if not (Flags.chams and snapshot) then
        if next(ActiveChamsEntries) then
            for id in pairs(ActiveChamsEntries) do
                RemoveEntityChams(id)
            end
        end
        return
    end

    chamsSettingsDirty = false
    SetChamsProp("through", TableContains(Flags.chamschecks, "Visible Only"))
    SetChamsProp("highlight", Flags.chamsmode == "Highlight")
    SetChamsProp("adorn", Flags.chamsmode == "Adornments")
    SetChamsProp("glow", Flags.chamsmode == "Glow")
    SetChamsProp("glowsize", Flags.chamsglowsize)

    for _, colorKey in ipairs({ "chamsColor", "chamsColorOutline" }) do
        local col, trans = GetChamsColorAndTrans(colorKey)
        SetChamsProp(colorKey, col)
        SetChamsProp(colorKey .. "t", trans)
    end

    local teamCheck = TableContains(Flags.chamschecks, "Team")
    local isGlowMode = Flags.chamsmode == "Glow"
    local glowColor = GetChamsColorAndTrans("chamsColor")
    local seenIds = {}

    for _, entity in ipairs(snapshot.entities) do
        local id = entity.Id
        if entity.Model and entity.Model.Parent and not entity.Hidden and not Client.IsLocal(entity) then
            local hp = entity.Health
            if hp and hp > 0 and not (teamCheck and not Client.IsEnemy(entity)) then
                seenIds[id] = true
                local entry = ActiveChamsEntries[id]
                if entry and entry.Model ~= entity.Model then
                    RemoveEntityChams(id)
                    entry = nil
                end
                if entry then
                    if chamsSettingsDirty then
                        UpdateEntityChams(entry)
                    end
                else
                    ActiveChamsEntries[id] = CreateEntityChams(entity)
                end
                if isGlowMode and ActiveChamsEntries[id] then
                    ApplyPartNeonGlow(ActiveChamsEntries[id], true, glowColor)
                end
            end
        end
    end

    for id in pairs(ActiveChamsEntries) do
        if not seenIds[id] then
            RemoveEntityChams(id)
        end
    end
end
ESP.ChamsStep = ChamsStep

-- zVJ[16282] & zVJ[1073] : Flèches directionnelles hors-champ (Out-Of-FOV Arrows)
local ActiveArrows = {}
local function DestroyArrow(arrowEntry)
    arrowEntry.Holder:Destroy()
    arrowEntry.Pointer:Destroy()
end

local function CreateArrowUI(entity)
    local plr = Client.GetPlayer(entity)
    local name = (plr and plr.Name) or entity.Name or ("Bot " .. tostring(entity.Id))

    local holder = CreateInstance("Frame", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BackgroundTransparency = 0.25,
        Visible = false,
        Parent = ESPScreenGui,
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = holder })

    local stroke = CreateInstance("UIStroke", {
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 80, 80),
        Parent = holder,
    })

    local icon = CreateInstance("ImageLabel", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = plr and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=48&h=48") or "",
        Parent = holder,
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = icon })

    local pointer = CreateInstance("Frame", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BorderSizePixel = 0,
        Visible = false,
        Parent = ESPScreenGui,
    })

    local label = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(140, 14),
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.2,
        Parent = holder,
    })

    return {
        Name = name,
        Holder = holder,
        Stroke = stroke,
        Icon = icon,
        Pointer = pointer,
        Label = label,
    }
end

local function ArrowStep(snapshot)
    if not (Flags.arrows and snapshot) then
        if next(ActiveArrows) then
            for id, arrow in pairs(ActiveArrows) do
                DestroyArrow(arrow)
                ActiveArrows[id] = nil
            end
        end
        return
    end

    local camCF, viewport = CurrentCamera.CFrame, CurrentCamera.ViewportSize
    local centerX, centerY = viewport.X / 2, viewport.Y / 2
    local radius = Flags.arrowradius or 200
    local size = Flags.arrowsize or 28
    local color = (Flags.arrowColor and Flags.arrowColor.Color) or Color3.fromRGB(255, 80, 80)
    local showIcons = Flags.arrowicons ~= false
    local showNames = Flags.arrownames ~= false
    local teamCheck = TableContains(Flags.espchecks, "Team")
    local seenIds = {}

    for _, entity in ipairs(snapshot.entities) do
        local id, root = entity.Id, entity.Root
        if entity.Model and root and root.Parent and not entity.Hidden and not Client.IsLocal(entity) then
            local hp = entity.Health
            if hp and hp > 0 and not (teamCheck and not Client.IsEnemy(entity)) then
                seenIds[id] = true
                local worldPos = root.Position
                local _, onScreen = CurrentCamera:WorldToViewportPoint(worldPos)
                local arrow = ActiveArrows[id]

                if onScreen then
                    if arrow then
                        arrow.Holder.Visible = false
                        arrow.Pointer.Visible = false
                    end
                else
                    if not arrow then
                        arrow = CreateArrowUI(entity)
                        ActiveArrows[id] = arrow
                    end
                    local localPos = camCF:PointToObjectSpace(worldPos)
                    local angle = math.atan2(localPos.X, -localPos.Z)
                    local dirX, dirY = math.sin(angle), -math.cos(angle)

                    arrow.Holder.Size = UDim2.fromOffset(size + 12, size + 12)
                    arrow.Holder.Position = UDim2.fromOffset(centerX + dirX * radius, centerY + dirY * radius)
                    arrow.Icon.Size = UDim2.fromOffset(size, size)
                    arrow.Icon.Visible = showIcons
                    arrow.Stroke.Color = color
                    arrow.Stroke.Transparency = Client.Trans("arrowColor")
                    arrow.Pointer.BackgroundColor3 = color
                    arrow.Pointer.BackgroundTransparency = Client.Trans("arrowColor")
                    arrow.Pointer.Rotation = math.deg(angle) + 45
                    arrow.Pointer.Position = UDim2.fromOffset(centerX + dirX * (radius + size / 2 + 9), centerY + dirY * (radius + size / 2 + 9))
                    arrow.Label.Visible = showNames
                    arrow.Label.Position = UDim2.new(0.5, 0, 0.5, size / 2 + 2)
                    arrow.Label.Text = ESP.Case(arrow.Name) .. " [" .. math.floor(localPos.Magnitude) .. "m]"
                    arrow.Holder.Visible = true
                    arrow.Pointer.Visible = true
                end
            end
        end
    end

    for id, arrow in pairs(ActiveArrows) do
        if not seenIds[id] then
            DestroyArrow(arrow)
            ActiveArrows[id] = nil
        end
    end
end
ESP.ArrowStep = ArrowStep

-- ============================================================================
-- [8] SELF-CHAMS & MODIFICATION DU VIEWMODEL (zVJ[11714], zVJ[3129], zVJ[580], zVJ[8915], zVJ[1046])
-- ============================================================================

local SavedPartAppearances = {}
local ModelHighlights = {}
local lastSelfChamsClock = 0

-- zVJ[11714] : Sauvegarde l'apparence d'origine d'une BasePart
local function SavePartAppearance(part, groupName)
    local entry = SavedPartAppearances[part]
    if not entry then
        entry = {
            Group = groupName,
            Material = part.Material,
            Color = part.Color,
            Transparency = part.Transparency,
            Reflectance = part.Reflectance,
            TextureID = part:IsA("MeshPart") and part.TextureID or nil,
            Appearance = part:FindFirstChildOfClass("SurfaceAppearance"),
        }
        SavedPartAppearances[part] = entry
    end
    return entry
end

-- zVJ[3129] : Restaure l'apparence d'origine d'une BasePart
local function RestorePartAppearance(part, saved)
    if part.Parent then
        part.Material = saved.Material
        part.Color = saved.Color
        part.Transparency = saved.Transparency
        part.Reflectance = saved.Reflectance
        if saved.TextureID then
            part.TextureID = saved.TextureID
        end
        if saved.Appearance and saved.Appearance.Parent ~= part then
            saved.Appearance.Parent = part
        end
    end
end

-- zVJ[580] : Désactive et restaure tous les Chams d'un groupe ("viewmodel" ou "character")
local function ClearChamsGroup(groupName)
    for part, saved in pairs(SavedPartAppearances) do
        if saved.Group == groupName then
            RestorePartAppearance(part, saved)
            SavedPartAppearances[part] = nil
        end
    end
    for _, highlight in pairs(ModelHighlights) do
        if highlight.Name == groupName then
            highlight.Enabled = false
        end
    end
end

-- zVJ[8915] : Applique un style Highlight ou Material sur un modèle (Bras, Arme, Ghost)
local function ApplyModelChams(model, groupName, flagPrefix)
    local mode = Flags[flagPrefix .. "mode"]
    local color = (Flags[flagPrefix .. "color"] and Flags[flagPrefix .. "color"].Color) or Color3.fromRGB(126, 192, 255)
    local trans = Flags[flagPrefix .. "trans"] or 0
    local mat = Enum.Material[Flags[flagPrefix .. "material"] or "ForceField"] or Enum.Material.ForceField
    local reflectance = Flags[flagPrefix .. "reflect"] or 0
    local highlight = ModelHighlights[model]

    if mode == "Highlight" then
        if not (highlight and highlight.Parent) then
            highlight = CreateInstance("Highlight", { Name = groupName, Adornee = model, Parent = ChamsContainer })
            ModelHighlights[model] = highlight
        end
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = trans
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = true
    elseif highlight then
        highlight.Enabled = false
    end

    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            local saved = SavePartAppearance(desc, groupName)
            if mode == "Material" and saved.Transparency < 0.99 then
                if saved.Appearance and saved.Appearance.Parent == desc then
                    saved.Appearance.Parent = nil
                end
                if saved.TextureID and desc.TextureID ~= "" then
                    desc.TextureID = ""
                end
                desc.Material = mat
                desc.Color = color
                desc.Reflectance = reflectance
                desc.Transparency = math.max(saved.Transparency, trans)
            else
                RestorePartAppearance(desc, saved)
            end
        end
    end
end

-- zVJ[1046] : Boucle de mise à jour des Self-Chams (Viewmodel & MoonGhost)
local function SelfChamsStep()
    local now = os.clock()
    if now - lastSelfChamsClock < 0.1 then
        return
    end
    lastSelfChamsClock = now

    local cam = workspace.CurrentCamera
    if not cam then
        return
    end

    for part in pairs(SavedPartAppearances) do
        if not part.Parent then
            SavedPartAppearances[part] = nil
        end
    end
    for model, hl in pairs(ModelHighlights) do
        if not model.Parent then
            hl:Destroy()
            ModelHighlights[model] = nil
        end
    end

    if Flags.selfvon then
        local selectedParts = Flags.selfvparts
        for _, child in ipairs(cam:GetChildren()) do
            local arms, weapon = child:FindFirstChild("Arms"), child:FindFirstChild("Weapon")
            if arms and weapon then
                if TableContains(selectedParts, "Arms") then
                    ApplyModelChams(arms, "viewmodel", "selfv")
                end
                if TableContains(selectedParts, "Weapon") then
                    ApplyModelChams(weapon, "viewmodel", "selfv")
                end
            end
        end
    else
        ClearChamsGroup("viewmodel")
    end

    local moonGhost = cam:FindFirstChild("MoonGhost")
    if Flags.selfcon and moonGhost then
        ApplyModelChams(moonGhost, "character", "selfc")
    else
        ClearChamsGroup("character")
    end
end

-- ============================================================================
-- [9] RÉTICULE (CROSSHAIR), NO-SCOPE, HITMARKER, LOGS & TRAILS (zVJ[71], zVJ[1606], zVJ[12328], zVJ[15478]...)
-- ============================================================================

-- zVJ[71] : Réticule dynamique réagissant à l'imprécision de l'arme
local isCrosshairVisible = false
local CrosshairLines = {}
for i = 1, 4 do
    CrosshairLines[i] = CreateInstance("Frame", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Visible = false,
        Parent = ESPScreenGui,
    })
end
local CrosshairDot = CreateInstance("Frame", {
    Name = "",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BorderSizePixel = 0,
    Visible = false,
    Parent = ESPScreenGui,
})
local CrosshairCircle = CreateInstance("Frame", {
    Name = "",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = ESPScreenGui,
})
CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = CrosshairCircle })
local CrosshairCircleStroke = CreateInstance("UIStroke", { Thickness = 1, Parent = CrosshairCircle })
local smoothedSpreadRadius = 0

local function CrosshairStep(snapshot, dt)
    if not (Flags.crosshair and snapshot and snapshot.isGun) then
        if isCrosshairVisible then
            isCrosshairVisible = false
            for _, line in ipairs(CrosshairLines) do
                line.Visible = false
            end
            CrosshairDot.Visible = false
            CrosshairCircle.Visible = false
        end
        return
    end

    isCrosshairVisible = true
    local color = (Flags.crosshairColor and Flags.crosshairColor.Color) or Color3.fromRGB(255, 255, 255)
    local length = Flags.crosshairlength or 6
    local thickness = Flags.crosshairthickness or 1
    local viewport = CurrentCamera.ViewportSize
    local spread = (snapshot.inaccuracy or 0) + (snapshot.spread or 0)

    local targetRadius = spread * (viewport.Y / 2) / math.tan(math.rad(CurrentCamera.FieldOfView) / 2)
    smoothedSpreadRadius = math.min(smoothedSpreadRadius + (targetRadius - smoothedSpreadRadius) * math.min(1, (dt or (1 / 60)) * 25), 600)

    local offset = smoothedSpreadRadius + (Flags.crosshairgap or 2) + length / 2
    local centerX, centerY = viewport.X / 2, viewport.Y / 2

    CrosshairLines[1].Position, CrosshairLines[1].Size = UDim2.fromOffset(centerX, centerY - offset), UDim2.fromOffset(thickness, length)
    CrosshairLines[2].Position, CrosshairLines[2].Size = UDim2.fromOffset(centerX, centerY + offset), UDim2.fromOffset(thickness, length)
    CrosshairLines[3].Position, CrosshairLines[3].Size = UDim2.fromOffset(centerX - offset, centerY), UDim2.fromOffset(length, thickness)
    CrosshairLines[4].Position, CrosshairLines[4].Size = UDim2.fromOffset(centerX + offset, centerY), UDim2.fromOffset(length, thickness)

    local trans = Client.Trans("crosshairColor")
    for _, line in ipairs(CrosshairLines) do
        line.BackgroundColor3 = color
        line.BackgroundTransparency = trans
        line.Visible = true
    end

    CrosshairDot.BackgroundColor3 = color
    CrosshairDot.BackgroundTransparency = trans
    CrosshairCircleStroke.Transparency = trans
    CrosshairDot.Position = UDim2.fromOffset(centerX, centerY)
    CrosshairDot.Size = UDim2.fromOffset(thickness + 1, thickness + 1)
    CrosshairDot.Visible = Flags.crosshairdot == true

    CrosshairCircleStroke.Color = color
    CrosshairCircle.Position = UDim2.fromOffset(centerX, centerY)
    CrosshairCircle.Size = UDim2.fromOffset(smoothedSpreadRadius * 2, smoothedSpreadRadius * 2)
    CrosshairCircle.Visible = Flags.crosshaircircle == true
end
ESP.CrosshairStep = CrosshairStep

-- zVJ[1606] : Suppression des bordures noires lors de la visée au sniper (No Scope Overlay)
local lastNoScopeState = nil
local cachedScopeFrame = nil
local lastScopeSearchClock = 0

local function NoScopeBlackStep()
    local enabled = Flags.noscopeblack == true
    if enabled == lastNoScopeState and cachedScopeFrame and cachedScopeFrame.Parent then
        return
    end
    if not (cachedScopeFrame and cachedScopeFrame.Parent) then
        local now = os.clock()
        if now - lastScopeSearchClock < 1 then
            return
        end
        lastScopeSearchClock, cachedScopeFrame, lastNoScopeState = now, nil, nil
        for _, desc in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if desc.Name == "Scope" and desc:IsA("Frame") and desc:FindFirstChild("Center") then
                cachedScopeFrame = desc
                break
            end
        end
        if not cachedScopeFrame then
            return
        end
    end

    local center = cachedScopeFrame:FindFirstChild("Center")
    if not center then
        return
    end
    center.ImageTransparency = enabled and 1 or 0
    for _, sideName in ipairs({ "Left", "Right", "Top", "Bottom" }) do
        local bar = center:FindFirstChild(sideName)
        if bar then
            bar.BackgroundTransparency = enabled and 1 or 0
        end
    end
    lastNoScopeState = enabled
end

-- zVJ[13699], zVJ[14770], zVJ[15533], zVJ[12328] : Sons de tir & Hitmarker animé
local lastHitTimestamp = 0
local lastHitWasLethal = false
local isHitmarkerShowing = false
local HitmarkerTicks = {}
local HitmarkerStrokes = {}
local HitmarkerDirections = {
    Vector2.new(-1, -1),
    Vector2.new(1, -1),
    Vector2.new(-1,  1),
    Vector2.new(1,  1),
}
local HitmarkerRotations = { -45, 45, 45, -45 }
for i = 1, 4 do
    local tick = CreateInstance("Frame", {
        Name = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = HitmarkerRotations[i],
        BorderSizePixel = 0,
        Visible = false,
        Parent = ESPScreenGui,
    })
    HitmarkerTicks[i] = tick
    HitmarkerStrokes[i] = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Parent = tick,
    })
end

local function HideHitmarker()
    if isHitmarkerShowing then
        isHitmarkerShowing = false
        for _, tick in ipairs(HitmarkerTicks) do
            tick.Visible = false
        end
    end
end

local function TriggerHitmarker(isLethal)
    lastHitTimestamp = os.clock()
    lastHitWasLethal = isLethal
end

local function PlayHitSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = Flags.hitvolume or 3
    sound.Parent = Services.SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    Services.Debris:AddItem(sound, 30)
    task.spawn(function()
        if not sound.IsLoaded then
            sound.Loaded:Wait()
        end
        sound:Play()
    end)
end

local function OwnHit(isLethal)
    if isLethal then
        if Flags.killsound then
            PlayHitSound(Flags.killsoundfile)
        elseif Flags.hitsound then
            PlayHitSound(Flags.hitsoundfile)
        end
        TriggerHitmarker(true)
    else
        if Flags.hitsound then
            PlayHitSound(Flags.hitsoundfile)
        end
        TriggerHitmarker(false)
    end
end
Client.OwnHit = OwnHit

local function HitStep(snapshot)
    if not snapshot or (not Flags.hitmarker and not Flags.hitsound and not Flags.killsound) then
        HideHitmarker()
        return
    end

    local now = os.clock()
    local progress = (now - lastHitTimestamp) / 0.35
    if Flags.hitmarker and progress < 1 then
        isHitmarkerShowing = true
        local color = lastHitWasLethal and Color3.fromRGB(255, 60, 60)
            or (Flags.hitmarkerColor and Flags.hitmarkerColor.Color or Color3.fromRGB(255, 255, 255))
        local viewport = CurrentCamera.ViewportSize
        local scale = lastHitWasLethal and 1.4 or 1
        local length = (Flags.hitmarkersize or 7) * scale
        local thickness = Flags.hitmarkerthickness or 2
        local distFromCenter = (Flags.hitmarkergap or 6) * scale + length / 2 + progress * 3
        local outlineEnabled = Flags.hitmarkeroutline ~= false

        for idx, tickFrame in ipairs(HitmarkerTicks) do
            local dir = HitmarkerDirections[idx]
            tickFrame.Size = UDim2.fromOffset(thickness, length)
            tickFrame.Position = UDim2.fromOffset(
                viewport.X / 2 + dir.X * distFromCenter * 0.7071,
                viewport.Y / 2 + dir.Y * distFromCenter * 0.7071
            )
            tickFrame.BackgroundColor3 = color
            local alpha = Client.Trans("hitmarkerColor", progress)
            tickFrame.BackgroundTransparency = alpha
            HitmarkerStrokes[idx].Enabled = outlineEnabled
            HitmarkerStrokes[idx].Transparency = alpha
            tickFrame.Visible = true
        end
    else
        HideHitmarker()
    end
end
ESP.HitStep = HitStep
ESP.MoveSoundStep = function() end
ESP.ItemStep = function() end

-- zVJ[126] : Traitement des événements de tir (Hitlogs & Killlogs)
local pendingServerHitLog = nil
local function OnShotEvent(packet)
    local shot = packet.shot
    if shot.Rejected or not shot.Damage or shot.Damage <= 0 then
        return
    end
    if Client.OwnHit then
        Client.OwnHit(shot.Lethal == true)
    end
    if not Flags.hitlogs and not Flags.killlogs then
        return
    end

    local victimName = "player " .. tostring(shot.Target)
    for _, entity in ipairs(packet.entities) do
        if entity.Id == shot.Target then
            local plr = Client.GetPlayer(entity)
            victimName = (plr and plr.Name) or ("Bot " .. tostring(entity.Id))
            break
        end
    end

    if shot.Lethal then
        if Flags.killlogs then
            UI:Notification({ Name = "killed " .. victimName, Time = 3 })
        end
    elseif Flags.hitlogs then
        local logMessage = string.format("hit %s for %d (%d hp left)", victimName, shot.Damage, math.floor(shot.After or 0))
        if Flags.serverlogs then
            local token = { Text = logMessage }
            pendingServerHitLog = token
            task.delay(0.8, function()
                if pendingServerHitLog == token then
                    pendingServerHitLog = nil
                    UI:Notification({ Name = logMessage, Time = 3 })
                end
            end)
        else
            UI:Notification({ Name = logMessage, Time = 3 })
        end
    end
end

-- zVJ[10255], zVJ[11033], zVJ[5028], zVJ[1203], zVJ[15478] : Bullet Trails & Penetration Visualizer
local ImpactBoxPool = {}
local TrailPartPool = {}
local TrailBeamPool = {}
local RecordedPenetrationPoints = {}
local RecordedPenetrationNormals = {}
local LastPenetrationEval = { Blocked = false, Walls = 0, Damage = 0 }
local ActivePenVisuals = {}
local ActiveBulletTrails = {}

local function GetOrCreateImpactBox(index)
    local entry = ImpactBoxPool[index]
    if not entry then
        local part = CreateInstance("Part", {
            Name = "",
            Size = Vector3.new(1, 0.001, 1),
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Transparency = 1,
            Parent = ChamsContainer,
        })
        entry = {
            Part = part,
            Box = CreateInstance("SelectionBox", { LineThickness = 0, Adornee = part, Parent = part }),
        }
        ImpactBoxPool[index] = entry
    end
    return entry
end

local function GetOrCreateTrailPart(index)
    local part = TrailPartPool[index]
    if not part then
        part = CreateInstance("Part", {
            Name = "",
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CastShadow = false,
            Material = Enum.Material.Neon,
            Parent = ChamsContainer,
        })
        TrailPartPool[index] = part
    end
    return part
end

local function GetOrCreateBeamAttachment(index, parentPart)
    local entry = TrailBeamPool[index]
    if not entry then
        local fromAtt = CreateInstance("Attachment", { Parent = parentPart })
        local toAtt = CreateInstance("Attachment", { Parent = parentPart })
        local beam = CreateInstance("Beam", {
            Attachment0 = fromAtt,
            Attachment1 = toAtt,
            FaceCamera = true,
            LightEmission = 1,
            Enabled = false,
            Parent = parentPart,
        })
        entry = { From = fromAtt, To = toAtt, Beam = beam }
        TrailBeamPool[index] = entry
    end
    return entry
end

local function BuildBulletTrailSegments(origin, direction)
    local rightOffset = direction:Cross(Vector3.new(0, 1, 0))
    rightOffset = rightOffset.Magnitude > 0.01 and rightOffset.Unit * 0.2 or Vector3.new(0, 0, 0)
    local currentStart = origin + rightOffset - Vector3.new(0, 0.15, 0)
    local segments = {}
    local numPoints = #RecordedPenetrationPoints

    for i = 1, numPoints, 2 do
        local enterPt, exitPt = RecordedPenetrationPoints[i], RecordedPenetrationPoints[i + 1]
        table.insert(segments, { currentStart, enterPt, false })
        if not exitPt then
            currentStart = nil
            break
        end
        table.insert(segments, { enterPt, exitPt, true })
        currentStart = exitPt
    end

    if currentStart and not LastPenetrationEval.Blocked then
        local maxRange = (Client.WeaponData and Client.WeaponData.Range) or 300
        local endPt = currentStart + direction * math.min(maxRange, 300)
        table.insert(segments, { currentStart, endPt, false })
    end
    return segments
end

local function RenderBulletTrailSegments(segments, partIndex, baseColor, transparency, thickness, renderMode, materialName, age)
    local wallSegmentColor = baseColor:Lerp(Color3.fromRGB(255, 0, 0), 0.6)
    local isBeamMode = renderMode == "Beam"
    local materialEnum = Enum.Material[materialName or "Neon"] or Enum.Material.Neon

    for _, seg in ipairs(segments) do
        local startPos, endPos, isInsideWall = seg[1], seg[2], seg[3]
        local segLength = (endPos - startPos).Magnitude
        if segLength > 0.01 then
            partIndex += 1
            local part = GetOrCreateTrailPart(partIndex)
            local segColor = isInsideWall and wallSegmentColor or baseColor
            part.Size = Vector3.new(thickness, thickness, segLength)
            part.CFrame = CFrame.lookAt((startPos + endPos) / 2, endPos)
            part.Color = segColor

            local beamEntry = GetOrCreateBeamAttachment(partIndex, part)
            if isBeamMode then
                part.Transparency = 1
                beamEntry.From.Position = Vector3.new(0, 0, segLength / 2)
                beamEntry.To.Position = Vector3.new(0, 0, -segLength / 2)
                local width = thickness * 12 * (age and (1 + 14 * (1 - math.min(age / 0.3, 1)) ^ 2) or 1)
                beamEntry.Beam.Width0, beamEntry.Beam.Width1 = width, width
                beamEntry.Beam.Color = ColorSequence.new(segColor)
                beamEntry.Beam.Transparency = NumberSequence.new(transparency)
                beamEntry.Beam.Enabled = true
            else
                beamEntry.Beam.Enabled = false
                if part.Material ~= materialEnum then
                    part.Material = materialEnum
                end
                part.Transparency = transparency
            end
        end
    end
    return partIndex
end

local function TraceShotPenetrationPath(origin, direction)
    table.clear(RecordedPenetrationPoints)
    table.clear(RecordedPenetrationNormals)
    local hit = workspace:Raycast(origin, direction * 300, WallRaycastParams)
    if hit then
        table.insert(RecordedPenetrationPoints, hit.Position)
        table.insert(RecordedPenetrationNormals, hit.Normal)
    end
    return true
end

local function RecordShotVisuals(shotData)
    local sim = shotData.sim
    if not ((Flags.penvisualize or Flags.bullettrails) and sim and shotData.isGun) then
        return
    end
    RefreshGeometryFilter()

    local frame = shotData.shotFrame
    local origin, direction
    if frame then
        origin = frame.Position
        direction = (frame.Look + frame.Right * (frame.OffsetX or 0) + frame.Up * (frame.OffsetY or 0)).Unit
    else
        origin = sim.Eye
        direction = (Client.SilentPoint and (Client.SilentPoint - origin).Unit)
            or Client.ShotLook(Client.PrevSim or sim, shotData.yaw, shotData.pitch)
    end

    if not TraceShotPenetrationPath(origin, direction) then
        return
    end

    if Flags.penvisualize then
        local blocked = LastPenetrationEval.Blocked
        local isGood = if blocked then not blocked else (LastPenetrationEval.Walls == 0 or LastPenetrationEval.Damage >= (Flags.triggermindamage or 1))
        table.insert(ActivePenVisuals, {
            Time = os.clock(),
            Points = table.clone(RecordedPenetrationPoints),
            Normals = table.clone(RecordedPenetrationNormals),
            Good = isGood,
        })
        if #ActivePenVisuals > 6 then
            table.remove(ActivePenVisuals, 1)
        end
    end

    if Flags.bullettrails then
        table.insert(ActiveBulletTrails, {
            Time = os.clock(),
            Segments = BuildBulletTrailSegments(origin, direction),
        })
        if #ActiveBulletTrails > 12 then
            table.remove(ActiveBulletTrails, 1)
        end
    end
end

-- ============================================================================
-- [10] INDICATEURS DE MOUVEMENT & PIXEL SURF SPOTS (zVJ[4809], zVJ[12351], zVJ[14994], zVJ[1991]...)
-- ============================================================================

local MovementIndicatorsByName = {}
local MovementIndicatorsList = {}
local MovementIndicatorScale = 1
local ActiveMovementTimers = {}

local function ApplyIndicatorTheme(indicator) end
local function CancelIndicatorTween(indicator)
    if indicator.Tween then
        indicator.Tween:Cancel()
        indicator.Tween = nil
    end
end
local function GetIndicatorColor(flagKey, fallbackColor)
    local picker = Flags[flagKey]
    return (picker and picker.Color) or fallbackColor
end
local function GetHiddenSlidePosition(indicator)
    local r = indicator.Rest
    return UDim2.new(r.X.Scale, r.X.Offset, r.Y.Scale, r.Y.Offset + 14)
end
local function GetStrokeTrans()
    return 0.25
end
local function GetIndicatorOption(indicator, optKey, defaultVal)
    local val = Flags[(indicator.Prefix or "mv") .. optKey]
    if val == nil then return defaultVal end
    return val
end
local function CompareSpeedColor(curSpeed, prevSpeed)
    if curSpeed > prevSpeed then
        return Color3.fromRGB(30, 255, 109)
    elseif curSpeed < prevSpeed then
        return Color3.fromRGB(255, 90, 90)
    end
    return Color3.fromRGB(255, 255, 255)
end
local function StepIndicatorTweens(dt) end

-- zVJ[4809] : Crée un label d'indicateur de vitesse ou de mouvement
local function CreateMovementIndicator(name, config)
    local label = CreateInstance("TextLabel", {
        Name = "",
        AnchorPoint = config.Anchor,
        Position = config.Position,
        Size = config.Size,
        BackgroundTransparency = 1,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = config.TextSize,
        TextStrokeTransparency = 1,
        TextTransparency = 1,
        TextColor3 = config.Color,
        TextXAlignment = config.Align or Enum.TextXAlignment.Center,
        Text = config.Text,
        Visible = false,
        Parent = ESPScreenGui,
    })
    local uiScale = CreateInstance("UIScale", { Parent = label })
    local indicator = {
        Name = name,
        Label = label,
        Scale = uiScale,
        Rest = config.Position,
        Prefix = config.Prefix,
        Group = config.Group,
        StateColors = config.StateColors,
        Shown = false,
        Success = false,
        ActivatedAt = 0,
    }
    MovementIndicatorsByName[name] = indicator
    MovementIndicatorsList[#MovementIndicatorsList + 1] = indicator
    ApplyIndicatorTheme(indicator)
    return indicator
end

-- zVJ[12351] : Aligne et centre horizontalement les indicateurs appartenant au même groupe
local GroupBasePosition = UDim2.new(0.5, 0, 0.5, 60)
local function LayoutMovementIndicatorGroups()
    local groups = {}
    for _, ind in ipairs(MovementIndicatorsList) do
        if ind.Group and ind.Shown then
            local grp = groups[ind.Group]
            if not grp then
                grp = {}
                groups[ind.Group] = grp
            end
            grp[#grp + 1] = ind
        end
    end

    local gap = Flags.mvgap or 12
    for _, grp in pairs(groups) do
        table.sort(grp, function(a, b)
            return a.ActivatedAt < b.ActivatedAt
        end)
        local widths, totalWidth = {}, 0
        for i, ind in ipairs(grp) do
            local w = ind.Label.TextBounds.X * MovementIndicatorScale
            w = if w <= 0 then 24 else w
            widths[i] = w
            totalWidth += w
        end
        local currentX = -(totalWidth + gap * (#grp - 1)) / 2
        for i, ind in ipairs(grp) do
            ind.Rest = UDim2.new(
                GroupBasePosition.X.Scale,
                math.floor(GroupBasePosition.X.Offset + currentX + widths[i] / 2 + 0.5),
                GroupBasePosition.Y.Scale,
                GroupBasePosition.Y.Offset
            )
            currentX = currentX + widths[i] + gap
        end
    end
end

-- zVJ[14994] : Anime l'apparition ou la disparition d'un indicateur de mouvement
local function SetIndicatorVisible(indicator, visible)
    if indicator.Shown == visible then
        return
    end
    indicator.Shown = visible
    local label = indicator.Label
    CancelIndicatorTween(indicator)

    if visible then
        indicator.ActivatedAt = os.clock()
        LayoutMovementIndicatorGroups()
    end

    if indicator.StateColors then
        label.TextColor3 = indicator.Success
            and GetIndicatorColor("mvsuccess", Color3.fromRGB(30, 255, 109))
            or GetIndicatorColor("mvcolor", Color3.fromRGB(255, 255, 255))
    end

    local targetProps = {
        Position = visible and indicator.Rest or GetHiddenSlidePosition(indicator),
        TextTransparency = visible and 0 or 1,
        TextStrokeTransparency = visible and GetStrokeTrans() or 1,
    }

    if GetIndicatorOption(indicator, "anim", true) then
        if visible then
            label.Position = GetHiddenSlidePosition(indicator)
            label.TextTransparency = 1
            label.TextStrokeTransparency = 1
            label.Visible = true
        end
        local style = Enum.EasingStyle[GetIndicatorOption(indicator, "ease", "Quart")] or Enum.EasingStyle.Quart
        local direction = visible and Enum.EasingDirection.Out or Enum.EasingDirection.In
        local tween = Services.TweenService:Create(label, TweenInfo.new(GetIndicatorOption(indicator, "slidetime", 0.4), style, direction), targetProps)
        indicator.Tween = tween
        tween.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed and indicator.Shown == false then
                label.Visible = false
            end
        end)
        tween:Play()
    else
        label.Position = targetProps.Position
        label.TextTransparency = targetProps.TextTransparency
        label.TextStrokeTransparency = targetProps.TextStrokeTransparency
        label.Visible = visible
    end
end

local function UpdateIndicatorStatus(name, visible, isSuccess)
    local ind = MovementIndicatorsByName[name]
    if not ind then return end
    ind.Success = isSuccess and true or false
    if ind.StateColors and ind.Shown then
        ind.Label.TextColor3 = ind.Success
            and GetIndicatorColor("mvsuccess", Color3.fromRGB(30, 255, 109))
            or GetIndicatorColor("mvcolor", Color3.fromRGB(255, 255, 255))
    end
    SetIndicatorVisible(ind, visible)
end

local VelocityIndicator = CreateMovementIndicator("Velocity", {
    Anchor = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.78, 0),
    Size = UDim2.fromOffset(100, 28),
    TextSize = 24,
    Color = Color3.fromRGB(255, 255, 255),
    Text = "0",
    Prefix = "vel",
})

local PreVelocityIndicator = CreateMovementIndicator("PreVelocity", {
    Anchor = Vector2.new(0, 0.5),
    Position = UDim2.new(0.5, 40, 0.78, 0),
    Size = UDim2.fromOffset(80, 22),
    TextSize = 18,
    Color = Color3.fromRGB(200, 200, 200),
    Align = Enum.TextXAlignment.Left,
    Text = "(0)",
    Prefix = "vel",
})

CreateMovementIndicator("PixelSurf", {
    Anchor = Vector2.new(0.5, 0.5),
    Position = GroupBasePosition,
    Size = UDim2.fromOffset(40, 20),
    TextSize = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Text = "ps",
    Prefix = "mv",
    Group = "mv",
    StateColors = true,
})

CreateMovementIndicator("EdgeBug", {
    Anchor = Vector2.new(0.5, 0.5),
    Position = GroupBasePosition,
    Size = UDim2.fromOffset(40, 20),
    TextSize = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Text = "eb",
    Prefix = "mv",
    Group = "mv",
    StateColors = true,
})

CreateMovementIndicator("AirStuck", {
    Anchor = Vector2.new(0.5, 0.5),
    Position = GroupBasePosition,
    Size = UDim2.fromOffset(40, 20),
    TextSize = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Text = "as",
    Prefix = "mv",
    Group = "mv",
    StateColors = true,
})

CreateMovementIndicator("EdgeJump", {
    Anchor = Vector2.new(0.5, 0.5),
    Position = GroupBasePosition,
    Size = UDim2.fromOffset(40, 20),
    TextSize = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Text = "ej",
    Prefix = "mv",
    Group = "mv",
    StateColors = true,
})

local EbMarkerPart = CreateInstance("Part", {
    Name = "",
    Size = Vector3.new(1.2, 0.05, 1.2),
    Anchored = true,
    CanCollide = false,
    CanQuery = false,
    CanTouch = false,
    Transparency = 1,
    Parent = ChamsContainer,
})
local EbMarkerAdornment = CreateInstance("BoxHandleAdornment", {
    Name = "",
    Adornee = EbMarkerPart,
    Size = EbMarkerPart.Size,
    AlwaysOnTop = true,
    Visible = false,
    Parent = ChamsContainer,
})

-- zVJ[1991] : Mise à jour des indicateurs de vitesse et de mouvements (PixelSurf, EdgeBug, AirStuck, EdgeJump)
local wasAirborneLastFrame = false
local glideTimer = 0
local currentTakeoffSpeed = 0
local previousTakeoffSpeed = 0
local preVelocityExpireClock = 0
local lastVerticalSpeed = 0
local lastEdgeJumpsCount = 0
local lastSpeedComparisonValue = 0
local lastSpeedComparisonClock = 0
local lastEbEventCount = 0
local ebMarkerExpireClock = 0

local function MovementIndicatorsStep(dt)
    local cam = workspace.CurrentCamera
    if cam then
        MovementIndicatorScale = math.clamp(cam.ViewportSize.Y / 1080, 0.6, 1.2)
    end

    local showVel, showMv = Flags.velindicator, Flags.mvindicators
    local snap = Client.Snapshot
    local sim = snap and snap.sim
    local anyActive = showVel or showMv

    if not (anyActive and sim) then
        for _, ind in ipairs(MovementIndicatorsList) do
            ind.Success = false
            SetIndicatorVisible(ind, false)
        end
        StepIndicatorTweens(dt)
        return
    end

    local now = os.clock()
    local speed = math.floor((snap.speed or 0) + 0.5)
    local isAirborne = sim.Airborne == true
    local mvHold = Flags.mvhold or 1
    local preVelHold = Flags.velprehold or 1.5

    if wasAirborneLastFrame and not isAirborne then
        glideTimer = 0
    end
    if not wasAirborneLastFrame and isAirborne then
        previousTakeoffSpeed, currentTakeoffSpeed = currentTakeoffSpeed, speed
        PreVelocityIndicator.Label.TextColor3 = CompareSpeedColor(currentTakeoffSpeed, previousTakeoffSpeed)
    end
    if isAirborne then
        preVelocityExpireClock = now + preVelHold
    end

    if snap.glide then
        if glideTimer == 0 and lastVerticalSpeed < -8 then
            ActiveMovementTimers.EdgeBug = now + mvHold
        end
        glideTimer += dt
    else
        glideTimer = 0
    end

    lastVerticalSpeed = snap.vy or 0
    local edgeJumps = snap.edgeJumps or 0
    if edgeJumps > lastEdgeJumpsCount then
        ActiveMovementTimers.EdgeJump = now + mvHold
    end
    lastEdgeJumpsCount = edgeJumps

    VelocityIndicator.Label.Text = tostring(speed)
    VelocityIndicator.Label.TextColor3 = CompareSpeedColor(speed, lastSpeedComparisonValue)
    PreVelocityIndicator.Label.Text = "(" .. currentTakeoffSpeed .. ")"

    local velRest = VelocityIndicator.Rest
    PreVelocityIndicator.Rest = UDim2.new(
        velRest.X.Scale,
        math.floor(velRest.X.Offset + VelocityIndicator.Label.TextBounds.X / 2 * MovementIndicatorScale + (Flags.velpregap or 6) + 0.5),
        velRest.Y.Scale,
        velRest.Y.Offset
    )

    local velShouldShow = speed > 0 or Flags.velstill
    UpdateIndicatorStatus("Velocity", showVel and velShouldShow and true or false, false)
    UpdateIndicatorStatus("PreVelocity", showVel and velShouldShow and preVelocityExpireClock > now and true or false, false)

    local ebEvent = snap.ebEvent
    if ebEvent and ebEvent.Count > lastEbEventCount then
        lastEbEventCount = ebEvent.Count
        if Flags.ebmarker then
            EbMarkerPart.CFrame = CFrame.new(ebEvent.Position + Vector3.new(0, 0.05, 0))
            ebMarkerExpireClock = now + (Flags.ebmarkertime or 8)
            ActiveMovementTimers.EdgeBug = now + mvHold
        end
    end

    EbMarkerAdornment.Visible = Flags.ebmarker == true and now < ebMarkerExpireClock
    EbMarkerAdornment.Color3 = (Flags.ebmarkercolor and Flags.ebmarkercolor.Color) or Color3.fromRGB(255, 255, 255)
    EbMarkerAdornment.Transparency = Client.Trans("ebmarkercolor")

    local mvList = Flags.mvlist
    local function CheckMovementIndicator(indName, shortCode, flagName, kbFlagName, isSuccess)
        local active = showMv and TableContains(mvList, shortCode) and IsFeatureAndKeyActive(flagName, kbFlagName)
        UpdateIndicatorStatus(indName, active and true or false, active and isSuccess)
    end

    CheckMovementIndicator("PixelSurf", "ps", "surfassist", "surfassistkb", glideTimer >= 0.1)
    CheckMovementIndicator("EdgeBug",   "eb", "edgebug",    "edgebugkb",    (ActiveMovementTimers.EdgeBug or 0) > now)
    CheckMovementIndicator("AirStuck",  "as", "airstuck",   "airstuckkb",   glideTimer >= 0.05 and speed <= 2)
    CheckMovementIndicator("EdgeJump",  "ej", "edgejump",   "edgejumpkb",   (ActiveMovementTimers.EdgeJump or 0) > now)

    if now - lastSpeedComparisonClock >= 0.078 then
        lastSpeedComparisonValue, lastSpeedComparisonClock = speed, now
    end
    wasAirborneLastFrame = isAirborne
    StepIndicatorTweens(dt)
end

-- zVJ[11889] & zVJ[3868] : Sauvegarde des spots de Pixel Surf
local SavedSurfSpotsFile = "moon_spots.json"
local SavedSurfSpots = {}

local function SavePixelSurfSpots()
    pcall(function()
        writefile(SavedSurfSpotsFile, Services.HttpService:JSONEncode(SavedSurfSpots))
    end)
    Client.SendCommand("spots", SavedSurfSpots)
end

local function OnPixelSurfSpotSaved(spotData)
    table.insert(SavedSurfSpots, spotData)
    SavePixelSurfSpots()
    UI:Notification({
        Name = string.format("pixel surf spot saved (%d ticks, start speed %.1f)", #spotData.steps, spotData.startSpeed or 0),
        Time = 5,
    })
end

-- ============================================================================
-- [11] ÉCLAIRAGE DU MONDE / WORLD LIGHTING (zVJ[12216], zVJ[9853], zVJ[10679])
-- ============================================================================

local OriginalLightingBackup = nil
local LightingPropertiesToSave = {
    "ClockTime", "Brightness", "ExposureCompensation",
    "Ambient", "OutdoorAmbient", "FogColor", "FogStart", "FogEnd", "GlobalShadows",
}

-- zVJ[12216] : Récupère la couleur d'une option si son interrupteur est activé
local function GetToggleColor(isEnabled, colorFlagName)
    local colorPicker = Flags[colorFlagName]
    return isEnabled and colorPicker and colorPicker.Color or nil
end

-- zVJ[9853] : Restaure les paramètres d'origine du service Lighting
local function RestoreOriginalLighting()
    if OriginalLightingBackup then
        for prop, val in pairs(OriginalLightingBackup) do
            pcall(function()
                Lighting[prop] = val
            end)
        end
        OriginalLightingBackup = nil
    end
end

-- zVJ[10679] : Applique les paramètres personnalisés de World Lighting
local function UpdateWorldLighting()
    if not Flags.wlon then
        RestoreOriginalLighting()
        return
    end
    if not OriginalLightingBackup then
        OriginalLightingBackup = {}
        for _, prop in ipairs(LightingPropertiesToSave) do
            OriginalLightingBackup[prop] = Lighting[prop]
        end
    end

    Lighting.ClockTime = Flags.wltime or 12
    Lighting.Brightness = Flags.wlbright or 2
    Lighting.ExposureCompensation = Flags.wlexposure or 0
    Lighting.Ambient = GetToggleColor(Flags.wlambient, "wlambientcolor") or OriginalLightingBackup.Ambient
    Lighting.OutdoorAmbient = GetToggleColor(Flags.wloutdoor, "wloutdoorcolor") or OriginalLightingBackup.OutdoorAmbient

    local fogColor = GetToggleColor(Flags.wlfog, "wlfogcolor")
    Lighting.FogColor = fogColor or OriginalLightingBackup.FogColor
    Lighting.FogStart = (fogColor and (Flags.wlfogstart or 0)) or OriginalLightingBackup.FogStart
    Lighting.FogEnd = (fogColor and (Flags.wlfogend or 1000)) or OriginalLightingBackup.FogEnd
    Lighting.GlobalShadows = if Flags.wlnoshadows then not Flags.wlnoshadows else OriginalLightingBackup.GlobalShadows
end

-- ============================================================================
-- [12] MOTEUR DE LA MACHINE VIRTUELLE LURAPH (zVJ["Oz"], zVJ["vm"], zVJ["Uz"], zVJ[7094])
-- ============================================================================

-- zVJ["Oz"] : Gestionnaire d'erreurs de la VM Luraph
local function LuraphErrorHandler(vmTable, errMessage, instructionIndex, lineMap)
    if type(errMessage) == "string" then
        if string.match(errMessage, "[%:](%d+)[\13%:\10]") then
            local mappedLine = lineMap[instructionIndex]
            local lineStr = mappedLine and tostring(mappedLine) or "?"
            error("LPH:" .. lineStr .. ": " .. errMessage, 0)
        else
            error(errMessage, 0)
        end
    else
        error(errMessage, 1)
    end
end

-- zVJ["vm"] : Décompression de l'en-tête "LPH/" à l'aide de la table fz
local function DecompressLPHPayload(vmTable)
    local rawBody = string.sub(vmTable.jz, 5)
    local expanded = string.gsub(rawBody, vmTable.lz, vmTable.fz)
    local byteBuffer = buffer.fromstring(expanded)
    return byteBuffer, #expanded - 1
end

-- zVJ["Uz"] : Décodage Base85 d'un entier 32-bits depuis le flux LPH
local function DecodeBase85Uint32(c1, c2, c3, c4, c5)
    return (c1 - 35) * 1
        + (c2 - 35) * 85
        + (c3 - 35) * 7225
        + (c4 - 35) * 614125
        + (c5 - 35) * 52200625
end

-- ============================================================================
-- [13] BOUCLES MAÎTRESSES D'EXÉCUTION (zVJ[6519], zVJ[4007] & RunService)
-- ============================================================================

-- zVJ[6519] : Boucle maîtresse de rendu ESP (appelée à chaque RenderStepped)
local function ESPStep(dt)
    local snap = Client.Snapshot
    ESP.ChamsStep(snap)
    ESP.CrosshairStep(snap, dt)
    ESP.HitStep(snap)
    ESP.MoveSoundStep(snap)
    ESP.ArrowStep(snap)
    ESP.ItemStep()

    if not Flags.esp then
        if next(ESP.Drawings) then
            ESP:Disable()
        end
        return
    end
    if not snap then
        return
    end

    SyncESPSettings()
    local activeIds = {}
    for _, entity in ipairs(snap.entities) do
        local id = entity.Id
        if entity.Model and not Client.IsLocal(entity) then
            local hp = entity.Health
            if hp and hp > 0 and not (ESPState.teamCheck and not Client.IsEnemy(entity)) then
                activeIds[id] = true
                ESP:Update(id, entity, ESP.Drawings[id] or ESP:Create(id, entity), dt)
            end
        end
    end

    for id in pairs(ESP.Drawings) do
        if not activeIds[id] then
            ESP:Remove(id)
        end
    end
end

-- zVJ[4007] : Boucle maîtresse de combat (appelée à chaque Heartbeat)
local function CombatStep(dt)
    if not RagebotStep() then
        if not LegitAimbotStep(dt) then
            RecoilCompensationStep(dt)
        end
    end
    SilentAimStep()
    TriggerbotAndAutoFireStep()
    UpdateAimbotFOVCircle()
    UpdateSilentFOVCircle()
    NoScopeBlackStep()
    SelfChamsStep()
end

-- Connexion des signaux de la caméra et des boucles principales
BindCameraSignals(function()
    UpdateAimbotFOVCircle()
end)

Services.RunService.RenderStepped:Connect(function(dt)
    ESPStep(dt)
    MovementIndicatorsStep(dt)
    UpdateWorldLighting()
end)

Services.RunService.Heartbeat:Connect(function(dt)
    CombatStep(dt)
end)

return {
    UI = UI,
    Flags = Flags,
    Client = Client,
    ESP = ESP,
    OnShotEvent = OnShotEvent,
    RecordShotVisuals = RecordShotVisuals,
    OnPixelSurfSpotSaved = OnPixelSurfSpotSaved,
}
