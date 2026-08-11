--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------

local AddOnFolderName, private = ...

local LDBIcon = LibStub("LibDBIcon-1.0")

---@class Toaster: AceAddon, AceConsole-3.0
local Toaster = LibStub("AceAddon-3.0"):NewAddon(AddOnFolderName, "AceConsole-3.0")

-- This global handle needs to exist so LibToast-1.0 can use it for various settings.
_G.Toaster = Toaster

--------------------------------------------------------------------------------
---- Constants
--------------------------------------------------------------------------------

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
    b = 0.541,
}

--------------------------------------------------------------------------------
---- Variables
--------------------------------------------------------------------------------

local AddOnObjects = {}
private.AddOnObjects = AddOnObjects

---@type ToasterDatabase
local db

--------------------------------------------------------------------------------
---- Helpers
--------------------------------------------------------------------------------

---@param addonName string
local function RegisterAddOn(addonName)
    if addonName == AddOnFolderName or addonName == "LibToast-1.0" or AddOnObjects[addonName] then
        return false
    end

    db.global.addons[addonName].known = true
    AddOnObjects[addonName] = { name = addonName }

    Toaster:UpdateAddOnOptions()

    return true
end

--------------------------------------------------------------------------------
---- Public API
--------------------------------------------------------------------------------

---@return FramePoint
function Toaster:SpawnPoint()
    return db.global.display.anchor.point
end

---@return number
function Toaster:SpawnOffsetX()
    return db.global.display.anchor.x
end

---@return number
function Toaster:SpawnOffsetY()
    return db.global.display.anchor.y
end

---@param urgencyLevel LibToast-1.0.UrgencyLevel
---@return (number r, number g, number b)
function Toaster:TitleColors(urgencyLevel)
    if not urgencyLevel then
        urgencyLevel = "normal"
    end

    local colors = db.global.display.title[urgencyLevel] or DEFAULT_TITLE_COLORS

    return colors.r, colors.g, colors.b
end

---@param urgencyLevel LibToast-1.0.UrgencyLevel
---@return (number r, number g, number b)
function Toaster:TextColors(urgencyLevel)
    if not urgencyLevel then
        urgencyLevel = "normal"
    end

    local colors = db.global.display.text[urgencyLevel]

    return colors.r, colors.g, colors.b
end

function Toaster:Backdrop() end

---@param addonName string?
---@return number
function Toaster:Duration(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.duration or db.global.display.duration
end

---@param addonName string?
---@return boolean
function Toaster:FloatingIcon(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.floating_icon or db.global.display.floating_icon
end

---@param addonName string?
---@return number
function Toaster:IconSize(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.icon_size or db.global.display.icon_size
end

---@param addonName string?
---@return number
function Toaster:Opacity(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.opacity or db.global.display.opacity
end

---@param urgencyLevel LibToast-1.0.UrgencyLevel
---@return (number r, number g, number b)
function Toaster:BackgroundColors(urgencyLevel)
    if not urgencyLevel then
        urgencyLevel = "normal"
    end

    local colors = db.global.display.background[urgencyLevel]

    return colors.r, colors.g, colors.b
end

---@return boolean
function Toaster:HideToasts()
    return db.global.general.hide_toasts
end

---@param addonName string
---@return boolean
function Toaster:HideToastsFromSource(addonName)
    if not addonName or RegisterAddOn(addonName) then
        return false
    end

    return not db.global.addons[addonName].enabled
end

---@return boolean
function Toaster:MuteToasts()
    return db.global.general.mute_toasts
end

---@param addonName string
---@return boolean
function Toaster:MuteToastsFromSource(addonName)
    if not addonName or RegisterAddOn(addonName) then
        return false
    end

    return db.global.addons[addonName].mute
end

--------------------------------------------------------------------------------
---- Initialization/Enable/Disable
--------------------------------------------------------------------------------

local DEFAULT_OFFSET_X = {
    TOPRIGHT = -20,
    BOTTOMRIGHT = -20,
}

local DEFAULT_OFFSET_Y = {
    TOPRIGHT = -30,
    BOTTOMRIGHT = 30,
}

---@class DefaultPreferences: AceDB.Schema
local DATABASE_DEFAULTS = {
    global = {
        addons = {
            ["*"] = {
                enabled = true,
                mute = false,
                duration = 5,
                icon_size = 30,
                floating_icon = false,
                opacity = 0.75,

                -- This is required so the AddOn stays in the SavedVariables table, and is hence visible in further sessions.
                known = false,
            },
        },
        display = {
            anchor = {
                point = "TOPRIGHT",
                scale = 1,
                y = DEFAULT_OFFSET_Y["TOPRIGHT"],
                x = DEFAULT_OFFSET_X["TOPRIGHT"],
            },
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
            mute_toasts = false,
        },
    },
}

private.DATABASE_DEFAULTS = DATABASE_DEFAULTS

function Toaster:OnInitialize()
    db = LibStub("AceDB-3.0"):New(("%sSettings"):format(AddOnFolderName), DATABASE_DEFAULTS, "Default") --[[@as ToasterDatabase]]
    private.db = db

    local dataObject = LibStub("LibDataBroker-1.1"):NewDataObject(AddOnFolderName, {
        type = "launcher",
        label = AddOnFolderName,
        icon = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]],
        OnClick = function(display, button)
            Toaster:ToggleOptionsVisibility()
        end,
    })

    LDBIcon:Register(AddOnFolderName, dataObject, db.global.general.minimap_icon)

    for addonName, data in _G.pairs(db.global.addons) do
        -- Migration.
        if _G.type(data.show) == "boolean" then
            data.enabled = data.show
            data.show = nil
        end
        -- End migration.

        AddOnObjects[addonName] = { name = addonName }
    end

    self:SetupOptions()
    self:UpdateAddOnOptions()

    self:RegisterChatCommand("toaster", function()
        self:ToggleOptionsVisibility()
    end)
end

function Toaster:OnEnable() end

function Toaster:OnDisable() end

function Toaster:ToggleOptionsVisibility()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    if AceConfigDialog.OpenFrames[AddOnFolderName] then
        AceConfigDialog:Close(AddOnFolderName)
    else
        AceConfigDialog:Open(AddOnFolderName)
        AceConfigDialog:SelectGroup(AddOnFolderName, "defaultOptions")
    end
end
