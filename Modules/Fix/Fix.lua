-- Fix 1: GUILD_NEWS_DUNGEON_ENCOUNTER_NORMAL is nil and trigger errors when using the new guild UI
if (not GUILD_NEWS_DUNGEON_ENCOUNTER_NORMAL) then
  GUILD_NEWS_DUNGEON_ENCOUNTER_NORMAL = "|cffd10000[%s]|r";
end
