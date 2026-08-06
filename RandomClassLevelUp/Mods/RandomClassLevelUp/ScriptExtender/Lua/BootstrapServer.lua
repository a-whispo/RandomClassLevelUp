local ClassUtils = Ext.Require("Shared/ClassUtils.lua");
local Channels = Ext.Require("Shared/Channels.lua");
local ClassRandomizer = Ext.Require("Shared/ClassRandomizer.lua");
local CurrentData = {};

Channels.RequestSync:SetRequestHandler(function(data, user)
    return CurrentData;
end)

-- need a manual random function since math.randomseed isnt implemented
function CreateRandom(seed)
    local state = seed or Ext.Timer.MonotonicTime();
    return function(min, max)
        state = (1103515245 * state + 12345) % 2147483648;
        if min and max then
            return min + (state % (max - min + 1));
        elseif min then
            return state % min;
        else
            return state / 2147483648;
        end
    end
end

function RandomizeProgression(RandomClassIndex, seed)
    local ProgressionTableUUID = ClassUtils.RandomClassProgressionUUID[RandomClassIndex];
    local DescriptionTableUUID = ClassUtils.RandomClassDescriptionUUID[RandomClassIndex];
    local PlaceholderUUID = ClassUtils.PlaceholderUUID[RandomClassIndex];
    local data = { RandomClassIndex = RandomClassIndex, Lvl1ClassName = "None", ProgressionEntries = {} };

    -- reset everything so we can re seed everything and make sure everything is fine
    local random = CreateRandom(seed);
    for _, UUID in ipairs(Ext.StaticData.GetAll("Progression")) do
        local progression = Ext.StaticData.Get(UUID, "Progression");
        if progression.TableUUID == ProgressionTableUUID then
            progression.TableUUID = PlaceholderUUID;
        end
    end

    -- probably a really inefficent way to do this but it also doesnt really matter
    -- lvl cap is 20 in this case
    for level = 1, 20 do
        
        -- find a random class
        local possibleClasses = {};
        for _, UUID in ipairs(Ext.StaticData.GetAll("Progression")) do
            local possibleClass = Ext.StaticData.Get(UUID, "Progression");
            if ClassUtils.IsClass(possibleClass.Name) and possibleClass.TableUUID == PlaceholderUUID and possibleClass.Level == level and not (possibleClass.Name == "Random1" or possibleClass.Name == "Random2" or possibleClass.Name == "Random3" or possibleClass.Name == "Random4") then
                table.insert(possibleClasses, possibleClass);
            end
        end
        if #possibleClasses == 0 then
            break;
        end
        local class = possibleClasses[random(1, #possibleClasses)];
        table.insert(data.ProgressionEntries, class.ResourceUUID);
        if level == 1 then
            data.Lvl1ClassName = class.Name;
        end
    end

    -- sync
    CurrentData[RandomClassIndex] = data;
    ClassRandomizer.Randomize(data);
    Channels.Sync:Broadcast(data)
end

Ext.Events.SessionLoaded:Subscribe(function()

    -- get/generate seeds
    if not Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds then
        local time = Ext.Timer.MonotonicTime();
        Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds = {time, time - 100, time - 200, time - 300};
    end
    
    -- randomize everything
    local seeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
    for i, seed in ipairs(seeds) do
        RandomizeProgression(i, seed);
    end
end)

Ext.Osiris.RegisterListener("FlagSet", 3, "before", function(flag, speaker, dialogInstance)
    local i = 0;
    if flag == "RerollRandom1_d2e409dd-15c6-40d0-9fa1-4abe1713dc86" then
        i = 1;
    elseif flag == "RerollRandom2_6141243e-8dd6-4509-9f73-5018b762ea5f" then
        i = 2;
    elseif flag == "RerollRandom3_2ba69774-8538-4fc4-9271-a25f9df5b3b9" then
        i = 3;
    elseif flag == "RerollRandom4_4b9ca7a9-d5ab-470c-9462-aea445d0e26c" then
        i = 4;
    end

    if i ~= 0 then
        local newSeeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
        newSeeds[i] = Ext.Timer.MonotonicTime();
        Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds = newSeeds;
        Osi.ClearFlag(flag);
        local seeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
        RandomizeProgression(i, seeds[i]);
    end
end)

Ext.Vars.RegisterModVariable(ModuleUUID, "RandomClassSeeds", { DontCache = true });