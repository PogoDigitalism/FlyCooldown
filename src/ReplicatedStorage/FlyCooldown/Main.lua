local Cooldown = {}
Cooldown.__index = Cooldown

type _player = number
type _unix = number

type on_cooldown = boolean
type cooldown_applied = boolean

function Cooldown.new(callback: (player: Player, cooldown_time: number) -> ()?)
	return setmetatable({
		callback = assert(
			typeof(callback) == 'function' or typeof(callback) == nil,
			"`callback` must be a function"
		), -- PUBLIC | Can be set after instancing a Cooldown instance
		_cooldown_list = {} :: {[_player]: {
				time_applied: _unix,
				cooldown_time: number,
			}
		},
		
		
	}, Cooldown)
end
export type CLASS = typeof(Cooldown.new(...))

function Cooldown.check(self: CLASS): on_cooldown
end

function Cooldown.apply(self: CLASS): cooldown_applied
end

function Cooldown.checkAndApply(self: CLASS): cooldown_applied
end

function Cooldown.clear(self: CLASS, player: Player)
end

function Cooldown.globalClear(self: CLASS)
end


return Cooldown
