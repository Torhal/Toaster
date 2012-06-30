local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)

if not L then return end

L["Background"] = true
L["Emergency"] = true
L["Floating Icon"] = true
L["Hide Toasts"] = true
L["High"] = true
L["Icon Size"] = true
L["Moderate"] = true
L["Normal"] = true
L["Preview"] = true
L["Show Minimap Icon"] = true
L["Spawn Point"] = true
L["Text"] = true
L["Title"] = true
L["Very Low"] = true

L["TOPLEFT"] = "Top Left"
L["BOTTOMLEFT"] = "Bottom Left"
L["TOPRIGHT"] = "Top Right"
L["BOTTOMRIGHT"] = "Bottom Right"
