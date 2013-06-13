local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE", false)

if not L then return end

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore", escape-non-ascii=false, same-key-is-true=true)@
