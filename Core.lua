-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local AddOnFolderName, private = ...

local LDBIcon = LibStub("LibDBIcon-1.0")
local Toaster = LibStub("AceAddon-3.0"):NewAddon(AddOnFolderName, "AceConsole-3.0")

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
    b = 0.541,
}

-----------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------
local AddOnObjects = {}
private.AddOnObjects = AddOnObjects

local db

-----------------------------------------------------------------------
-- Helpers.
-----------------------------------------------------------------------
local function RegisterAddOn(addonName)
    if addonName == AddOnFolderName or addonName == "LibToast-1.0" or AddOnObjects[addonName] then
        return false
    end

    db.global.addons[addonName].known = true
    AddOnObjects[addonName] = { name = addonName }

    Toaster:UpdateAddOnOptions()

    return true
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------
function Toaster:SpawnPoint()
    return db.global.display.anchor.point
end

function Toaster:SpawnOffsetX()
    return db.global.display.anchor.x
end

function Toaster:SpawnOffsetY()
    return db.global.display.anchor.y
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

function Toaster:Backdrop() end

function Toaster:Duration(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.duration or db.global.display.duration
end

function Toaster:FloatingIcon(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.floating_icon or db.global.display.floating_icon
end

function Toaster:IconSize(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.icon_size or db.global.display.icon_size
end

function Toaster:Opacity(addonName)
    local addon = addonName and db.global.addons[addonName]
    return (addon and addon.known) and addon.opacity or db.global.display.opacity
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

function Toaster:HideToastsFromSource(addonName)
    if not addonName or RegisterAddOn(addonName) then
        return false
    end
    return not db.global.addons[addonName].enabled
end

function Toaster:MuteToasts()
    return db.global.general.mute_toasts
end

function Toaster:MuteToastsFromSource(addonName)
    if not addonName or RegisterAddOn(addonName) then
        return false
    end
    return db.global.addons[addonName].mute
end

-----------------------------------------------------------------------
-- Initialization/Enable/Disable
-----------------------------------------------------------------------
local DEFAULT_OFFSET_X = {
    TOPRIGHT = -20,
    BOTTOMRIGHT = -20,
}

local DEFAULT_OFFSET_Y = {
    TOPRIGHT = -30,
    BOTTOMRIGHT = 30,
}

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
        },
    },
}

private.DATABASE_DEFAULTS = DATABASE_DEFAULTS

function Toaster:OnInitialize()
    db = LibStub("AceDB-3.0"):New(("%sSettings"):format(AddOnFolderName), DATABASE_DEFAULTS, "Default")
    private.db = db

    LDBIcon:Register(
        AddOnFolderName,
        LibStub("LibDataBroker-1.1", true):NewDataObject(AddOnFolderName, {
            type = "launcher",
            label = AddOnFolderName,
            icon = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]],
            OnClick = function(display, button)
                Toaster:ToggleOptionsVisibility()
            end,
        }),
        db.global.general.minimap_icon
    )

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

    self:RegisterChatCommand("toaster", function(args)
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
