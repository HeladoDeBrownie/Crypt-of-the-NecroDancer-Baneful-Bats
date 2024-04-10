-- Being next to a bat who's about to move is almost always a blunder. The goal
-- of this mod is to provide feedback when a player does so. By killing them.

local Action = require'necro.game.system.Action'
local AI = require'necro.game.enemy.ai.AI'
local Attack = require'necro.game.character.Attack'
local Collision = require'necro.game.tile.Collision'
local Damage = require'necro.game.system.Damage'
local Event = require'necro.event.Event'
local Flyaway = require'necro.game.system.Flyaway'
local Player = require'necro.game.character.Player'

-- The "feedback" needs to happen *before* the bat has decided which way to go,
-- so that the bat can go on their merry little way unbothered and unimpeded.
Event.objectCheckMove.add('batstep', {
    order = 'moveType',
    filter = {
        -- Bats are AI entities, which is as specific as we can get as far as
        -- filtering for components goes.
        'ai',
        -- But black bats are exempt because there is no randomness involved in
        -- them attacking you. They just always attack if able.
        '!aiAttackWhenPossible',
    },
}, function (event)
    local entity = event.entity
    local ai = entity.ai

    -- Consider only entities who move at random. In other words, bats. It's
    -- okay if someone modded in something that moves at random and isn't a bat
    -- though. The more the merrier.
    if ai.id ~= AI.Type.RANDOM then return end

    local position = entity.position
    local my_x, my_y = position.x, position.y

    -- Check every reachable tile for incautious players. For most bats this
    -- means cardinal directions only, but green bats will also threaten
    -- diagonals.
    for _, direction in ipairs(ai.directions) do
        local dx, dy = Action.getMovementOffset(direction)
        local target_x, target_y = my_x + dx, my_y + dy

        -- Ignore any tile we wouldn't normally have attacked. Even though we
        -- might attack a player bearing a ring of luck or lucky charm if
        -- forced to do so, they're still immune to the instant death due to
        -- it not being luck-dependent. Lucky them!
        if Collision.check(target_x, target_y, ai.collision) then
            goto next
        end

        local victims =
            Attack.getAttackableEntitiesOnTile(entity, target_x, target_y)

        for _, victim in ipairs(victims) do
            if Player.isPlayerEntity(victim) then
                -- Someone made a wrong move! Kill!
                Flyaway.create({text = 'Bat blunder!', entity = victim})
                -- Damage.inflict was chosen over Object.die because it causes
                -- a red VFX like that of Monk's death from vow of poverty.
                Damage.inflict{
                    victim = victim,
                    damage = 999,
                    type = Damage.Type.SELF_DESTRUCT,
                    killerName = 'incaution',
                }
            end
        end

        ::next::
    end
end)
