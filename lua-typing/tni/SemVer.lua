---@meta _
-- Generated API for game version 0.10.7

---@class SemVer : Object
---@field Version Object # Constant value: <GDScript#-9223369184560198357>
---@field VersionRange Object # Constant value: <GDScript#-9223369184543421140>
---@field VersionComparatorUnary Object # Constant value: <GDScript#-9223369184526643923>
---@field VersionComparatorRange Object # Constant value: <GDScript#-9223369184509866706>
---@field VersionComparatorBinary Object # Constant value: <GDScript#-9223369184493089489>
---@field SemVerParsing Object # Constant value: <GDScript#-9223369184476312272>
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
