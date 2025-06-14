--!strict

local Observer = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Cleaner = require("./Cleaner")

function Observer.ObserveTag(Tag: string, Callback: (Instance) -> ())
    for _, Instance in CollectionService:GetTagged(Tag) do
        Callback(Instance)
    end

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
        Callback(Instance)
    end)
end

function Observer.ObservePlayers(Callback: (Player) -> (), Cleanup: nil | (Player) -> ())
	for _, Player in Players:GetPlayers() do
		Callback(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
        Callback(Player)
    end)

	if typeof(Cleanup) == "function" then
		Players.PlayerRemoving:Connect(Cleanup)
	end
end

function Observer.ObserveCharacters(Callback: (Player, Model) -> any, Cleanup: nil | (Player, Model) -> any)
	local CharacterCleaners = {}

	Observer.ObservePlayers(function(Player)
		CharacterCleaners[Player] = Cleaner.new()

		if Player.Character then
			Callback(Player, Player.Character)
		end

		CharacterCleaners[Player]:Add(Player.CharacterAdded:Connect(function(Character)
			Callback(Player, Character)
		end))

        CharacterCleaners[Player]:Add(Player.CharacterRemoving:Connect(function(Character)
            if not Cleanup or typeof(Cleanup) ~= "function" then
                return
            end

            Cleanup(Player, Character)
        end))
	end,

    function(Player)
        CharacterCleaners[Player]:Clean()
    end)
end

return Observer
