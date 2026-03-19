---@meta _
-- Generated API for game version 0.10.11

---@class SemVer : Object
---@field Version Object # Constant value: <GDScript#-9223369179560587935>
---@field VersionRange Object # Constant value: <GDScript#-9223369179543810718>
---@field VersionComparatorUnary Object # Constant value: <GDScript#-9223369179527033501>
---@field VersionComparatorRange Object # Constant value: <GDScript#-9223369179510256284>
---@field VersionComparatorBinary Object # Constant value: <GDScript#-9223369179493479067>
---@field SemVerParsing Object # Constant value: <GDScript#-9223369179476701850>
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
