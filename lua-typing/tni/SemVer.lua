---@meta _
-- Generated API for game version 0.10.7

---@class SemVer : Object
---@field Version Object # Constant value: <GDScript#-9223369184241431247>
---@field VersionRange Object # Constant value: <GDScript#-9223369184224654030>
---@field VersionComparatorUnary Object # Constant value: <GDScript#-9223369184207876813>
---@field VersionComparatorRange Object # Constant value: <GDScript#-9223369184191099596>
---@field VersionComparatorBinary Object # Constant value: <GDScript#-9223369184174322379>
---@field SemVerParsing Object # Constant value: <GDScript#-9223369184157545162>
local SemVer = {}
---@enum SemVer.VersionComparatorUnaryOp
SemVer.VersionComparatorUnaryOp = {
	["EQ"] = 0,
	["LT"] = 1,
	["LE"] = 2,
	["GT"] = 3,
	["GE"] = 4,
	["TILDE"] = 5,
	["CARET"] = 6,
}
---@enum SemVer.VersionComparatorBinaryOp
SemVer.VersionComparatorBinaryOp = {
	["AND"] = 0,
	["OR"] = 1,
}
