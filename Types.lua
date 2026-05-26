-------- Generic
---@alias ItemLink string

---@class BasicRGB
---@field r number
---@field g number
---@field b number

--------- Texture
---@class TextureData
---@field texture string
---@field size [number, number]
---@field coords [number, number, number, number]

--------- Database
---@class Character
---@field name string
---@field race string
---@field className string
---@field group EnumCharacterGroup
---@field cooldownGroup table<string, CurrentCooldown[]>
---@field professionsData ProfessionsCooldownList

---@class Option
---@field categoryID number

-------- Preset
---@class MailPresetItemType
---@field classID number
---@field subclassID? number

---@class MailPreset
---@field id? number
---@field name string
---@field to string
---@field color colorRGBA
---@field itemGroups table<string, boolean>
---@field custom ItemLink[]
---@field exclusion ItemLink[]
---@field itemType MailPresetItemType[]

---@class ItemGroupOption
---@field label string
---@field CheckItemBelongsToGroup fun(itemLink: ItemLink): boolean
---@field IsEnabledInThisExpansion? fun(): boolean

------- Options
---@class OptionsCreateList
---@field GetText? fun(rowData): string
---@field SortComparator fun(a: any, b: any): boolean
---@field CustomizeRow? fun(frame: table, helpers)
---@field showCheckbox? boolean
---@field OnCheckedChange? fun(rowFrame: table, rowData)
---@field showRemoveIcon? boolean
---@field OnRemove? fun(rowData, OptionsCreateList): boolean
---@field OnUpdate? fun(frame: table)
---@field hasHyperlink? boolean
---@field GetHyperlink? fun(rowData: any): string

------- AutoBuy
---@class AutoBuyItem
---@field itemLink ItemLink
---@field quantity number
---@field scope EAutoBuyScope
---@field scopeValue? string

------- MouseRing
---@class MouseRingData
---@field enabled boolean
---@field size number
---@field shape string
---@field colorR number
---@field colorG number
---@field colorB number
---@field useClassColor boolean
---@field hideBackground boolean
---@field showOutOfCombat boolean
---@field hideOnRightClick boolean
-- Cast swipe
---@field castSwipeEnabled boolean
---@field castSwipeR? number
---@field castSwipeG? number
---@field castSwipeB? number
---@field castSwipeUseClassColor boolean
-- GCD swipe
---@field gcdEnabled boolean
---@field gcdR? number
---@field gcdG? number
---@field gcdB? number
---@field gcdUseClassColor boolean
-- Trail
---@field trailEnabled boolean
---@field trailR? number
---@field trailG? number
---@field trailB? number
---@field trailUseClassColor boolean
---@field trailDuration number

--- Cooldowns
---@class CooldownConfig
---@field internalID number
---@field enabled boolean
---@field showNotification boolean

---@class BasicCooldown
---@field internalID number
---@field name string
---@field spellID? number
---@field itemID? number

---@class GroupedCooldown : BasicCooldown
---@field spellList? BasicCooldown[]

---@class Profession
---@field id number
---@field name string
---@field spellIDs number[]
---@field cooldowns (BasicCooldown|GroupedCooldown)[]

---@class ProfessionCooldownData
---@field name string
---@field internalID number
---@field source "SPELL_API"|"TRADE_SKILL_FRAME"
---@field endTime number
---@field invalid? boolean
---@field startTimeSpellAPI? number

---@alias ProfessionsCooldownList table<number, table<number, ProfessionCooldownData>>
