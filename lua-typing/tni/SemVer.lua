---@meta _
-- Generated API for game version 0.10.11

---@class SemVer : Object
---@field Version Object # Constant value: <GDScript#-9223369182916031174>
---@field VersionRange Object # Constant value: <GDScript#-9223369182899253957>
---@field VersionComparatorUnary Object # Constant value: <GDScript#-9223369182882476740>
---@field VersionComparatorRange Object # Constant value: <GDScript#-9223369182865699523>
---@field VersionComparatorBinary Object # Constant value: <GDScript#-9223369182848922306>
---@field SemVerParsing Object # Constant value: <GDScript#-9223369182832145089>
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
