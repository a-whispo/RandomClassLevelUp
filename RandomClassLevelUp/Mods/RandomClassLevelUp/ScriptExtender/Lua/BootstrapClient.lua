print("--- Loading Client ---");

local ClassUtils = Ext.Require("Shared/ClassUtils.lua");
local Channels = Ext.Require("Shared/Channels.lua");
local ClassRandomizer = Ext.Require("Shared/ClassRandomizer.lua");

Channels.Sync:SetHandler(function(data, user)
    print("(C) Got a Sync request, randomizing.")
    ClassRandomizer.Randomize(data);
end)

Ext.Events.SessionLoaded:Subscribe(function()
    print("(C) Sent a SyncRequest.");
    Channels.RequestSync:RequestToServer({}, function(response)
        print("(C) Got data back, randomizing.");
        for _, data in ipairs(response) do
            ClassRandomizer.Randomize(data);
        end
    end)
end)

local allAddedProgressions = {};
local addedClasses = {};
local addedSubClasses = {};
local newClassFound = false;

function ShouldAdd(name)
    for _, class in ipairs(allAddedProgressions) do
        if class == name then
            return false;
        end
    end
    return true;
end

-- look over all classes and see which have already been added
for _, progressionUUID in ipairs(Ext.StaticData.GetAll("Progression")) do
    local progression = Ext.StaticData.Get(progressionUUID, "Progression");
    for  _, UUID in ipairs(ClassUtils.PlaceholderUUID) do
        if progression.TableUUID == UUID then
            table.insert(allAddedProgressions, progression.Name);
        end
    end
    for  _, UUID in ipairs(ClassUtils.RandomClassProgressionUUID) do
        if progression.TableUUID == UUID then
            table.insert(allAddedProgressions, progression.Name);
        end
    end
end

-- add everything to the Random class's Progression table
for _, progressionUUID in ipairs(Ext.StaticData.GetAll("Progression")) do

    -- make sure this is a valid class or subclass, otherwise theres no need to create a new row in our Progression table
    local progression = Ext.StaticData.Get(progressionUUID, "Progression");
    if ShouldAdd(progression.Name) and not progression.IsMulticlass and (ClassUtils.IsClass(progression.Name) or ClassUtils.IsSubClass(progression.Name)) then
        for i = 1, 4 do
            local newProgressionUUID = Ext.Utils.GenerateGuid();
            Ext.StaticData.Create("Progression", newProgressionUUID);
            local newProgressionData = Ext.StaticData.Get(newProgressionUUID, "Progression");

            -- copy everything over
            newProgressionData.Name = progression.Name;
            newProgressionData.Level = progression.Level;
            newProgressionData.Boosts = progression.Boosts;
            newProgressionData.BoostPrototypes = progression.BoostPrototypes;
            --data.PassivePrototypesAdded = progression.PassivePrototypesAdded;
            --data.PassivePrototypesRemoved = progression.PassivePrototypesRemoved;
            newProgressionData.PassivesAdded = progression.PassivesAdded;
            newProgressionData.PassivesRemoved = progression.PassivesRemoved;
            newProgressionData.AllowImprovement = progression.AllowImprovement;
            newProgressionData.SelectAbilities = progression.SelectAbilities;
            newProgressionData.SelectAbilityBonus = progression.SelectAbilityBonus;
            newProgressionData.SelectSkills = progression.SelectSkills;
            newProgressionData.SelectSkillsExpertise = progression.SelectSkillsExpertise;
            newProgressionData.SelectSpells = progression.SelectSpells;
            newProgressionData.SelectPassives = progression.SelectPassives;
            newProgressionData.SelectEquipment = progression.SelectEquipment;
            newProgressionData.AddSpells = progression.AddSpells;
            newProgressionData.SubClasses = progression.SubClasses;
            newProgressionData.ProgressionType = progression.ProgressionType;
            newProgressionData.TableUUID = ClassUtils.PlaceholderUUID[i];

            if ClassUtils.IsClass(newProgressionData.Name) then
                table.insert(addedClasses, newProgressionData);
            else
                table.insert(addedSubClasses, newProgressionData);
            end
        end
        newClassFound = true;
    end
end
print("* Added all classes to Progression table.");

-- add unique ClassDescriptions for each subclass level
for i = 1, 4 do
    if not newClassFound then
        break;
    end

    for _, class in ipairs(addedClasses) do
        local subClasses = ClassUtils.GetSubClasses(class.Name);
        if class.TableUUID ~= ClassUtils.PlaceholderUUID[i] or #subClasses == 0 then
            goto continue;
        end

        local subClassesToAdd = {};
        for _, subClass in ipairs(subClasses) do
            for _, addedSubClass in ipairs(addedSubClasses) do
                if addedSubClass.TableUUID == ClassUtils.PlaceholderUUID[i] and addedSubClass.Level == class.Level and addedSubClass.Name == subClass.Name then
                    local UUID = Ext.Utils.GenerateGuid();
                    Ext.StaticData.Create("ClassDescription", UUID);
                    local newSubClassDescription = Ext.StaticData.Get(UUID, "ClassDescription");
                    newSubClassDescription.ParentGuid = ClassUtils.RandomClassDescriptionUUID[i];
                    newSubClassDescription.Name = addedSubClass.Name;

                    -- copy everything over
                    local originalSubClassDescription = Ext.StaticData.Get(subClass.DescriptionUUID, "ClassDescription");
                    newSubClassDescription.DisplayName = originalSubClassDescription.DisplayName;
                    newSubClassDescription.SubclassTitle = originalSubClassDescription.SubclassTitle;
                    newSubClassDescription.CanLearnSpells = originalSubClassDescription.CanLearnSpells;
                    newSubClassDescription.CharacterCreationPose = originalSubClassDescription.CharacterCreationPose;
                    newSubClassDescription.ClassEquipment = originalSubClassDescription.ClassEquipment;
                    newSubClassDescription.HasGod = originalSubClassDescription.HasGod;
                    newSubClassDescription.HpPerLevel = originalSubClassDescription.HpPerLevel;
                    newSubClassDescription.MustPrepareSpells = originalSubClassDescription.MustPrepareSpells;
                    newSubClassDescription.PrimaryAbility = originalSubClassDescription.PrimaryAbility;
                    newSubClassDescription.SomaticEquipmentSet = originalSubClassDescription.SomaticEquipmentSet;
                    newSubClassDescription.SoundClassType = originalSubClassDescription.SoundClassType;
                    newSubClassDescription.SpellCastingAbility = originalSubClassDescription.SpellCastingAbility;
                    newSubClassDescription.SpellList = originalSubClassDescription.SpellList;
                    newSubClassDescription.Tags = originalSubClassDescription.Tags;

                    -- "b659e449-100f-424f-bba2-96cecc7bb2ea" is the uuid of a fake ClassDescription just so we can copy the Description over
                    newSubClassDescription.Description = Ext.StaticData.Get("b659e449-100f-424f-bba2-96cecc7bb2ea", "ClassDescription").Description;

                    Ext.StaticData.Get(addedSubClass.ResourceUUID, "Progression").TableUUID = Ext.Utils.GenerateGuid();
                    newSubClassDescription.ProgressionTableUUID = Ext.StaticData.Get(addedSubClass.ResourceUUID, "Progression").TableUUID;
                    table.insert(subClassesToAdd, newSubClassDescription.ResourceUUID);
                    break;
                end
            end
        end
        Ext.StaticData.Get(class.ResourceUUID, "Progression").SubClasses = subClassesToAdd;
        ::continue::;
    end
end
print("* Added all subclasses to Progression table.");

-- change ProgressionIds in the description to be global and not specific to classes
for _, descriptionUUID in ipairs(Ext.StaticData.GetAll("ProgressionDescription")) do
    local description = Ext.StaticData.Get(descriptionUUID, "ProgressionDescription");
    description.ProgressionTableId = ClassUtils.EmptyUUID;
    description.ProgressionId = ClassUtils.EmptyUUID;
end
print("* Modified descriptions in ProgressionDescriptions.");