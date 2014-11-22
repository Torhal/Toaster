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
local LibToast = LibStub("LibToast-1.0", true)
local Toaster = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local db
local addon_names = private.addon_names

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

local addon_options

local function AddOnOptions()
	if addon_options then
		return addon_options
	end
	addon_options = {
		order = 1,
		name = _G.MESSAGE_SOURCES,
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
			empty_3 = {
				order = 31,
				type = "description",
				width = "full",
				name = " ",
			},
			spawn_point = {
				order = 40,
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
			icon_size = {
				order = 14,
				name = L["Icon Size"],
				type = "range",
				width = "full",
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
			empty_3 = {
				order = 15,
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
				addon_options = AddOnOptions(),
				color_options = ColorOptions(),
				display_options = DisplayOptions(),
				general_options = GeneralOptions(),
			}
		}
	end
	return options
end

function Toaster:SetupOptions()
	db  = private.db

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, Options)
	self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)
end
