---@meta _
-- Generated API for game version 0.10.7

---@class ModManifest : RefCounted
---@field raw_data table<any,any>
---@field icon Image
---@field mod_path string
---@field id string
---@field name string
---@field authors PackedStringArray
---@field version SemVerVersion
---@field description PackedStringArray
---@field links table<string,string>
---@field dependencies table<string,RefCounted>
---@field dependencies_optional table<string,RefCounted>
---@field incompatibilities table<string,RefCounted>
local ModManifest = {}

---@param mod_id string
---@param jsonc string
---@return ModManifest
function ModManifest.from_jsonc_string(mod_id, jsonc) end

---@param other ModManifest
---@return boolean
function ModManifest.is_functionally_same(other) end

---@param mod_dir string
function ModManifest.try_load_icon(mod_dir) end

---@return ModManifest
function ModManifest.as_minified_manifest() end

---@param other ModManifest
---@return boolean
function ModManifest.is_dependency_satisfied(other) end

---@param other ModManifest
---@return boolean
function ModManifest.is_incompatible(other) end
