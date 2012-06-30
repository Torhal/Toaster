local ADDON_NAME, private = ...

local _G = getfenv(0)

local is_release = true
--@debug@
is_release = false
--@end-debug@


local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", is_release, is_release)

if not L then return end

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="ignore", escape-non-ascii=false, same-key-is-true=true)@
