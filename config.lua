local addonName, addon = ...
local L = addon.L
local ldbi = LibStub('LibDBIcon-1.0', true)

local function build()
  local t = {
    name = "GoldTracker",
    handler = GoldTracker,
    type = 'group',
    args = {
      showMinimapIcon = {
        type = 'toggle',
        name = L.showMinimapIcon,
        desc = L.showMinimapIconDescription,
        order = 0,
        get = function(info) return not addon.db.minimap.hide end,
        set = function(info, value)
          local config = addon.db.minimap
          config.hide = not value
          addon:setDB("minimap", config)
          ldbi:Refresh(addonName)
        end,
      },
      showAll = {
        type = 'toggle',
        order = 1,
        get = function(info) return addon.db[info[#info]] end,
        set = function(info, value) return addon:setDB(info[#info], value) end,
        name = L.showAll,
        desc = L.showAllDescription,
      },
      characters = {
        type = 'header',
        name = 'Saved Data',
        order = 20,
      },
    }
  }

  local order = 20
  for faction,realms in pairs(addon.db.gold) do
    for realm,characters in pairs(realms) do
      local header = ('%s (%s)'):format(realm, faction)
      order = order + 50 * 3
      t.args[header] = { type = 'header', name = header, order = order }
      for character, amt in pairs(characters) do
        local isDisabled = character == UnitName("player") and realm == GetRealmName()
        t.args[faction..realm..character.."_name"] = {
          type = "description",
          width = "half",
          name = character,
          order = order + 1,
          disabled = isDisabled,
        }
        t.args[faction..realm..character.."_delete"] = {
          type = "execute",
          width = "half",
          func = function(i, v) return addon:clearCharacter(faction, realm, character) end,
          name = L.deleteCharacter,
          desc = L.deleteCharacterDescription,
          order = order + 2,
          disabled = isDisabled,
        }
        t.args[faction..realm..character.."_break"] = {
          type = "description",
          width = "full",
          name = " ",
          order = order + 3,
        }
        order = order + 3
      end
    end
  end

  -- return our new table
  return t
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("GoldTracker", build, nil)
addon.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "GoldTracker")
