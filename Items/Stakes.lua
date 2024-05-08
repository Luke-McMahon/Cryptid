local pink = SMODS.Stake({
	name = "Pink Stake",
	key = "pink",
	pos = {x = 0, y = 0},
    atlas = "stake",
    applied_stakes = {"gold"},
	loc_txt = {
        name = "Pink Stake",
        text = {
        "Required score scales",
        "faster for each {C:attention}Ante"
        }
    },
    modifiers = function()
        G.GAME.modifiers.scaling = math.max(G.GAME.modifiers.scaling or 0, 4)
    end,
    color = HEX("ff5ee6")
})
local gba = get_blind_amount
function get_blind_amount(ante)
    local k = 0.7
    if G.GAME.modifiers.scaling == 4 then
        local amounts = {
            300,  1200, 4000,  11000,  30000,  100000,  180000,  300000
        }
        if ante < 1 then return 100 end
        if ante <= 8 then return amounts[ante] end
        local a, b, c, d = amounts[8],1.6,ante-8, 1 + 0.2*(ante-8)
        local amount = math.floor(a*(b+(k*c)^d)^c)
        amount = amount - amount%(10^math.floor(math.log10(amount)-1))
        return amount
    else return gba(ante)
    end
end
local brown = SMODS.Stake({
	name = "Brown Stake",
	key = "brown",
	pos = {x = 1, y = 0},
    atlas = "stake",
    applied_stakes = {"cry_pink"},
    modifiers = function()
        G.GAME.modifiers.eternal_perishable_compat = true
    end,
	loc_txt = {
        name = "Brown Stake",
        text = {
        "All {C:attention}stickers{} are compatible",
        "with each other"
        }
    },
    color = HEX("883200")
})
local yellow = SMODS.Stake({
	name = "Yellow Stake",
	key = "yellow",
	pos = {x = 2, y = 0},
    atlas = "stake",
    applied_stakes = {"cry_brown"},
    modifiers = function()
        G.GAME.modifiers.any_stickers = true
    end,
	loc_txt = {
        name = "Yellow Stake",
        text = {
        "{C:attention}Stickers{} can appear on",
        "all purchasable items",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    color = HEX("f7ff1f")
})
-- We're modifying so much of this for Brown and Yellow Stake that it's fine to override...
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    local area = area or G.jokers
    local center = G.P_CENTERS.b_red
        

    --should pool be skipped with a forced key
    if not forced_key and soulable and (not G.GAME.banned_keys['c_soul']) then
        if (_type == 'Tarot' or _type == 'Spectral' or _type == 'Tarot_Planet') and
        not (G.GAME.used_jokers['c_soul'] and not next(find_joker("Showman")))  then
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_soul'
            end
        end
        if (_type == 'Planet' or _type == 'Spectral') and
        not (G.GAME.used_jokers['c_black_hole'] and not next(find_joker("Showman")))  then 
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_black_hole'
            end
        end
    end

    if _type == 'Base' then 
        forced_key = 'c_base'
    end



    if forced_key and not G.GAME.banned_keys[forced_key] then 
        center = G.P_CENTERS[forced_key]
        _type = (center.set ~= 'Default' and center.set or _type)
    else
        local _pool, _pool_key = get_current_pool(_type, _rarity, legendary, key_append)
        center = pseudorandom_element(_pool, pseudoseed(_pool_key))
        local it = 1
        while center == 'UNAVAILABLE' do
            it = it + 1
            center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
        end

        center = G.P_CENTERS[center]
    end

    local front = ((_type=='Base' or _type == 'Enhanced') and pseudorandom_element(G.P_CARDS, pseudoseed('front'..(key_append or '')..G.GAME.round_resets.ante))) or nil

    local card = Card(area.T.x + area.T.w/2, area.T.y, G.CARD_W, G.CARD_H, front, center,
    {bypass_discovery_center = area==G.shop_jokers or area == G.pack_cards or area == G.shop_vouchers or (G.shop_demo and area==G.shop_demo) or area==G.jokers or area==G.consumeables,
     bypass_discovery_ui = area==G.shop_jokers or area == G.pack_cards or area==G.shop_vouchers or (G.shop_demo and area==G.shop_demo),
     discover = area==G.jokers or area==G.consumeables, 
     bypass_back = G.GAME.selected_back.pos})
    if card.ability.consumeable and not skip_materialize then card:start_materialize() end

    if _type == 'Joker' or G.GAME.modifiers.any_stickers then
        if G.GAME.modifiers.all_eternal then
            card:set_eternal(true)
        end
        if (area == G.shop_jokers) or (area == G.pack_cards) then 
            local eternal_perishable_poll = pseudorandom('cry_et'..(key_append or '')..G.GAME.round_resets.ante)
            if G.GAME.modifiers.enable_eternals_in_shop and eternal_perishable_poll > 0.7 then
                card:set_eternal(true)
            end
            if G.GAME.modifiers.enable_perishables_in_shop then
                if not G.GAME.modifiers.eternal_perishable_compat and ((eternal_perishable_poll > 0.4) and (eternal_perishable_poll <= 0.7)) then
                    card:set_perishable(true)
                end
                if G.GAME.modifiers.eternal_perishable_compat and pseudorandom('cry_per'..(key_append or '')..G.GAME.round_resets.ante) > 0.7 then
                    card:set_perishable(true)
                end
            end
            if G.GAME.modifiers.enable_rentals_in_shop and pseudorandom((area == G.pack_cards and 'packssjr' or 'ssjr')..G.GAME.round_resets.ante) > 0.7 then
                card:set_rental(true)
            end
        end
        if _type == 'Joker' then
            local edition = poll_edition('edi'..(key_append or '')..G.GAME.round_resets.ante)
            card:set_edition(edition)
            check_for_unlock({type = 'have_edition'})
        end
    end
    return card
end
function Card:set_perishable(_perishable) 
    self.ability.perishable = nil
    if (self.config.center.perishable_compat or G.GAME.modifiers.any_stickers) and (not self.ability.eternal or G.GAME.modifiers.eternal_perishable_compat) then 
        self.ability.perishable = true
        self.ability.perish_tally = G.GAME.perishable_rounds
    end
end
function Card:set_eternal(_eternal)
    self.ability.eternal = nil
    if (self.config.center.eternal_compat or G.GAME.modifiers.any_stickers) and (not self.ability.perishable or G.GAME.modifiers.eternal_perishable_compat) then
        self.ability.eternal = _eternal
    end
end
local silver = SMODS.Stake({
	name = "Silver Stake",
	key = "silver",
	pos = {x = 3, y = 0},
    atlas = "stake",
    applied_stakes = {"cry_yellow"},
	loc_txt = {
        name = "Silver Stake",
        text = {
        "Cards can be drawn {C:attention}face down{}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("bbbbbb")
})
local cyan = SMODS.Stake({
	name = "Cyan Stake",
	key = "cyan",
	pos = {x = 4, y = 0},
    atlas = "stake",
    applied_stakes = {"cry_silver"},
	loc_txt = {
        name = "Cyan Stake",
        text = {
        "{C:green}Uncommon{} and {C:red}Rare{} Jokers are",
        "less likely to appear",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    color = HEX("39ffcc")
})
local gray = SMODS.Stake({
	name = "Gray Stake",
	key = "gray",
	pos = {x = 0, y = 1},
    atlas = "stake",
    applied_stakes = {"cry_cyan"},
	loc_txt = {
        name = "Gray Stake",
        text = {
        "Rerolls increase by {C:attention}$2{} each",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    color = HEX("999999")
})
local crimson = SMODS.Stake({
	name = "Crimson Stake",
	key = "crimson",
	pos = {x = 1, y = 1},
    atlas = "stake",
    applied_stakes = {"cry_gray"},
	loc_txt = {
        name = "Crimson Stake",
        text = {
        "Vouchers restock every {C:attention}2{} Antes",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    color = HEX("800000")
})
local diamond = SMODS.Stake({
	name = "Diamond Stake",
	key = "diamond",
	pos = {x = 2, y = 1},
    atlas = "stake",
    applied_stakes = {"cry_crimson"},
	loc_txt = {
        name = "Diamond Stake",
        text = {
        "Must beat Ante {C:attention}10{} to win",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("88e5d9")
})
local amber = SMODS.Stake({
	name = "Amber Stake",
	key = "amber",
	pos = {x = 3, y = 1},
    atlas = "stake",
    applied_stakes = {"cry_diamond"},
	loc_txt = {
        name = "Amber Stake",
        text = {
        "{C:attention}-1{} Booster Pack slot",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("feb900")
})
local bronze = SMODS.Stake({
	name = "Bronze Stake",
	key = "bronze",
	pos = {x = 4, y = 1},
    atlas = "stake",
    applied_stakes = {"cry_amber"},
	loc_txt = {
        name = "Bronze Stake",
        text = {
        "Vouchers are {C:attention}50%{} more expensive",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("d27c37")
})
local quartz = SMODS.Stake({
	name = "Quartz Stake",
	key = "quartz",
	pos = {x = 0, y = 2},
    atlas = "stake",
    applied_stakes = {"cry_bronze"},
	loc_txt = {
        name = "Quartz Stake",
        text = {
        "Jokers can be {C:attention}Pinned{}",
        "{s:0.8,C:inactive}(Stays pinned to the leftmost position){}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("e8e8e8")
})
local ruby = SMODS.Stake({
	name = "Ruby Stake",
	key = "ruby",
	pos = {x = 1, y = 2},
    atlas = "stake",
    applied_stakes = {"cry_quartz"},
	loc_txt = {
        name = "Ruby Stake",
        text = {
        "{C:attention}Big{} Blinds can become",
        "{C:attention}Boss{} Blinds",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("fc5f55")
})
local topaz = SMODS.Stake({
	name = "Topaz Stake",
	key = "topaz",
	pos = {x = 2, y = 2},
    atlas = "stake",
    applied_stakes = {"cry_ruby"},
	loc_txt = {
        name = "Topaz Stake",
        text = {
        "Blind rewards decreased by {C:attention}$2{}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("fcbb63")
})
local sapphire = SMODS.Stake({
	name = "Sapphire Stake",
	key = "sapphire",
	pos = {x = 3, y = 2},
    atlas = "stake",
    applied_stakes = {"cry_topaz"},
	loc_txt = {
        name = "Sapphire Stake",
        text = {
        "Lose {C:attention}25%{} of current money",
        "at end of Ante",
        "{s:0.8,C:inactive}(Up to $10){}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("3551fc")
})
local emerald = SMODS.Stake({
	name = "Emerald Stake",
	key = "emerald",
	pos = {x = 4, y = 2},
    atlas = "stake",
    applied_stakes = {"cry_sapphire"},
	loc_txt = {
        name = "Emerald Stake",
        text = {
        "Cards, packs, and vouchers",
        "can be {C:attention}face down{}",
        "{s:0.8,C:inactive}(Unable to be viewed until purchased){}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("06fc2c")
})
local platinum = SMODS.Stake({
	name = "Platinum Stake",
	key = "platinum",
	pos = {x = 0, y = 3},
    atlas = "stake",
    applied_stakes = {"cry_emerald"},
	loc_txt = {
        name = "Platinum Stake",
        text = {
        "Small Blinds are {C:attention}removed{}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("b0f6ff")
})
local twilight = SMODS.Stake({
	name = "Twilight Stake",
	key = "twilight",
	pos = {x = 1, y = 3},
    atlas = "stake",
    applied_stakes = {"cry_platinum"},
	loc_txt = {
        name = "Twilight Stake",
        text = {
        "Jokers can be {C:attention}Banana{}",
        "{s:0.8,C:inactive}(1 in 10 chance of being destroyed each round){}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local verdant = SMODS.Stake({
	name = "Verdant Stake",
	key = "verdant",
	pos = {x = 2, y = 3},
    atlas = "stake",
    applied_stakes = {"cry_twilight"},
	loc_txt = {
        name = "Verdant Stake",
        text = {
        "Required score scales",
        "faster for each {C:attention}Ante",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local ember = SMODS.Stake({
	name = "Ember Stake",
	key = "ember",
	pos = {x = 3, y = 3},
    atlas = "stake",
    applied_stakes = {"cry_verdant"},
	loc_txt = {
        name = "Ember Stake",
        text = {
        "Deck effects are {C:attention}halved",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local dawn = SMODS.Stake({
	name = "Dawn Stake",
	key = "dawn",
	pos = {x = 4, y = 3},
    atlas = "stake",
    applied_stakes = {"cry_ember"},
	loc_txt = {
        name = "Dawn Stake",
        text = {
        "Tarots and Spectrals target {C:attention}1",
        "fewer card",
        "{s:0.8,C:inactive}(Minimum of 1){}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local horizon = SMODS.Stake({
	name = "Horizon Stake",
	key = "horizon",
	pos = {x = 0, y = 4},
    atlas = "stake",
    applied_stakes = {"cry_dawn"},
	loc_txt = {
        name = "Horizon Stake",
        text = {
        "When blind selected, add a",
        "{C:attention}random card{} to deck",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local blossom = SMODS.Stake({
	name = "Blossom Stake",
	key = "blossom",
	pos = {x = 1, y = 4},
    atlas = "stake",
    applied_stakes = {"cry_horizon"},
	loc_txt = {
        name = "Blossom Stake",
        text = {
        "{C:attention}Final{} Boss Blinds can appear",
        "after Ante 1",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local azure = SMODS.Stake({
	name = "Azure Stake",
	key = "azure",
	pos = {x = 2, y = 4},
    atlas = "stake",
    applied_stakes = {"cry_blossom"},
	loc_txt = {
        name = "Azure Stake",
        text = {
        "Values on Jokers are reduced",
        "by {C:attention}20%{}",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})
local ascendant = SMODS.Stake({
	name = "Ascendant Stake",
	key = "ascendant",
	pos = {x = 3, y = 4},
    atlas = "stake",
    applied_stakes = {"cry_azure"},
	loc_txt = {
        name = "Ascendant Stake",
        text = {
        "{C:attention}-1{} Joker slot",
        "{s:0.8,C:inactive}(Not yet implemented){}",
        }
    },
    shiny = true,
    color = HEX("ffffff") --temporary before gradients
})

local stake_atlas = SMODS.Sprite({
    key = "stake",
    atlas = "asset_atlas",
    path = "stake_cry.png",
    px = 29,
    py = 29
})
local sticker_atlas = SMODS.Sprite({
    key = "sticker",
    atlas = "asset_atlas",
    path = "sticker_cry.png",
    px = 71,
    py = 95
})

local stakes = {pink, brown, yellow, silver, cyan, gray, crimson, diamond,
amber, bronze, quartz, ruby, topaz, sapphire, emerald, platinum,
twilight, verdant, ember, dawn, horizon, blossom, azure, ascendant}

for _, v in pairs(stakes) do
    v.sticker_pos = v.pos
    v.sticker_atlas = "sticker"
    local words = {}
    words[1], words[2] = v.name:match("(%w+)(.+)")
    local stakeName = words[1]
    v.sticker_loc_txt = {
        name = stakeName.." Sticker",
        text = {
            "Used this Joker",
            "to win on {C:attention}"..stakeName,
            "{C:attention}Stake{} difficulty"
        }
    }
end

return {stake_atlas, sticker_atlas, pink, brown, yellow, silver, cyan, gray, crimson, diamond,
        amber, bronze, quartz, ruby, topaz, sapphire, emerald, platinum,
        twilight, verdant, ember, dawn, horizon, blossom, azure, ascendant}