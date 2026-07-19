# Hexamania.io

Hello! This is my game submission for the Raylib 6.x game jam! (the first one i've been in)  
You're basically a little hexagon guy and you shoot at other hexagons  
to get their hearts, merge them with your hexagon body, and become bigger.  
Like all good .io games, of course, the enemies are just bots.  

This is my first game jam, I dove straight in without any sort of preperation...  
It was more difficult than I expected, originally the plan was to make a relatively  
small game, but as time passed, I wanted to add more and more things.  

Originally, I was planning to finish the code by the second day, art by the third  
and sound by the fourth, which would've left 2 extra days of bugfixing, playtesting,  
and balancing. Unfortunately, I ended up finishing the code on the last day, which  
meant I had to do the code, art, and sound simultaneously. This isn't because I'm a  
slow programmer (okay maybe it is), it's because I wasn't very in-depth when making the  
game plan. From a glance, it seemed like there weren't that many things to do, so I adjusted  
the plan accordingally. However, I realised that my "tasks" for each day were way too vague,  
they had additional sub-tasks that I didn't take into account, that ended up costing me  
a lot of time.  

I went in thinking that I shouldn't have worried about the cleanness(?) of my code. In general,  
I did a lot of copy pasting, and applied some design philosophies that are pretty bad. This cost me  
a memory leak that I decided to ingore, that ended up making the game unplayable after some point! (this is fixed)  
If I end up updating the game, I'd like to clean the code up a lot.  

There were also some bugs and QoLs that I didn't have the time to fix,  
most notably a bug that crashed the game because of a memory leak, as mentioned above.  
I ended up fixing this and a few more, and I will probably be fixing the rest of them at a later date.  

In general I was pretty happy with how it turned out, even though my score isn't the best,  
I'm satisfied enough, as I had no idea what I was doing. I will probably be updating the game,  
as I like the idea and want to completely finish the project. I ended up not adding a lot of things  
because of the time constraint, so there's a chance I'll be adding those, but at the same time, I want  
to keep the game about the same as it was at launch.

Below is the game roadmap. Note that this isn't like it was at launch, as I ended up having to  
move/postpone a lot of tasks. These are exactly how I had written them while making the plan.  
(some were added later)  

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

Ultimately, some of these (like shaders and collisions) weren't added. I had some prototype  
versions, but they ended up being too buggy or didn't fit in, so I had to scrap them.