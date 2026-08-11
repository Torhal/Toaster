---@meta _

--------------------------------------------------------------------------------
---- Types
--------------------------------------------------------------------------------

---@class ToasterDatabase.Global.AddOns.Wildcard
---@field enabled boolean
---@field mute boolean
---@field duration number
---@field icon_size number
---@field floating_icon boolean
---@field opacity number
---@field known boolean

---@class ToasterDatabase.Global.AddOns
---@field * ToasterDatabase.Global.AddOns.Wildcard

---@class ToasterDatabase.Global.Display.Anchor
---@field point FramePoint
---@field scale number
---@field x { BOTTONRIGHT: number, TOPRIGHT: number}
---@field y { BOTTONRIGHT: number, TOPRIGHT: number}

---@class ToasterDatabase.Global.Display.Background
---@field * { r: number, g: number, b: number, }

---@class ToasterDatabase.Global.Display.Text
---@field * { r: number, g: number, b: number, }

---@class ToasterDatabase.Global.Display.Title
---@field * { r: number, g: number, b: number, }

---@class ToasterDatabase.Global.Display
---@field anchor ToasterDatabase.Global.Display.Anchor
---@field background ToasterDatabase.Global.Display.Background
---@field duration number
---@field icon_size number
---@field floating_icon boolean
---@field opacity number
---@field text ToasterDatabase.Global.Display.Text
---@field title ToasterDatabase.Global.Display.Title

---@class ToasterDatabase.Global.General
---@field hide_toasts boolean
---@field minimap_icon { hide: boolean }
---@field mute_toasts boolean

---@class ToasterDatabase.Global
---@field addons ToasterDatabase.Global.AddOns
---@field display ToasterDatabase.Global.Display
---@field general ToasterDatabase.Global.General

---@class ToasterDatabase: AceDBObject-3.0
---@field global ToasterDatabase.Global
