minetest.register_privilege("trusted", {description = "You are trusted...", give_to_singleplayer=false})

-- nothing "not normal" happening
local nothing = minetest.registered_items["bucket:bucket_lava"].on_place
local nothing_water = minetest.registered_items["bucket:bucket_water"].on_place

if minetest.get_modpath("technic") then
local nothing_lava_can = minetest.registered_items["technic:lava_can"].on_place
local nothing_water_can = minetest.registered_items["technic:water_can"].on_place
end

local MAX_LAVA_PLACE_DEPTH = -50 -- no placing in general except for trusted player under this depth
local MAX_WATER_PLACE_DEPTH = 50 -- placing in general only under this depth except for trusted player

minetest.override_item("bucket:bucket_lava", {
	on_place = function(itemstack, placer, pointed_thing)
		if not minetest.check_player_privs(placer:get_player_name(),
				{trusted = true}) then
			return itemstack
		else
			return nothing(itemstack, placer, pointed_thing)
		end
	end,
})

minetest.override_item("bucket:bucket_water", {
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		if not minetest.check_player_privs(placer:get_player_name(),
				{trusted = true}) and pos.y > (MAX_WATER_PLACE_DEPTH-2) then
			return itemstack
		else
				return nothing_water(itemstack, placer, pointed_thing)
		end
	end,
})

if minetest.get_modpath("technic") then
	minetest.override_item("technic:lava_can", {
		on_place = function(itemstack, placer, pointed_thing)
			if not minetest.check_player_privs(placer:get_player_name(),
					{trusted = true}) then
				return itemstack
			else
				return nothing_lava_can(itemstack, placer, pointed_thing)
			end
		end,
	})
end

if minetest.get_modpath("technic") then
	minetest.override_item("technic:water_can", {
		on_place = function(itemstack, placer, pointed_thing)
			local pos = pointed_thing.under
			if not minetest.check_player_privs(placer:get_player_name(),
					{trusted = true}) and pos.y > (MAX_WATER_PLACE_DEPTH-2) then
				return itemstack
			else
				return nothing_water_can(itemstack, placer, pointed_thing)
			end
		end,
	})
end

minetest.override_item("default:lava_source", {
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not minetest.check_player_privs(placer:get_player_name(),
				{trusted = true}) then
			minetest.remove_node(pos)
		end
	end,
	-- forbid constructing lava sources in general above MAX_LAVA_PLACE_DEPTH
	on_construct = function(pos)
			if pos.y >= MAX_LAVA_PLACE_DEPTH then
				minetest.env:remove_node(pos)
			end
	end,
})

minetest.override_item("default:water_source", {
	after_place_node = function(pos, placer, itemstack, pointed_thing)
	 if not minetest.check_player_privs(placer:get_player_name(),
				{trusted = true}) and pos.y >= MAX_WATER_PLACE_DEPTH then
			minetest.remove_node(pos)
		end
	end,
})

local function check_protection(pos, name, text)
	if minetest.is_protected(pos, name) then
		minetest.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
		return true
	end
	return false
end

minetest.override_item("bucket:bucket_empty", {
	description = "Empty Bucket",
	inventory_image = "bucket.png",
	stack_max = 99,
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		-- Must be pointing to node
		if pointed_thing.type ~= "node" then
			return
		end
		-- Check if pointing to a liquid source
		local node = minetest.get_node(pointed_thing.under)
		local liquiddef = bucket.liquids[node.name]
		local item_count = user:get_wielded_item():get_count()

		-- lava check
		if node.name == "default:lava_source"  and not minetest.check_player_privs(user:get_player_name(), {trusted = true}) then
			return
		end
		-- end lava check

		if liquiddef ~= nil
		and liquiddef.itemname ~= nil
		and node.name == liquiddef.source then
			if check_protection(pointed_thing.under,
					user:get_player_name(),
					"take ".. node.name) then
				return
			end
			-- default set to return filled bucket
			local giving_back = liquiddef.itemname

			-- check if holding more than 1 empty bucket
			if item_count > 1 then

				-- if space in inventory add filled bucked, otherwise drop as item
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=liquiddef.itemname}) then
					inv:add_item("main", liquiddef.itemname)
				else
					local pos = user:getpos()
					pos.y = math.floor(pos.y + 0.5)
					core.add_item(pos, liquiddef.itemname)
				end

				-- set to return empty buckets minus 1
				giving_back = "bucket:bucket_empty "..tostring(item_count-1)

			end

			minetest.add_node(pointed_thing.under, {name="air"})

			return ItemStack(giving_back)
		end
	end,
})
