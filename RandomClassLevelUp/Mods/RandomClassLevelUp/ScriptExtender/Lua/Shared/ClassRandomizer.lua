local ClassRandomizer = {};
local ClassUtils = Ext.Require("Shared/ClassUtils.lua");

function ClassRandomizer.Randomize(data)
    local ProgressionTableUUID = ClassUtils.RandomClassProgressionUUID[data.RandomClassIndex];
    local DescriptionTableUUID = ClassUtils.RandomClassDescriptionUUID[data.RandomClassIndex];
    local PlaceholderUUID = ClassUtils.PlaceholderUUID[data.RandomClassIndex];
    
    -- reset everything so we can re seed everything and make sure everything is fine
    for _, UUID in ipairs(Ext.StaticData.GetAll("Progression")) do
        local progression = Ext.StaticData.Get(UUID, "Progression");
        if progression.TableUUID == ProgressionTableUUID then
            progression.TableUUID = PlaceholderUUID;
        end
    end
    
    -- add random classes to our progression table
    for _, UUID in ipairs(data.ProgressionEntries) do
        local progression = Ext.StaticData.Get(UUID, "Progression");
        progression.TableUUID = ProgressionTableUUID;
    end

    -- copy class description of the class we got at lvl 1
    local randomClassDesc = Ext.StaticData.Get(DescriptionTableUUID, "ClassDescription");
    for _, UUID in ipairs(Ext.StaticData.GetAll("ClassDescription")) do
        local classDesc = Ext.StaticData.Get(UUID, "ClassDescription");
        if classDesc.Name == data.Lvl1ClassName then
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
end

return ClassRandomizer;