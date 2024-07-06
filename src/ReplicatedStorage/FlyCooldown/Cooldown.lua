--!strict

local Cooldown = {}
Cooldown.__index = Cooldown

type _player = number
type _callback = (player: Player, cooldown_time: number) -> ()

type unix = number
type on_cooldown = boolean
type cooldown_applied = boolean

function Cooldown.new(default_cooldown: number, callback: _callback?)
	assert(
		typeof(default_cooldown) == 'number',
		"`default_cooldown` must be a number"
	)	
	assert(
		typeof(callback) == 'function' or typeof(callback) == 'nil',
		"`callback` must be a function or unfilled"
	)

	return setmetatable({
		default_cooldown = default_cooldown, -- PUBLIC REQUIRED | Can be set after instancing a Cooldown instance
		callback = callback, -- PUBLIC OPTIONAL | Can be set after instancing a Cooldown instance
		
		_cooldown_list = {} :: {[_player]: {
				time_applied: unix,
				cooldown_time: number,
			}
		},
		_callback_registry = {} :: {[_player]: thread}
	}, Cooldown)
end
export type CLASS = typeof(Cooldown.new(...))

function Cooldown.setEntry(self: CLASS, player: Player, time_applied: unix, cooldown_time: number): ()
	assert(
		player:IsA('Player'),
		'`player` must be a Player'
	)
	assert(
		typeof(time_applied) == 'number',
		'`time_applied` must be a number (unix)'
	)
	assert(
		typeof(cooldown_time) == 'number',
		'`cooldown_time` must be a number'
	)

	self._cooldown_list[player.UserId] = {
		["time_applied"] = time_applied,
		["cooldown_time"] = cooldown_time,
	}
end

function Cooldown.check(self: CLASS, player: Player): on_cooldown | nil
	assert(
		player:IsA('Player'), 
		'`player` must be a Player'
	)
	
	local _current = DateTime.now().UnixTimestampMillis
	local _cooldown_info = self._cooldown_list[player.UserId]
	if _cooldown_info then
		if _current - _cooldown_info.time_applied < _cooldown_info.cooldown_time then
			return false
		end

		return true
	else
		return nil
	end
end

function Cooldown._delayCallback(self: CLASS, player: Player, cooldown_time: number): ()
	task.wait(
		cooldown_time
	)
	
	if self.callback then -- !strict satisfyer
		self.callback(
			player, 
			cooldown_time
		)
		self._callback_registry[player.UserId] = nil
	end
end

function Cooldown.apply(self: CLASS, player: Player, cooldown_time: number?): ()
	self._cooldown_list[player.UserId] = {
		["time_applied"] = DateTime.now().UnixTimestampMillis,
		["cooldown_time"] = cooldown_time or self.default_cooldown
	}
	
	if self.callback then
		local Thread = coroutine.create(
			self._delayCallback
		)
		self._callback_registry[player.UserId] = Thread
		
		coroutine.resume(
			Thread, 
			self, player, cooldown_time
		)
	end
end

function Cooldown.checkAndApply(self: CLASS, player: Player, cooldown_time: number?): cooldown_applied
	if self:check(player) then
		self:apply(player, 
			cooldown_time
		)

		return true
	else
		return false
	end
end

function Cooldown.cancelCallback(self: CLASS, player: Player): ()
	local Thread = self._callback_registry[player.UserId]
	if Thread then
		coroutine.close(
			Thread
		)
		self._callback_registry[player.UserId] = nil
	end	
end

function Cooldown.clear(self: CLASS, player: Player): ()
	self._cooldown_list[player.UserId] = nil

	self:cancelCallback(
		player
	)
end

function Cooldown.globalClear(self: CLASS): ()
	table.clear(
		self._cooldown_list
	)
	
	for id, Thread in self._callback_registry do
		coroutine.close(
			Thread
		)
	end
end

return Cooldown
