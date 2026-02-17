---@meta _
-- Generated API for game version 0.10.7

---@class ModPreset : RefCounted
---@field name string
---@field frozen boolean
---@field mods Array<ModManifest>
local ModPreset = {}

---@return ModPreset
function ModPreset.duplicate() end

---@return table<any,any>
function ModPreset.to_json() end

---@param data table<any,any>
---@return ModPreset
function ModPreset.from_json(data) end

---@return ModPreset
function ModPreset.with_minified_manifests() end

---@param other ModPreset
---@return boolean
function ModPreset.is_functionally_same(other) end

function ModPreset.update_with_discovered() end

---@param mod ModManifest
---@return integer
function ModPreset.find(mod) end

---@param mod ModManifest
---@return boolean
function ModPreset.add(mod) end

---@param mod ModManifest
---@return boolean
function ModPreset.remove(mod) end

---@param mod ModManifest
function ModPreset.lower_order_position(mod) end

---@param mod ModManifest
function ModPreset.raise_order_position(mod) end

function ModPreset.auto_sort() end

---@param addition ModManifest
---@return PackedStringArray
function ModPreset.get_mod_issues(addition) end
