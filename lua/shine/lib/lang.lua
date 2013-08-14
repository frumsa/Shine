--[[
	Multi language handling.

	The plan:

	Plugins:
		Add lua files under lua/shine/extensions/pluginname/lang, each one being for a separate language.
		Names should be lower case, 4 letter language code, e.g engb.lua, enus.lua etc.
		Contents should be returning the table of strings, e.g

		return {
			HELLO_THERE = "Hello there!"
		}

	Core:
		Add lua files under lua/shine/lang, each one being for a separate language.
		Names and contents as for plugins.

	Language handling will be entirely client side and automatic. Clients will be sent either a straight translation ID
	from the server, or they'll be sent a special network message with data for them to build the translation if, for example,
	they need to include a time duration.

	TODO:
	- Certain languages will order key information in different ways maybe? So we need to be able to specify which part
	goes where.
	- Add the actual translation data for each plugin and core files in British and American English.
	- Remake every notification!
]]

local Shine = Shine

local LoadFile = loadfile
local StringFormat = string.format

Shine.Language = Shine.Language or {}

local Lang = Shine.Language
Lang.Strings = Lang.Strings or {}

--Default to British English (that's my locale :>)
local DefaultLang = "engb"

Lang.DefaultLanguage = DefaultLang

local CorePath = "lua/shine/lang/"

local Files = {}
Shared.GetMatchingFileNames( CorePath.."*.lua", false, Files )

local CoreFiles = {}
for i = 1, #Files do
	CoreFiles[ Files[ i ] ] = true
end

Lang.CoreFiles = CoreFiles

--[[
	Loads a translation file from the given plugin for the given language.

	Inputs: Plugin name, language code.
	Output: True if we have strings, false otherwise. 
]]
function Lang:LoadFromPlugin( Plugin, Lang )
	Lang = Lang:lower()

	local Path = Shine.ExtensionPath
	local Files = Shine.PluginFiles

	Path = StringFormat( "%s%s/lang/%s.lua", Path, Plugin, Lang )

	--No translation file present.
	if not Files[ Path ] then return false end

	--Translation files should return their table of strings.
	local Strings = LoadFile( Path )

	self.Strings[ Plugin ] = self.String[ Plugin ] or {}

	self.Strings[ Plugin ][ Lang ] = Strings()

	return true
end

--[[
	Returns the loaded strings for a plugin and language or nil.

	Inputs: Plugin name, language code.
	Output: Table of strings or nil.
]]
function Lang:GetPluginStrings( Plugin, Lang )
	if not self.Strings[ Plugin ] or not self.Strings[ Plugin ][ Lang ] then
		return self:LoadFromPlugin( Plugin, Lang ) and self.Strings[ Plugin ][ Lang ] or nil
	end

	return self.Strings[ Plugin ][ Lang ]
end

--[[
	Gets the default language string for the given plugin and translation ID.

	Inputs: Plugin name, string ID.
	Output: Default language translation or the input ID if we don't have a translation.
]]
function Lang:GetDefaultPluginString( Plugin, String )
	local Strings = self:GetPluginStrings( Plugin, DefaultLang )

	return Strings and Strings[ String ] or String
end

--[[
	Gets a translated string for the given plugin.

	Inputs: Plugin name, string translation ID.
	Output: Translated string if available, otherwise it returns the default language string.

	If there is no translation data at all, then the string ID is returned.
]]
function Lang:GetPluginString( Plugin, String )
	local Lang = Locale.GetLocale()

	local Strings = self:GetPluginStrings( Plugin, Lang )

	if not Strings then
		--Default language non-existant!
		if Lang == DefaultLang then
			return String
		end

		--Return the default language string for this if we have it.
		return self:GetDefaultPluginString( Plugin, String )
	end

	--Return the correct translation or the default language string.
	return Strings[ String ] or self:GetDefaultPluginString( Plugin, String )
end

--[[
	Loads a core language file.

	Input: Language name.
	Output: True if loaded, false if not.
]]
function Lang:Load( Lang )
	Lang = Lang:lower()

	local Path = StringFormat( "%s%s.lua", CorePath, Lang )

	if not CoreFiles[ Path ] then
		return false
	end

	local Strings = LoadFile( Path )

	self.Strings[ Lang ] = Strings()

	return true
end

--[[
	Gets the table of strings for the given language.

	Input: Language.
	Output: Table of strings or nil.
]]
function Lang:GetStrings( Lang )
	if not self.Strings[ Lang ] then
		return self:Load( Lang ) and self.Strings[ Lang ] or nil
	end

	return self.Strings[ Lang ]
end

--[[
	Gets the default language string for the given translation ID.

	Input: ID.
	Output: Default language translation or the input string.
]]
function Lang:GetDefaultString( String )
	local Strings = self:GetStrings( DefaultLang )

	return Strings and Strings[ String ] or String
end

--[[
	Gets a core language string.

	Input: String ID.
	Output: Translated string or the default translation, or the input string if neither exist.
]]
function Lang:GetString( String )
	local Lang = Locale.GetLocale():lower()

	local Strings = self:GetStrings( Lang )

	if not Strings then
		if Lang == DefaultLang then
			return String
		end
		
		return self:GetDefaultString( String )
	end

	return Strings[ String ] or self:GetDefaultString( String )
end
