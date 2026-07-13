Ext.Require("ClassUtils.lua");

print("--- Loading Server ---");

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

function RandomizeProgression(ProgressionTableUUID, DescriptionTableUUID, PlaceholderUUID, seed)

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
    local lvl1ClassName;
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
        class.TableUUID = ProgressionTableUUID;
        if level == 1 then
            lvl1ClassName = class.Name;
        end
    end

    -- copy class description of the class we got at lvl 1
    local randomClassDesc = Ext.StaticData.Get(DescriptionTableUUID, "ClassDescription");
    for _, UUID in ipairs(Ext.StaticData.GetAll("ClassDescription")) do
        local classDesc = Ext.StaticData.Get(UUID, "ClassDescription");
        if classDesc.Name == lvl1ClassName then
            randomClassDesc.CanLearnSpells = classDesc.CanLearnSpells;
            randomClassDesc.CharacterCreationPose = classDesc.CharacterCreationPose;
            randomClassDesc.ClassEquipment = classDesc.ClassEquipment;
            randomClassDesc.HasGod = classDesc.HasGod;
            randomClassDesc.HpPerLevel = classDesc.HpPerLevel;
            randomClassDesc.MustPrepareSpells = classDesc.MustPrepareSpells;
            randomClassDesc.PrimaryAbility = classDesc.PrimaryAbility;
            randomClassDesc.SomaticEquipmentSet = classDesc.SomaticEquipmentSet;
            randomClassDesc.SoundClassType = classDesc.SoundClassType;
            randomClassDesc.SpellCastingAbility = classDesc.SpellCastingAbility;
            randomClassDesc.SpellList = classDesc.SpellList;
            randomClassDesc.Tags = classDesc.Tags; -- do something more with this, add all the other tags as you level up?
        end
    end

    -- list classes for debugging
    local classes = {};
    for j, UUID in ipairs(Ext.StaticData.GetAll("Progression")) do
        local data = Ext.StaticData.Get(UUID, "Progression");
        if data.TableUUID == ProgressionTableUUID then
            table.insert(classes, data);
        end
    end
    table.sort(classes, function(class1, class2)
        return class1.Level < class2.Level;
    end)
    for _, class in ipairs(classes) do
        print("Lvl ".. class.Level .. ": " .. class.Name);
    end
end

Ext.Events.SessionLoaded:Subscribe(function()

    -- get/generate seeds
    if not Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds then
        local time = Ext.Timer.MonotonicTime();
        print("* Creating a new seeds based on the time: " .. time);
        Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds = {time, time - 100, time - 200, time - 300};
    end
    local seeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
    print("* Seeds:");
    _D(seeds);

    -- randomize everything
    for i, seed in ipairs(seeds) do
        RandomizeProgression(ClassUtils.RandomClassProgressionUUID[i], ClassUtils.RandomClassDescriptionUUID[i], ClassUtils.PlaceholderUUID[i], seed);
    end
end)

Ext.Osiris.RegisterListener("FlagSet", 3, "before", function(flag, speaker, dialogInstance)
    local i = 0;
    if flag == "RerollRandom1_d2e409dd-15c6-40d0-9fa1-4abe1713dc86" then
        i = 1;
    elseif flag ==  "RerollRandom2_6141243e-8dd6-4509-9f73-5018b762ea5f" then
        i = 2;
    elseif flag ==  "RerollRandom3_2ba69774-8538-4fc4-9271-a25f9df5b3b9" then
        i = 3;
    elseif flag ==  "RerollRandom4_4b9ca7a9-d5ab-470c-9462-aea445d0e26c" then
        i = 4;
    end

    if i ~= 0 then
        local newSeeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
        newSeeds[i] = Ext.Timer.MonotonicTime();
        Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds = newSeeds;
        Osi.ClearFlag(flag);
        print("* New seeds:");
        local seeds = Ext.Vars.GetModVariables(ModuleUUID).RandomClassSeeds;
        _D(seeds);
        RandomizeProgression(ClassUtils.RandomClassProgressionUUID[i], ClassUtils.RandomClassDescriptionUUID[i], ClassUtils.PlaceholderUUID[i], seeds[i]);
    end
end)

Ext.Vars.RegisterModVariable(ModuleUUID, "RandomClassSeeds", { DontCache = true });