# Hexamania.io

Hexamania description goes here

## IDEAS

#### DAY 1
- ~~Start out in the center of a map, nothing else around you~~
- ~~Can move with arrow keys, physics like Epic Asteroid Game (just steal em lol)~~
- ~~Shoot out little pellets/circles as the base attack~~
- ~~Go onto hexagon hearts to M E R G E~~
- ~~Merging combines that hexagon with yours, making you bigger and more resilient~~
- ~~Hexagons have different types (with different colors)! Joining them buffs a certain stat.~~
- ~~Get to 66 hexagons (should probably change to a number so that the player is a perfect hexagon) stuck together to REACH MAX!~~

#### DAY 2
- ~~Evil hexagons, developed as the player~~
- ~~Kill enemy hexagons -> drop hearts~~
- ~~Evil hexagons move! (AI: Wander, "Find a target it likes", Full aggro, panic and run away on low health)~~
- ~~Evil hexagons attack! (base attack for now)~~
- ~~Oh ye health, self explanatory~~
- ~~a ye add points~~
- ~~Zoom out when building a full shell (leveling up)~~
- ~~Hexahearts follow you when you're close.~~
- ~~Make an ownership system (for spells, pellets, etc)~~
- ~~Entities have UUIDs, so that the above works~~
- ~~Add sprinting~~
- ~~Add SIMPLE background~~
- ~~Passively regain health~~
- ~~Maybe make enemies collidable?~~

#### DAY 3
- ~~Powerups (circular): give either a temporary buff or a health boost idk~~
- ~~after max, no more normal hexagons spawn, only powerup ones.~~
- ~~SPELLSSSSS~~
- ~~Design a couple different hexagon and powerup types~~
- ~~Enemies naturally spawn~~
- ~~Powerups naturally spawn~~
- ~~Enemies get bigger and stronger as time passes~~
- ~~Grade when you die XD~~
- ~~Menus (Main, Paused, Death, Win)~~
- ~~Health bar (should be at the bottom middle of the screen lol)~~
- ~~Map~~

#### DAY 4
###### Code
- ~~Implement rifle upgrades (currently only the textures)~~
- ~~Spell previews in spell mode (like a green rect_lines for the health one, etc)~~
- ~~Spell cooldowns! (visible in spell mode)~~
- ~~Better system to do player spells (right click to activate spell mode, scroll to choose spell)~~
- ~~Enemy do spells~~
- ~~Enemies spawn with different hexahearts~~
- ~~Enemies drop hexahearts based on the ones they have!~~
- ~~Add final spell, black hole!~~
- ~~Dunno if this counts as code but add a menu with a list of all the spells the player has~~
- ~~remove winning~~
###### Art
- ~~Spell menu thing (bottom left, make it top left/right) should be the corresponding hexagon, with the number if it is on cooldown! (and darker)~~
- ~~Layered hexagons on top of every clump's hexagons denoting if frozen/burning~~
- ~~Note for top thing: both the freezing and burning overlays should be rotated on each hexagon, burning should be 3 parts that change color seperately~~
- ~~powerup draw :>~~
- ~~shader support~~

#### DAY 5 (FINAL DAY)
###### Code
- Hexagon has eyes <3 that look where your mouse is!
- Death animation
- find good shader to use (glowy)
- Balance to hell
###### Art
- fully draw spells (and the previews)
- New Background, should have falling hexagons lol
- Prettier menus, maybe look space-y or some shi
- Transitions maybe? (for each gamestate)
###### Sound
- Sound effects
- Music! (should be 6/4 lol, calm and relaxing with reverb/echo)

## HEXAHEARTS

#### Rifle
Shoots pellets  
Victim takes damage when hit by pellet
Upgrades: shoot speed (how fast they go), damage, fire rate

#### Health Pad
Places a health pad on the user's position (like grass and flowers or something)  
User heals when on the pad  
Upgrades: size, time, health (how much health it gives each time)  

#### Ice Ball
Ice area thingies are summoned from the ground (with piercing)  
After hitting an enemy, freezes them for some seconds (cant move or attack)  
Upgrades: more range, more aoe, more freeze time  

#### Fireball
Shoots a fireball (with piercing)  
Hit enemies get burned for some seconds (periodically take damage)  
Upgrades: size/aoe, time, damage dealt  

#### Black Hole
Shoots a black hole  
Close enemies are pulled into it  
Upgrades: size, suction power, time  