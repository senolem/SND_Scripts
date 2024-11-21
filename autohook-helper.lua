-- Settings

do_spiritbonding = true     -- Auto spiritbonding
do_repair = true            -- Auto repair
repair_threshold = 30       -- Minimum % before repairing gear
check_rate = 5              -- Seconds to wait between each check
interval_rate = 0.2         -- Seconds to wait between each action
interval_move = 10          -- Minutes to wait between each movement
stop_main = false

-- Move stuff
move_timer = interval_move * 60
move_direction = true
fishing_start_time = os.time()

-- Functions

function main()
    while not stop_main do
        if isPauseNeeded() then
            print("Pause needed, waiting for player to be available...")
            while not IsPlayerAvailable() and GetCharacterCondition(43) and GetCharacterCondition(6) do
                yield("/wait "..interval_rate)
            end
            while GetCharacterCondition(6) do
                yield("/ac Abandon")
                yield("/wait 1")
            end
            if should_move then
                moveAside()
                should_move = false
            end
            if do_repair and isRepairNeeded() then
                print("Attempting to perform self-repair...")
                repair()
            end
            if do_spiritbonding and CanExtractMateria() then
                print("Attempting to perform spiritbonding...")
                spiritbonding()
            end
        else
            if (GetCharacterCondition(6) and not GetCharacterCondition(43)) or GetCharacterCondition(1) then
                yield("/ac Pêche")
                fishing_start_time = os.time()
            end
            yield("/wait "..check_rate)
        end
    end
end

function isPauseNeeded()
    return (do_repair and isRepairNeeded())
        or (do_spiritbonding and CanExtractMateria())
        or (needToMove())
end

function isRepairNeeded()
    if do_repair == true then
        repair_threshold = tonumber(repair_threshold) or 99
        if NeedsRepair(repair_threshold) then
            return true
        else
            return false
        end
    end
end

function spiritbonding()
    while CanCharacterDoActions() and not IsAddonVisible("Materialize") and not IsAddonReady("Materialize") do
        yield('/gaction "Matérialisation"')
        repeat
            yield("/wait "..interval_rate)
        until IsPlayerAvailable()
    end
    while CanCharacterDoActions() and CanExtractMateria() do
        
        yield("/wait 0.1")
        yield("/pcall Materialize true 2 0")
        repeat
            if not CanCharacterDoActions() then return end
            yield("/wait 1")
        until not GetCharacterCondition(39)
    end
    while CanCharacterDoActions() and IsAddonVisible("Materialize") do
        yield('/gaction "Matérialisation"')
        repeat
            yield("/wait "..interval_rate)
        until IsPlayerAvailable()
    end
    if CanExtractMateria() then
        print("Failed to fully extract all materia!")
        print("Please check your if you have spare inventory slots,")
        print("Or manually extract any materia.")
        return false
    else
        print("Materia extraction complete!")
    end
end

function repair()
    while CanCharacterDoActions() and not IsAddonVisible("Repair") and not IsAddonReady("Repair") do
        yield('/gaction "Réparation"')
        repeat
            if not CanCharacterDoActions() then return end
            yield("/wait "..interval_rate)
        until IsPlayerAvailable()
    end
    yield("/wait 0.1")
    yield("/pcall Repair true 0")
    repeat
        yield("/wait "..interval_rate)
    until IsAddonVisible("SelectYesno") and IsAddonReady("SelectYesno")
    yield("/pcall SelectYesno true 0")
    repeat
        yield("/wait "..interval_rate)
    until not IsAddonVisible("SelectYesno")
    while GetCharacterCondition(39) do yield("/wait "..interval_rate) end
    while IsAddonVisible("Repair") do
        yield('/gaction "Réparation"')
        repeat
            yield("/wait "..interval_rate)
        until IsPlayerAvailable()
    end
    if NeedsRepair() then
        print("Self-repair failed!")
        print("Please place the appropriate Dark Matter in your inventory,")
        return false
    else
        print("Repairs complete!")
    end
end

function print(message)
    yield("/echo [Autohook-Helper] "..message)
end

function CanCharacterDoActions()
    return not (GetCharacterCondition(6) or GetCharacterCondition(32) or GetCharacterCondition(45) or GetCharacterCondition(27) or GetCharacterCondition(4))
end

function moveAside()
    currentX = GetPlayerRawXPos
    currentY = GetPlayerRawYPos
    currentZ = GetPlayerRawZPos
    if move_direction then
        currentX = currentX + 1
    else
        currentX = currentX - 1
    end
    move_direction = not move_direction
    PathfindAndMoveTo(X, Y, Z, false)
    while (PathIsRunning() or IsMoving()) then
        yield("/wait 1")
    end
    fishing_start_time = os.time()
end

function needToMove()
    if fishing_start_time + move_timer > os.time() then
        should_move = true
        return true
    else
        return false
    end
end

main()