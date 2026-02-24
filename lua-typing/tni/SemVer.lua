---@meta _
-- Generated API for game version 0.10.7

---@class SemVer : Object
---@field Version Object # Constant value: <GDScript#-9223369184342094544>
---@field VersionRange Object # Constant value: <GDScript#-9223369184325317327>
---@field VersionComparatorUnary Object # Constant value: <GDScript#-9223369184308540110>
---@field VersionComparatorRange Object # Constant value: <GDScript#-9223369184291762893>
---@field VersionComparatorBinary Object # Constant value: <GDScript#-9223369184274985676>
---@field SemVerParsing Object # Constant value: <GDScript#-9223369184258208459>
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
