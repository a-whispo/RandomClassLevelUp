print("--- ClassUtils Loaded ---");

ClassUtils = {};
ClassUtils.Classes = {};
ClassUtils.SubClasses = {};
ClassUtils.SubClassesByClass = {};
ClassUtils.RandomClassProgressionUUID = {"ab4f357c-5341-4847-9a82-89ab991fdd07", "f0d4b817-7f32-4d1c-9cc6-312246f4459e", "bbedefa5-6782-4cc0-9c23-e305d5db7c05", "46f10ddb-cc5f-4759-ae43-ec95d783f761"};
ClassUtils.RandomClassDescriptionUUID = {"2d92a486-53b3-426d-90e1-3ee4358831b3", "51dc4e18-ab39-4491-afd7-eea6ee5711b6", "06649c00-8b21-4855-9c3e-00cbeadc6cf0", "78b3d069-22d5-47fa-80b1-663918303b0d"};
ClassUtils.PlaceholderUUID = {"72700000-0000-0000-0000-000000000001", "72700000-0000-0000-0000-000000000002", "72700000-0000-0000-0000-000000000003", "72700000-0000-0000-0000-000000000004"};
ClassUtils.EmptyUUID = "00000000-0000-0000-0000-000000000000";

function ClassUtils.IsClass(name)
    return ClassUtils.Classes[name] or false;
end

function ClassUtils.IsSubClass(name)
    return ClassUtils.SubClasses[name] or false;
end

function ClassUtils.GetSubClasses(name)
    return ClassUtils.SubClassesByClass[name] or {};
end

if #ClassUtils.Classes == 0 then
    for _, UUID in ipairs(Ext.StaticData.GetAll("ClassDescription")) do
        local description = Ext.StaticData.Get(UUID, "ClassDescription");
        if description.ParentGuid == ClassUtils.EmptyUUID then
            -- no parent means its a class
            if not ClassUtils.Classes[description.Name] then
                ClassUtils.Classes[description.Name] = true;
            end
        else
            -- parent means its a subclass
            local parent = Ext.StaticData.Get(description.ParentGuid, "ClassDescription");
            if not ClassUtils.SubClassesByClass[parent.Name] then
                ClassUtils.SubClassesByClass[parent.Name] = {};
            end
            table.insert(ClassUtils.SubClassesByClass[parent.Name], { Name = description.Name, DescriptionUUID = description.ResourceUUID });
            if not ClassUtils.SubClasses[description.Name] then
                ClassUtils.SubClasses[description.Name] = true;
            end
        end
    end
    print("* Filtered all classes and subclasses.");
end