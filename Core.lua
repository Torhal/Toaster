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
local Toaster = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")
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
local addon_names = {}
private.addon_names = addon_names

local db

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
local function PopulateAddOnNames()
    for addon_name, data in _G.pairs(db.global.addons) do
        addon_names[addon_name] = addon_name
    end
end

local function RegisterAddOn(source_addon)
    if source_addon == ADDON_NAME or db.global.addons[source_addon].known then
        return false
    end
    db.global.addons[source_addon].known = true

    PopulateAddOnNames()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)

    return true
end

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

function Toaster:Backdrop()

end

function Toaster:Duration()
    return db.global.display.duration
end

function Toaster:FloatingIcon()
    return db.global.display.floating_icon
end

function Toaster:IconSize()
    return db.global.display.icon_size
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

function Toaster:HideToastsFromSource(source_addon)
    if not source_addon or RegisterAddOn(source_addon) then
        return false
    end
    return not db.global.addons[source_addon].show
end

function Toaster:MuteToasts()
    return db.global.general.mute_toasts
end

function Toaster:MuteToastsFromSource(source_addon)
    if not source_addon or RegisterAddOn(source_addon) then
        return false
    end
    return db.global.addons[source_addon].mute
end

-----------------------------------------------------------------------
-- Initialization/Enable/Disable
-----------------------------------------------------------------------
function Toaster:OnInitialize()
    local database_defaults = {
        global = {
            addons = {
                ["*"] = {
                    show = true,
                    mute = false,
                    known = false,
                },
            },
            display = {
                background = {
                    ["*"] = DEFAULT_BACKGROUND_COLORS,
                },
                duration = 5,
                icon_size = 30,
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
                spawn_point = _G.IsMacClient() and "TOPRIGHT" or "BOTTOMRIGHT",
            },
        },
    }
    db = LibStub("AceDB-3.0"):New(("%sSettings"):format(ADDON_NAME), database_defaults, "Default")
    private.db = db

    LDBIcon:Register(ADDON_NAME, LibStub("LibDataBroker-1.1", true):NewDataObject(ADDON_NAME,
        {
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
        }), db.global.general.minimap_icon)

    PopulateAddOnNames()

    self:SetupOptions()
    self:RegisterChatCommand("toaster", function(args)
        local options_frame = _G.InterfaceOptionsFrame

        if options_frame:IsVisible() then
            options_frame:Hide()
        else
            _G.InterfaceOptionsFrame_OpenToCategory(self.options_frame)
        end
    end)
end

function Toaster:OnEnable()
end

function Toaster:OnDisable()
end

