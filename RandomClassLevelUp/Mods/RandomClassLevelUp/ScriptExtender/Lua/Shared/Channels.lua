local Channels = {};
Channels.Sync = Ext.Net.CreateChannel(ModuleUUID, "Sync");
Channels.RequestSync = Ext.Net.CreateChannel(ModuleUUID, "RequestSync");
return Channels;