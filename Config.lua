-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

local math = _G.math

local tonumber = _G.tonumber
local tostring = _G.tostring

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LibToast = LibStub("LibToast-1.0", true)
local LibWindow = LibStub("LibWindow-1.1")
local Toaster = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local db
local addon_names = private.addon_names

-------------------------------------------------------------------------------
-- Constants.
-------------------------------------------------------------------------------
local SPAWN_POINTS = {
    "CENTER",
    "BOTTOM",
    "BOTTOMLEFT",
    "BOTTOMRIGHT",
    "LEFT",
    "RIGHT",
    "TOP",
    "TOPLEFT",
    "TOPRIGHT",
}

local SPAWN_INDICES = {}
local LOCALIZED_SPAWN_POINTS = {}

for index = 1, #SPAWN_POINTS do
    LOCALIZED_SPAWN_POINTS[index] = L[SPAWN_POINTS[index]]
    SPAWN_INDICES[SPAWN_POINTS[index]] = index
end

-------------------------------------------------------------------------------
-- Variables.
-------------------------------------------------------------------------------
local anchorFrame

-------------------------------------------------------------------------------
-- Helpers.
-------------------------------------------------------------------------------
local function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function CreateAnchorFrame()
    local anchorFrame = _G.CreateFrame("Frame", nil, _G.UIParent)
    anchorFrame:SetSize(250, 50)
    anchorFrame:SetFrameStrata("DIALOG")
    anchorFrame:SetBackdrop({
        bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
        edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5,
        },
    })

    local r, g, b = Toaster:BackgroundColors("normal")
    anchorFrame:SetBackdropColor(r, g, b, Toaster:Opacity())

    anchorFrame:EnableMouse(true)
    anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame:SetClampedToScreen(true)
    anchorFrame:SetPoint("TOPRIGHT", _G.UIParent, "TOPRIGHT", -20, -30)
    anchorFrame:Hide()

    local icon_size = Toaster:IconSize()

    local icon = anchorFrame:CreateTexture(nil, "BORDER")
    icon:SetSize(icon_size, icon_size)
    icon:SetTexture([[Interface\COMMON\help-i]])
    icon:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 10, -10)

    local title = anchorFrame:CreateFontString(nil, "BORDER", "FriendsFont_Normal")
    title:SetJustifyH("LEFT")
    title:SetJustifyV("MIDDLE")
    title:SetWordWrap(true)
    title:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", icon:GetWidth() + 15, -10)
    title:SetPoint("RIGHT", anchorFrame, "RIGHT", -20, 10)
    title:SetText(ADDON_NAME)
    title:SetTextColor(Toaster:TitleColors("normal"))
    title:SetWidth(anchorFrame:GetWidth() - icon:GetWidth() - 20)

    local text = anchorFrame:CreateFontString(nil, "BORDER", "FriendsFont_Normal")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(true)
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    text:SetText(L["Drag to set the spawn point for toasts."])
    text:SetTextColor(Toaster:TextColors("normal"))
    text:SetWidth(anchorFrame:GetWidth() - icon:GetWidth() - 20)

    local dismiss_button = _G.CreateFrame("Button", nil, anchorFrame)
    dismiss_button:SetSize(18, 18)
    dismiss_button:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -4, -4)
    dismiss_button:SetFrameStrata("DIALOG")
    dismiss_button:SetFrameLevel(anchorFrame:GetFrameLevel() + 2)
    dismiss_button:SetNormalTexture([[Interface\FriendsFrame\UI-Toast-CloseButton-Up]])
    dismiss_button:SetPushedTexture([[Interface\FriendsFrame\UI-Toast-CloseButton-Down]])
    dismiss_button:SetHighlightTexture([[Interface\FriendsFrame\UI-Toast-CloseButton-Highlight]])
    dismiss_button:SetScript("OnClick", function()
        anchorFrame:Hide()
    end)

    anchorFrame:SetHeight(text:GetStringHeight() + title:GetStringHeight() + 25)
    return anchorFrame
end

local addon_options

local function AddOnOptions()
    if addon_options then
        return addon_options
    end
    addon_options = {
        order = 1,
        name = _G.ADDONS,
        type = "group",
        childGroups = "tab",
        args = {
            show = {
                name = _G.SHOW,
                order = 1,
                type = "group",
                args = {
                    entries = {
                        name = _G.ADDONS,
                        type = "multiselect",
                        values = addon_names,
                        get = function(info, addon_name)
                            return db.global.addons[addon_name].show
                        end,
                        set = function(info, addon_name, value)
                            db.global.addons[addon_name].show = value
                        end,
                    },
                },
            },
            mute = {
                name = _G.MUTE,
                order = 2,
                type = "group",
                args = {
                    entries = {
                        name = _G.ADDONS,
                        type = "multiselect",
                        values = addon_names,
                        get = function(info, addon_name)
                            return db.global.addons[addon_name].mute
                        end,
                        set = function(info, addon_name, value)
                            db.global.addons[addon_name].mute = value
                        end,
                    },
                },
            },
        },
    }
    return addon_options
end

local general_options

local function GeneralOptions()
    if general_options then
        return general_options
    end
    general_options = {
        order = 3,
        name = _G.GENERAL,
        type = "group",
        args = {
            minimap_icon = {
                order = 10,
                type = "toggle",
                name = L["Show Minimap Icon"],
                get = function(info)
                    return not db.global.general.minimap_icon.hide
                end,
                set = function(info, value)
                    db.global.general.minimap_icon.hide = not value
                    LDBIcon[value and "Show" or "Hide"](LDBIcon, ADDON_NAME)
                end,
            },
            empty_2 = {
                order = 11,
                type = "description",
                width = "full",
                name = "",
            },
            hide_toasts = {
                order = 20,
                type = "toggle",
                name = L["Hide Toasts"],
                get = function(info)
                    return db.global.general.hide_toasts
                end,
                set = function(info, value)
                    db.global.general.hide_toasts = value
                end,
            },
            empty_3 = {
                order = 21,
                type = "description",
                width = "full",
                name = " ",
            },
            mute_toasts = {
                order = 30,
                type = "toggle",
                name = L["Mute Toasts"],
                get = function(info)
                    return db.global.general.mute_toasts
                end,
                set = function(info, value)
                    db.global.general.mute_toasts = value
                end,
            },
        },
    }
    return general_options
end


local function ColorDefinition(order, category, reference)
    local name = L[category:lower():gsub("^%l", _G.string.upper):gsub("_", " "):gsub(" %l", _G.string.upper)]

    return {
        order = order,
        type = "color",
        name = name,
        desc = _G.COLOR,
        get = function()
            local col = db.global.display[category][reference]
            return col.r, col.g, col.b
        end,
        set = function(info, r, g, b)
            local col = db.global.display[category][reference]
            col.r = r
            col.g = g
            col.b = b
        end,
    }
end

local preview_registered = false

local function ColorPreview(order, reference)
    return {
        order = order,
        type = "execute",
        name = L["Preview"],
        width = "half",
        func = function()
            if not preview_registered then
                LibToast:Register("ToasterPreview", function(toast, ...)
                    toast:SetTitle("Preview")
                    toast:SetFormattedText("This is a %s preview toast.", (...):gsub("_", " "))
                    toast:SetIconTexture([[Interface\FriendsFrame\Battlenet-WoWicon]])
                    toast:SetUrgencyLevel(...)
                end)
                preview_registered = true
            end
            LibToast:Spawn("ToasterPreview", reference)
        end,
    }
end

local color_options

local function ColorOptions()
    if color_options then
        return color_options
    end

    color_options = {
        order = 2,
        name = _G.COLOR,
        type = "group",
        args = {
            empty_1 = {
                order = 21,
                type = "description",
                width = "full",
                name = "",
            },
            header1 = {
                order = 30,
                type = "header",
                name = L["Very Low"],
            },
            urgency_very_low_title = ColorDefinition(31, "title", "very_low"),
            urgency_very_low_text = ColorDefinition(32, "text", "very_low"),
            urgency_very_low_background = ColorDefinition(33, "background", "very_low"),
            urgency_very_low_preview = ColorPreview(34, "very_low"),
            empty_3 = {
                order = 35,
                type = "description",
                width = "full",
                name = "",
            },
            header2 = {
                order = 36,
                type = "header",
                name = L["Moderate"],
            },
            urgency_moderate_title = ColorDefinition(40, "title", "moderate"),
            urgency_moderate_text = ColorDefinition(41, "text", "moderate"),
            urgency_moderate_background = ColorDefinition(42, "background", "moderate"),
            urgency_moderate_preview = ColorPreview(43, "moderate"),
            empty_4 = {
                order = 44,
                type = "description",
                width = "full",
                name = "",
            },
            header3 = {
                order = 45,
                type = "header",
                name = L["Normal"],
            },
            urgency_normal_title = ColorDefinition(50, "title", "normal"),
            urgency_normal_text = ColorDefinition(51, "text", "normal"),
            urgency_normal_background = ColorDefinition(52, "background", "normal"),
            urgency_normal_preview = ColorPreview(53, "normal"),
            empty_5 = {
                order = 54,
                type = "description",
                width = "full",
                name = "",
            },
            header4 = {
                order = 55,
                type = "header",
                name = L["High"],
            },
            urgency_high_title = ColorDefinition(60, "title", "high"),
            urgency_high_text = ColorDefinition(61, "text", "high"),
            urgency_high_background = ColorDefinition(62, "background", "high"),
            urgency_high_preview = ColorPreview(63, "high"),
            empty_6 = {
                order = 64,
                type = "description",
                width = "full",
                name = "",
            },
            header5 = {
                order = 65,
                type = "header",
                name = L["Emergency"],
            },
            urgency_emergency_title = ColorDefinition(70, "title", "emergency"),
            urgency_emergency_text = ColorDefinition(71, "text", "emergency"),
            urgency_emergency_background = ColorDefinition(72, "background", "emergency"),
            urgency_emergency_preview = ColorPreview(73, "emergency"),
            empty_7 = {
                order = 74,
                type = "description",
                width = "full",
                name = "",
            },
        },
    }

    return color_options
end

local display_options

local function DisplayOptions()
    if display_options then
        return display_options
    end

    display_options = {
        order = 3,
        name = _G.DISPLAY,
        type = "group",
        args = {
            opacity = {
                order = 10,
                name = _G.OPACITY,
                type = "range",
                width = "full",
                min = 0,
                max = 1,
                step = 0.05,
                isPercent = true,
                get = function()
                    return db.global.display.opacity
                end,
                set = function(info, value)
                    db.global.display.opacity = value
                end,
            },
            empty_1 = {
                order = 11,
                type = "description",
                width = "full",
                name = "",
            },
            duration = {
                order = 12,
                name = _G.TOAST_DURATION_TEXT,
                type = "range",
                width = "full",
                min = 5,
                max = 30,
                step = 0.25,
                get = function()
                    return db.global.display.duration
                end,
                set = function(info, value)
                    db.global.display.duration = value
                end,
            },
            empty_2 = {
                order = 13,
                type = "description",
                width = "full",
                name = "",
            },
            icon_size = {
                order = 14,
                name = L["Icon Size"],
                type = "range",
                min = 10,
                max = 30,
                step = 1,
                get = function()
                    return db.global.display.icon_size
                end,
                set = function(info, value)
                    db.global.display.icon_size = value
                end,
            },
            floating_icon = {
                order = 20,
                name = L["Floating Icon"],
                type = "toggle",
                get = function()
                    return db.global.display.floating_icon
                end,
                set = function(info, value)
                    db.global.display.floating_icon = value
                end,
            },
            empty_3 = {
                order = 21,
                type = "description",
                width = "full",
                name = " ",
            },
            spawn_point = {
                order = 30,
                type = "select",
                name = L["Spawn Point"],
                get = function()
                    return SPAWN_INDICES[db.global.display.anchor.point]
                end,
                set = function(info, value)
                    db.global.display.anchor.point = SPAWN_POINTS[value]
                    LibWindow.RestorePosition(anchorFrame)
                end,
                values = LOCALIZED_SPAWN_POINTS,
            },
            x = {
                order = 40,
                type = "input",
                name = L["X Offset"],
                desc = L["Horizontal offset from the anchor point."],
                get = function()
                    return tostring(round(db.global.display.anchor.x))
                end,
                set = function(info, value)
                    db.global.display.anchor.x = tonumber(value)
                    LibWindow.RestorePosition(anchorFrame)
                end,
                dialogControl = "NumberEditBox",
            },
            y = {
                order = 50,
                type = "input",
                name = L["Y Offset"],
                desc = L["Vertical offset from the anchor point."],
                get = function()
                    return tostring(round(db.global.display.anchor.y))
                end,
                set = function(info, value)
                    db.global.display.anchor.y = tonumber(value)
                    LibWindow.RestorePosition(anchorFrame)
                end,
                dialogControl = "NumberEditBox",
            },
            empty_4 = {
                order = 51,
                type = "description",
                width = "full",
                name = " ",
            },
            reset = {
                order = 60,
                type = "execute",
                name = L["Reset Position"],
                func = function()
                    db.global.display.anchor = _G.copyTable(private.DATABASE_DEFAULTS.global.display.anchor)
                    LibWindow.RestorePosition(anchorFrame)
                end,
            },
            show_anchor = {
                order = 70,
                type = "execute",
                name = L["Show Anchor"],
                func = function()
                    anchorFrame:Show()
                end,
            },
        },
    }
    return display_options
end

local options

local function Options()
    if not options then
        options = {
            name = ADDON_NAME,
            type = "group",
            childGroups = "tab",
            args = {
                display_options = DisplayOptions(),
                general_options = GeneralOptions(),
            }
        }
    end
    return options
end


local function SetupSuboptions(label, optionsTable)
    local optionsName = ADDON_NAME .. ":" .. label
    AceConfigRegistry:RegisterOptionsTable(optionsName, optionsTable)
    return AceConfigDialog:AddToBlizOptions(optionsName, optionsTable.name or label, ADDON_NAME)
end

function Toaster:SetupOptions()
    db = private.db
    anchorFrame = CreateAnchorFrame()

    LibWindow.RegisterConfig(anchorFrame, db.global.display.anchor)
    LibWindow.RestorePosition(anchorFrame)
    LibWindow.MakeDraggable(anchorFrame)

    anchorFrame:HookScript("OnDragStop", function()
        AceConfigRegistry:NotifyChange(ADDON_NAME)
    end)

    AceConfigRegistry:RegisterOptionsTable(ADDON_NAME, Options)
    self.OptionsFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME)
    self.AddOnsOptions = SetupSuboptions("AddOns", AddOnOptions())
    self.ColorOptions = SetupSuboptions("Color", ColorOptions())
end
