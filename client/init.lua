TOWING_VEHICLE = nil
SELECTED_VEHICLE = nil
RAYCAST = nil
ATTACH = false

local function clamp(val, min, max)
	if val < min then
		return min
	elseif val > max then
		return max
	else
		return val
	end
end

function StartAttach()
	if ATTACH then return end
	ATTACH = true

	local xPos, yPos, zPos = 0.0, -1.0, 1.0
	local xRot, yRot, zRot = 0.0, 0.0, 0.0

	FreezeEntityPosition(TOWING_VEHICLE, true)
	FreezeEntityPosition(SELECTED_VEHICLE, true)

	SetEntityCollision(TOWING_VEHICLE, false, true)
	SetEntityCollision(SELECTED_VEHICLE, false, true)

	SetEntityAlpha(SELECTED_VEHICLE, 115, false)

	AttachEntityToEntity(SELECTED_VEHICLE, TOWING_VEHICLE, 0,
	xPos, yPos, zPos,
	xRot, yRot, zRot,
	0, false, false, false, 2, true)

	local ButtonsHandle = RequestScaleformMovie('INSTRUCTIONAL_BUTTONS')
	while not HasScaleformMovieLoaded(ButtonsHandle) do
		Wait(0)
	end

	CallScaleformMovieMethod(ButtonsHandle, 'CLEAR_ALL')
	CallScaleformMovieMethodWithNumber(ButtonsHandle, 'TOGGLE_MOUSE_BUTTONS', 0)

	local function SetInstructionSlot(slotIndex, input1, text1)
		BeginScaleformMovieMethod(ButtonsHandle, 'SET_DATA_SLOT')
		ScaleformMovieMethodAddParamInt(slotIndex)

		ScaleformMovieMethodAddParamPlayerNameString(input1)
		ScaleformMovieMethodAddParamPlayerNameString(text1)

		EndScaleformMovieMethod()
	end

	SetInstructionSlot( 9, '~INPUT_FRONTEND_ACCEPT~', 'Apply')
	SetInstructionSlot( 8, '~INPUT_FRONTEND_CANCEL~', 'Cancel')
	SetInstructionSlot( 7, '~INPUT_FRONTEND_RIGHT~', 'Move Right')
	SetInstructionSlot( 6, '~INPUT_FRONTEND_LEFT~', 'Move Left')
	SetInstructionSlot( 5, '~INPUT_FRONTEND_DOWN~', 'Move Backward')
	SetInstructionSlot( 4, '~INPUT_FRONTEND_UP~', 'Move Forward')
	SetInstructionSlot( 3, '~INPUT_HUD_SPECIAL~', 'Rotate Left')
	SetInstructionSlot( 2, '~INPUT_LOOK_BEHIND~', 'Rotate Right')
	SetInstructionSlot( 1, '~INPUT_COVER~', 'Move Up')
	SetInstructionSlot( 0, '~INPUT_CONTEXT~', 'Move Down')


	EndScaleformMovieMethod()
	CallScaleformMovieMethod(ButtonsHandle, 'DRAW_INSTRUCTIONAL_BUTTONS')

	local applied = false
	CreateThread(function()
		while true do
			Wait(0)
			DrawScaleformMovieFullscreen(ButtonsHandle, 255, 255, 255, 255, 1)

			EnableControlAction(0, 44, false) -- Q
			EnableControlAction(0, 46, false) -- E
			EnableControlAction(0, 26, false) -- C
			EnableControlAction(0, 48, false) -- Z
			EnableControlAction(0, 188, false) -- W
			EnableControlAction(0, 187, false) -- S
			EnableControlAction(0, 189, false) -- A
			EnableControlAction(0, 190, false) -- D
			EnableControlAction(0, 172, false) -- W
			EnableControlAction(0, 173, false) -- S
			EnableControlAction(0, 174, false) -- A
			EnableControlAction(0, 175, false) -- D
			EnableControlAction(0, 201, false) -- Enter
			EnableControlAction(0, 202, false) -- Backspace

			if IsDisabledControlJustReleased(2, 201) then
				applied = true
				break
			end

			if IsDisabledControlJustReleased(2, 202) then
				break
			end

			if IsControlPressed(2, 44) then
				zPos += 0.01
			end

			if IsControlPressed(2, 46) then
				zPos -= 0.01
			end

			if IsControlPressed(2, 26) then -- Rotate Left
				zRot -= 1
			end

			if IsControlPressed(2, 48) then -- Rotate Right
				zRot += 1
			end

			if IsControlPressed(2, 172) then
				yPos += 0.01
				if yPos > 7.5 then
					yPos = 7.5
				end
			end

			if IsControlPressed(2, 173) then
				yPos -= 0.01
				if yPos < -7.5 then
					yPos = -7.5
				end
			end

			if IsControlPressed(2, 174) then
				xPos -= 0.01
				if xPos < -4 then xPos = -4 end
			end

			if IsControlPressed(2, 175) then
				xPos += 0.01
				if xPos > 4 then xPos = 4 end
			end

			AttachEntityToEntity(SELECTED_VEHICLE, TOWING_VEHICLE, 0,
			xPos, yPos, zPos,
			xRot, yRot, zRot,
			0, false, false, false, 2, true)
		end

		SetScaleformMovieAsNoLongerNeeded(ButtonsHandle)
		local towID = NetworkGetNetworkIdFromEntity(TOWING_VEHICLE)
		local attachID = NetworkGetNetworkIdFromEntity(SELECTED_VEHICLE)

		SetEntityAlpha(SELECTED_VEHICLE, 255, false)
		FreezeEntityPosition(TOWING_VEHICLE, false)
		FreezeEntityPosition(SELECTED_VEHICLE, false)

		SetEntityCollision(TOWING_VEHICLE, true, true)
		SetEntityCollision(SELECTED_VEHICLE, true, true)

		ATTACH = false
		TOWING_VEHICLE = nil
		SELECTED_VEHICLE = nil

		if not applied then return end
		TriggerServerEvent("filo_tow_attachVehicle", towID, attachID)
	end)
end

function StartRaycast()
	if RAYCAST then return end
	RAYCAST = true

	local ped = cache.ped
	local coords = GetEntityCoords(ped)
	local outline = false
	local outlinedEntity = nil

	local function applyOutline(entity, state)
		if state then
			outline = true
			outlinedEntity = entity
			SetEntityDrawOutline(outlinedEntity, true)
			SetEntityDrawOutlineShader(1)
		else
			SetEntityDrawOutline(outlinedEntity, false)
			outlinedEntity = nil
			outline = false
		end
	end

	CreateThread(function()
		local selected = false
		local lastEntity = nil
		while RAYCAST do
			local hit, entity, coords = lib.raycast.fromCamera(2, nil, 10)

			DisableControlAction(2, 202)
			if IsDisabledControlJustReleased(2, 202) then
				break
			end

			AddTextEntry('TEST_LABEL', '~a~')
			BeginTextCommandDisplayHelp('TEST_LABEL')
			if not TOWING_VEHICLE then
				AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to select a vehicle to attach/detach.')
			else
				if not SELECTED_VEHICLE then
					AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to select a vehicle to tow.')
				end
			end

			EndTextCommandDisplayHelp(
			0,
			false,
			true,
			-1
		)

		if hit and entity ~= 0 then
			if not IsEntityAVehicle(entity) then goto continue end
			local entityState = Entity(entity).state

			if lastEntity ~= entity then
				applyOutline(nil, false)
				lastEntity = nil
			end

			if TOWING_VEHICLE and entity == TOWING_VEHICLE then
				applyOutline(nil, false)
				goto continue
			end

			if SELECTED_VEHICLE and entity == SELECTED_VEHICLE then
				applyOutline(nil, false)
				goto continue
			end

			if not outline then
				lastEntity = entity
				applyOutline(entity, true)
				if entityState and entityState.attached then
					SetEntityDrawOutlineColor(255, 0, 0, 255)
				else
					SetEntityDrawOutlineColor(255, 255, 255, 255)
				end
			end

			if IsControlJustReleased(2, 51) then
				if not TOWING_VEHICLE then
					if entityState and entityState.attached then
						local parent = NetworkGetEntityFromNetworkId(entityState.attached)
						local targetCoords = GetOffsetFromEntityInWorldCoords(parent, -4.0, 0.0, 0.0)

						DetachEntity(entity)

						SetEntityCoords(
						entity,
						targetCoords.x,
						targetCoords.y,
						targetCoords.z
					)

					SetEntityHeading(entity, GetEntityHeading(parent))
					SetVehicleOnGroundProperly(entity)

					TriggerServerEvent("filo_tow_detachVehicle", entityState.attached, NetworkGetNetworkIdFromEntity(entity))
					break
				end

				if entityState and entityState.attachedVehicle then
					local data = json.decode(entityState.attachedVehicle)
					if #data > Config.MaxAttachedVehicles then
						lib.notify({
							type = "error",
							title = "Max attached vehicles."
						})
						goto continue
					end
				end

				if not Config.AllowedVehicles[GetEntityModel(entity)] then
					lib.notify({
						type = "error",
						title = "Vehicle not allowed."
					})

					goto continue
				end

				TOWING_VEHICLE = entity
			else
				if entityState and entityState.attached then
					lib.notify({
						type = "error",
						title = "Already attached."
					})
					goto continue
				end

				if #(GetEntityCoords(entity) - GetEntityCoords(TOWING_VEHICLE)) > 15 then
					lib.notify({
						type = "error",
						title = "Too far."
					})

					goto continue
				end

				SELECTED_VEHICLE = entity
				selected = true
				StartAttach()

				break
			end
		end

		::continue::
	else
		if outline then
			SetEntityDrawOutline(outlinedEntity, false)
			outlinedEntity = nil
			outline = false
		end
	end
end

if outline then
	applyOutline(nil, false)
end

RAYCAST = false
if not selected then
	TOWING_VEHICLE = nil
	SELECTED_VEHICLE = nil
end
end)
end

function StartTowing()
	if TOWING_VEHICLE or SELECTED_VEHICLE then return end
end

RegisterCommand(Config.Command, function()
	if RAYCAST then
		RAYCAST = false
	else
		StartRaycast()
	end
end)

AddEventHandler('onResourceStop', function(name)
	if name ~= GetCurrentResourceName() then return end
	if not TOWING_VEHICLE and not SELECTED_VEHICLE then return end

	if IsEntityAttachedToEntity(SELECTED_VEHICLE, TOWING_VEHICLE) then
		DetachEntity(SELECTED_VEHICLE, true, true)
	end

	FreezeEntityPosition(TOWING_VEHICLE, false)
	FreezeEntityPosition(SELECTED_VEHICLE, false)

	SetEntityCollision(TOWING_VEHICLE, true, true)
	SetEntityCollision(SELECTED_VEHICLE, true, true)
end)