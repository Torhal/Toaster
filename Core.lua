-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local LDBIcon = LibStub("LibDBIcon-1.0")
local LibToast = LibStub("LibToast-1.0",true)
if not LibToast then return end
local Toaster = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
_G.Toaster = Toaster

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------
local DEFAULT_BACKGROUND_COLORS = {
    r = 0,
    g = 0,
    b = 0,
}

local DEFAULT_TITLE_COLORS = {
    r = 0.510,
    g = 0.773,
    b = 1,
}

local DEFAULT_TEXT_COLORS = {
    r = 0.486,
    g = 0.518,
    b = 0.541
}

-----------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------
local db

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------
function Toaster:SpawnPoint()
    return db.global.general.spawn_point
end

function Toaster:TitleColors(urgency)
    if not urgency then
        urgency = "normal"
    end
    local colors = db.global.display.title[urgency] or DEFAULT_TITLE_COLORS
    return colors.r, colors.g, colors.b
end

function Toaster:TextColors(urgency)
    if not urgency then
        urgency = "normal"
    end
    local colors = db.global.display.text[urgency]
    return colors.r, colors.g, colors.b
end

function Toaster:Duration()
    return db.global.display.duration
end

function Toaster:FloatingIcon()
    return db.global.display.floating_icon
end

function Toaster:Opacity()
    return db.global.display.opacity
end

function Toaster:BackgroundColors(urgency)
    if not urgency then
        urgency = "normal"
    end
    local colors = db.global.display.background[urgency]
    return colors.r, colors.g, colors.b
end

function Toaster:HideToasts()
    return db.global.general.hide_toasts
end

-----------------------------------------------------------------------
-- Initialization/Enable/Disable
-----------------------------------------------------------------------
function Toaster:OnInitialize()
    local database_defaults = {
        global = {
            display = {
                background = {
                    ["*"] = DEFAULT_BACKGROUND_COLORS,
                },
                duration = 5,
                floating_icon = false,
                opacity = 0.75,
                text = {
                    ["*"] = DEFAULT_TEXT_COLORS,
                },
                title = {
                    ["*"] = DEFAULT_TITLE_COLORS,
                },
            },
            general = {
                hide_toasts = false,
                minimap_icon = {
                    hide = false,
                },
                spawn_point = "TOPRIGHT",
            },
        },
    }
    db = LibStub("AceDB-3.0"):New(("%sSettings"):format(ADDON_NAME), database_defaults, "Default")

    local LDB_launcher = LibStub("LibDataBroker-1.1", true):NewDataObject(ADDON_NAME, {
        type = "launcher",
        label = ADDON_NAME,
        icon = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]],
        OnClick = function(display, button)
            local options_frame = _G.InterfaceOptionsFrame

            if options_frame:IsVisible() then
                options_frame:Hide()
            else
                _G.InterfaceOptionsFrame_OpenToCategory(Toaster.options_frame)
            end
        end,
    })

    LDBIcon:Register(ADDON_NAME, LDB_launcher, db.global.general.minimap_icon)
    self:SetupOptions()
end

function Toaster:OnEnable()
end

function Toaster:OnDisable()
end

-------------------------------------------------------------------------------
-- Configuration.
-------------------------------------------------------------------------------
local SPAWN_POINTS = {
    "TOPLEFT",
    "BOTTOMLEFT",
    "TOPRIGHT",
    "BOTTOMRIGHT",
}

local LOCALIZED_SPAWN_POINTS = {
    L["TOPLEFT"],
    L["BOTTOMLEFT"],
    L["TOPRIGHT"],
    L["BOTTOMRIGHT"],
}
local SPAWN_INDICES = {}

for index = 1, #SPAWN_POINTS do
    SPAWN_INDICES[SPAWN_POINTS[index]] = index
end

local general_options

local function GeneralOptions()
    if not general_options then
        general_options = {
            order = 1,
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
                spawn_point = {
                    order = 30,
                    type = "select",
                    name = L["Spawn Point"],
                    get = function()
                        return SPAWN_INDICES[db.global.general.spawn_point]
                    end,
                    set = function(info, value)
                        db.global.general.spawn_point = SPAWN_POINTS[value]
                    end,
                    values = LOCALIZED_SPAWN_POINTS,
                }
            },
        }
    end
    return general_options
end

local display_options

local function _displayColorDefinition(order, category, reference)
    local name = category:lower():gsub("^%l", _G.string.upper):gsub("_", " "):gsub(" %l", _G.string.upper)

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

local function _displayColorPreview(order, reference)
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

local function DisplayOptions()
    if not display_options then
        display_options = {
            order = 2,
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
                    min = 0,
                    max = 10,
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
                header1 = {
                    order = 30,
                    type = "header",
                    name = L["Very Low"],
                },
                urgency_very_low_title = _displayColorDefinition(31, "title", "very_low"),
                urgency_very_low_text = _displayColorDefinition(32, "text", "very_low"),
                urgency_very_low_background = _displayColorDefinition(33, "background", "very_low"),
                urgency_very_low_preview = _displayColorPreview(34, "very_low"),
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
                urgency_moderate_title = _displayColorDefinition(40, "title", "moderate"),
                urgency_moderate_text = _displayColorDefinition(41, "text", "moderate"),
                urgency_moderate_background = _displayColorDefinition(42, "background", "moderate"),
                urgency_moderate_preview = _displayColorPreview(43, "moderate"),
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
                urgency_normal_title = _displayColorDefinition(50, "title", "normal"),
                urgency_normal_text = _displayColorDefinition(51, "text", "normal"),
                urgency_normal_background = _displayColorDefinition(52, "background", "normal"),
                urgency_normal_preview = _displayColorPreview(53, "normal"),
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
                urgency_high_title = _displayColorDefinition(60, "title", "high"),
                urgency_high_text = _displayColorDefinition(61, "text", "high"),
                urgency_high_background = _displayColorDefinition(62, "background", "high"),
                urgency_high_preview = _displayColorPreview(63, "high"),
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
                urgency_emergency_title = _displayColorDefinition(70, "title", "emergency"),
                urgency_emergency_text = _displayColorDefinition(71, "text", "emergency"),
                urgency_emergency_background = _displayColorDefinition(72, "background", "emergency"),
                urgency_emergency_preview = _displayColorPreview(73, "emergency"),
                empty_7 = {
                    order = 74,
                    type = "description",
                    width = "full",
                    name = "",
                },
            },
        }
    end
    return display_options
end

local options

local function Options()
    if not options then
        options = {
            name = ADDON_NAME,
            type = "group",
            childGroups = "tab",
            args = {}
        }
        options.args.general_options = GeneralOptions()
        options.args.display_options = DisplayOptions()
    end
    return options
end

function Toaster:SetupOptions()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, Options)
    self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)
end
