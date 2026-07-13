# Hexamania.io

Hello! This is my game submission for the Raylib 6.x game jam! (the first one i've been in)  
You're basically a little hexagon guy and you shoot at other hexagons  
to get their hearts, merge them with your hexagon body, and become bigger.  
Like all good .io games, of course, the enemies are just bots.  

HUGE NOTE: I am aware of a bug that instantly crashes the game after some point.  
It has something to do with exceeded memory (details can be found on the console)  
I have to admit that not playtesting enough to catch this was a huge mistake in my part,  
I also didn't bother optimizing any of the code, I assumed it wouldn't matter since this is  
a really small game, and it would run fine, even without the optimizations.  
I'll probably not be updating this game anymore, or at least not until the voting period is over,  
so there's a good chance this crash is engraved into the game forever!  
I've learned from my mistakes :D  

Below is the game plan (each bullet is exactly how I had written it while making the game lol)

#### DAY 1
- Start out in the center of a map, nothing else around you
- Can move with arrow keys, physics like Epic Asteroid Game (just steal em lol)
- Shoot out little pellets/circles as the base attack
- Go onto hexagon hearts to M E R G E
- Merging combines that hexagon with yours, making you bigger and more resilient
- Hexagons have different types (with different colors)! Joining them buffs a certain stat.
- Get to 66 hexagons (should probably change to a number so that the player is a perfect hexagon) stuck together to REACH MAX!

#### DAY 2
- Evil hexagons, developed as the player
- Kill enemy hexagons -> drop hearts
- Evil hexagons move! (AI: Wander, "Find a target it likes", Full aggro, panic and run away on low health)
- Evil hexagons attack! (base attack for now)
- Oh ye health, self explanatory
- a ye add points
- Zoom out when building a full shell (leveling up)
- Hexahearts follow you when you're close.
- Make an ownership system (for spells, pellets, etc)
- Entities have UUIDs, so that the above works
- Add sprinting
- Add SIMPLE background
- Passively regain health
- Maybe make enemies collidable?

#### DAY 3
- Powerups (circular): give either a temporary buff or a health boost idk
- after max, no more normal hexagons spawn, only powerup ones.
- SPELLSSSSS
- Design a couple different hexagon and powerup types
- Enemies naturally spawn
- Powerups naturally spawn
- Enemies get bigger and stronger as time passes
- Grade when you die XD
- Menus (Main, Paused, Death, Win)
- Health bar (should be at the bottom middle of the screen lol)
- Map

#### DAY 4
###### Code
- Implement rifle upgrades (currently only the textures)
- Spell previews in spell mode (like a green rect_lines for the health one, etc)
- Spell cooldowns! (visible in spell mode)
- Better system to do player spells (right click to activate spell mode, scroll to choose spell)
- Enemy do spells
- Enemies spawn with different hexahearts
- Enemies drop hexahearts based on the ones they have!
- Add final spell, black hole!
- Dunno if this counts as code but add a menu with a list of all the spells the player has
- remove winning
###### Art
- Spell menu thing (bottom left, make it top left/right) should be the corresponding hexagon, with the number if it is on cooldown! (and darker)
- Layered hexagons on top of every clump's hexagons denoting if frozen/burning
- Note for top thing: both the freezing and burning overlays should be rotated on each hexagon, burning should be 3 parts that change color seperately
- powerup draw :>
- shader support

#### DAY 5
###### Code
- Hexagon has eyes <3 that look where your mouse is!
- Death animation
- Add tutorial
###### Balancing
- More hexagons = more max health
- buff spells, nerf weapon
- remove the "ice floor" thing
- fireball: huge explosion when hit, no piercing
- black hole, not being able to attack if colliding with it
- limit absolute max speed
- increase fov
- increase enemy amount by a bit
- hexahearts follow you everywhere
- limit enemy's velocity too
- enemies dont attack you if not in screen
###### Art
- fully draw spells (and the previews)
- New Background
- Prettier menus, maybe look space-y or some shi

#### DAY 6 (FINAL DAY)
- finish tutorial
- redo health bar
- Sound effects
- add the .io thing on the logo
- has_killed_enemy info
- death sequence
- Music! (should be 6/4 lol, calm and relaxing with reverb/echo)