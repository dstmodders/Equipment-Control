local InventoryFunctions = require "util/inventoryfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

-- 
-- Logic
-- 

local AutoEquipFns = {}

local function AddAutoEquip(config, trigger, fn)
    if GetModConfigData(config, MOD_EQUIPMENT_CONTROL.MODNAME) then
        AutoEquipFns[#AutoEquipFns + 1] =
        {
            trigger = trigger,
            fn = fn
        }
    end
end

-- 
-- Helpers
-- 

local function GlasscutterTrigger(target)
    return target:HasTag("shadow")
        or target:HasTag("shadowminion")
        or target:HasTag("shadowchesspiece")
        or target:HasTag("stalker")
        or target:HasTag("stalkerminion")
end

local AUTO_EQUIP_WEAPON = GetModConfigData("AUTO_EQUIP_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME)

local function WeaponTrigger(target)
    return AUTO_EQUIP_WEAPON
       and not target:HasTag("butterfly")
end

local function GetPrefabFromInventory(prefab)
    for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if invItem.prefab == prefab then
            return invItem
        end
    end

    return nil
end

local function Equip(item)
    if not item or InventoryFunctions:IsEquipped(item.prefab) then
        return
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)
end

local function EquipWeapon()
    if not ThePlayer or not ThePlayer.components.actioncontroller then
        return
    end

    local category = ThePlayer.components.actioncontroller:GetAutoEquipCategory()
    local weapon = ThePlayer.components.actioncontroller:GetItemFromCategory(category)

    Equip(weapon)
end

local function EquipGlasscutter()
    local weapon = GetPrefabFromInventory("glasscutter")

    if not weapon then
        EquipWeapon()
        return
    end

    Equip(weapon)
end

-- 
-- Auto equips
-- 

AddAutoEquip("AUTO_EQUIP_GLASSCUTTER", GlasscutterTrigger, EquipGlasscutter)
AddAutoEquip("AUTO_EQUIP_WEAPON", WeaponTrigger, EquipWeapon)

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local OldDoAttackButton = PlayerController.DoAttackButton
    function PlayerController:DoAttackButton(retarget)
        local force_attack = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK)
        local target = self:GetAttackTarget(force_attack, retarget, retarget ~= nil)

        if target then
            for i = 1, #AutoEquipFns do
                if AutoEquipFns[i].trigger(target) then
                    AutoEquipFns[i].fn(target)
                    break
                end
            end
        end

        OldDoAttackButton(self, retarget)
    end
end

KeybindService:AddKey("TOGGLE_AUTO_EQUIP", function()
    AUTO_EQUIP_WEAPON = DoToggle("Auto-equip weapon", AUTO_EQUIP_WEAPON)
end)

return Init
