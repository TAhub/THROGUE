package game 
{
	import net.flashpunk.graphics.TiledSpritemap;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	
	public class Map extends World
	{
		[Embed(source = "sprites/tiles.png")] private static const TILE:Class;
		[Embed(source = "sprites/chests.png")] private static const CHEST:Class;
		[Embed(source = "sprites/pitEffect.png")] private static const PITEFFECT:Class;
		private static const NOTILE:uint = 999;
		public static const TILESIZE:uint = 40;
		public static const ACCESSEDCHEST:uint = 1000;
		private static const LOWERDARKENFACTOR:Number = 0.5;
		private static const LOWERDARKENFACTORHALF:Number = 0.85;
		private static const BORDERSIZE:uint = 10;
		private static const SHRINKPOTENTIAL:Number = 0.25;
		private static const METATILELISTLENGT:uint = 4; //number of entries in the meta tile lists
		private static const BRUSHSIZE:uint = 3; //size of the texture brush
		private static const COARSEBRUSHSIZE:uint = 15; //size of the coarse meta brush
		private static const FINEBRUSHCHANCE:Number = 0.4; //chance of the fine meta brush
		private static const PATHMAPRADIUS:uint = 6;
		private static const sprTile:Spritemap = new Spritemap(TILE, TILESIZE, TILESIZE);
		private static const MAXSEGMENTS:uint = 8;
		private static const sprQuarterTile:Spritemap = new Spritemap(TILE, TILESIZE, TILESIZE / MAXSEGMENTS);
		private static const sprPitEffect:TiledSpritemap = new TiledSpritemap(PITEFFECT, TILESIZE, TILESIZE / 2, TILESIZE, TILESIZE / 2);
		private static const sprHalfTile:Spritemap = new Spritemap(TILE, TILESIZE, TILESIZE / 2);
		private static const sprChest:Spritemap = new Spritemap(CHEST, TILESIZE, TILESIZE);
		private static const CHESTMIN:uint = 3; //minimum chest size
		private static const CHESTMAX:uint = 8; //maximum chest size
		private static const MINDIFFICULTYINCREASE:uint = 1; //minimum increase in difficulty between maps
		private static const MAXDIFFICULTYINCREASE:uint = 3;
		private static const MONSTERGROUPSIZE:uint = 3; //radius of a monster group
		private static const MONSTERGROUPMINNUMBER:uint = 1;
		private static const MONSTERGROUPMAXNUMBER:uint = 2;
		private static const SHOPSIZE:uint = 8;
		private static const MINROOMSIZE:uint = 7;
		private static const MAXROOMSIZE:uint = 15;
		private static const WINDOWCHANCE:Number = 0.4;
		private static const FLOORFAILS:uint = 4000;
		private static const TRAPVARIATION:Number = 0.25;
		private static const MERCHANTEQUIPLOOT:uint = 4;
		private static const BOSSEQUIPLOOT:uint = 2;
		// generation shape constants
		private static const SHAPEFLOOR:uint = 0;
		private static const SHAPESOLID:uint = 1;
		private static const SHAPEDOOR:uint = 2;
		private static const SHAPEWINDOW:uint = 3;
		private static const SHAPEFURNITURE:uint = 4;
		private static const SHAPEROOMSOLID:uint = 5;
		private static const SHAPEDEPLETEDROOMSOLID:uint = 6;
		private var visibleArray:Array;
		private var explored:Array;
		private var creatures:Array;
		private var traps:Array;
		private var items:Array;
		private var tiles:Array;
		private var background:Array;
		private var stairs:Array;
		private var creaturesOrder:Array;
		private var moving:Creature;
		private var width:uint;
		private var height:uint;
		private var p:Player;
		private var firstCenter:Number;
		private var _levelNumber:uint;
		private var _difficulty:uint;
		private var _faction:uint;
		private var _mapID:uint;
		private var pitEffectTimer:Number;
		private var pitEffect:Number;
		public var crime:Boolean;
		
		public function Map(levelNumber:uint, levelFrom:uint, difficulty:uint, faction:uint) 
		{
			crime = false;
			p = null;
			pitEffectTimer = 100 * Math.random();
			
			_levelNumber = levelNumber;
			if (_levelNumber == 0)
			{
				_levelNumber = Saver.levelOn;
			}
			
			//initialize the visible array
			visibleArray = new Array();
			for (var i:uint = 0; i < (FP.width / TILESIZE) * (FP.height / TILESIZE); i++)
				visibleArray.push(false);
			
			if (Saver.levelExists(_levelNumber))
			{
				Saver.load(_levelNumber, this);
				if (levelFrom != 0)
				{
					//this means that you came from somewhere else
					//so load the player specially
					loadPlayerAtStairs(levelFrom);
				}
			}
			else
			{
				//generate the map
				trace("GENERATING LEVEL " + _levelNumber);
				_difficulty = difficulty; //save the difficulty suggestion
				generate(levelFrom, faction);
				moving = null;
			}
			
			firstCenter = 0;
			
			Saver.setLevelOn(_levelNumber);
		}
		
		public function save():void
		{
			Saver.save(_levelNumber, this, true);
		}
		
		private function savePlayer():void
		{
			var pArray:Array = Saver.playerArray;
			while (pArray.length > 0)
				pArray.pop();
			p.save(pArray);
		}
		
		private function staircaseAt(i:uint):Boolean
		{
			for (var j:uint = 0; j < stairs.length / 2; j++)
			{
				if (stairs[j * 2 + 1] == i)
					return true;
			}
			return false;
		}
		
		public function useStaircaseAt(x:uint, y:uint):void
		{
			var iA:uint = getI(x, y);
			for (var i:uint = 0; i < stairs.length / 2; i++)
			{
				if (stairs[i * 2 + 1] == iA)
				{
					var to:uint = stairs[i * 2];
					if (to == 0)
					{
						//this stair is undefined, so pick a destination for it
						to = Saver.freeLevelNumber;
						stairs[i * 2] = to;
					}
					
					//save the level, so you can come back
					Saver.save(_levelNumber, this, false);
					
					//save the player, so the next level can access it
					savePlayer();
					
					//load the level
					FP.world = new Map(to, _levelNumber,
						_difficulty + MINDIFFICULTYINCREASE + (MAXDIFFICULTYINCREASE - MINDIFFICULTYINCREASE) * Math.random(),
						_faction);
					
					return;
				}
			}
		}
		
		private function loadPlayerAtStairs(levelFrom:uint):void
		{
			for (var i:uint = 0; i < stairs.length / 2; i++)
			{
				if (stairs[i * 2] == levelFrom)
				{
					loadPlayer(getX(stairs[i * 2 + 1]), getY(stairs[i * 2 + 1]));
					return;
				}
			}
			trace("Unable to find staircase back to level " + levelFrom);
		}
		
		private function loadPlayer(x:uint, y:uint):void
		{
			var pArray:Array = Saver.playerArray;
			p = Creature.load(pArray, 0)[0] as Player;
			p.setPosition(x, y);
			creatures[getI(x, y)] = p;
			//force it to be the front of the array
			var newCO:Array = new Array();
			newCO.push(p);
			for (var i:uint = 0; i < creaturesOrder.length; i++)
				newCO.push(creaturesOrder[i]);
			creaturesOrder = newCO;
		}
		
		public function saveSettings(saveTo:Array):void
		{
			saveTo.push(_mapID);
			saveTo.push(width);
			saveTo.push(height);
			saveTo.push(_difficulty);
			saveTo.push(_faction);
			saveTo.push(pitEffect);
			saveTo.push(crime);
		}
		
		public function loadSettings(loadFrom:Array):void
		{
			var on:uint = 0;
			_mapID = loadFrom[on++];
			width = loadFrom[on++];
			height = loadFrom[on++];
			_difficulty = loadFrom[on++];
			_faction = loadFrom[on++];
			pitEffect = loadFrom[on++];
			crime = loadFrom[on++];
		}
		
		private function toVisibleI(x:uint, y:uint):uint
		{
			return ((x - (FP.camera.x / TILESIZE)) +
					(y - (FP.camera.y / TILESIZE)) * (FP.width / TILESIZE));
		}
		
		public function squareIsVisible(x:uint, y:uint):Boolean
		{
			return onscreen(x, y) && visibleArray[toVisibleI(x, y)];
		}
		
		public function getOthers(caller:Creature):Array
		{
			var others:Array = new Array();
			for (var i:uint = 0; i < creaturesOrder.length; i++)
			{
				var cr:Creature = creaturesOrder[i];
				if (cr != caller)
					others.push(cr);
			}
			return others;
		}
		
		public function inBounds(x:int, y:int):Boolean
		{
			return (x < width && y < height && x >= 0 && y >= 0);
		}
		
		public function spaceEmptyI(i:uint):Boolean
		{
			return creatureAtI(i) == null && Main.data.tile[tiles[i]][3] == 0;
		}
		
		public function spaceEmptyXY(x:uint, y:uint):Boolean
		{
			return spaceEmptyI(getI(x, y));
		}
		
		public function move(oldX:uint, oldY:uint, newX:uint, newY:uint):void
		{
			var oldI:uint = getI(oldX, oldY);
			var newI:uint = getI(newX, newY);
			creatures[newI] = creatures[oldI];
			creatures[oldI] = null;
		}
		
		public function creatureAtI(i:uint):Creature
		{
			return creatures[i];
		}
		
		public function creatureAtXY(x:uint, y:uint):Creature
		{
			return creatures[getI(x, y)];
		}
		
		public function getI(x:uint, y:uint):uint { return x + y * width; }
		public function getX(i:uint):uint { return i % width; }
		public function getY(i:uint):uint { return i / width; }
		
		public function getPathMap(fromX:uint, fromY:uint):PathMap
		{
			var l:int = fromX - PATHMAPRADIUS;
			var r:uint = fromX + PATHMAPRADIUS;
			var u:int = fromY - PATHMAPRADIUS;
			var d:int = fromY + PATHMAPRADIUS;
			//shift it to the side if necessary
			if (l < 0)
			{
				l -= l;
				r -= l;
			}
			if (u < 0)
			{
				u -= u;
				d -= u;
			}
			if (r > width - 1)
			{
				var dif:uint = r - (width - 1);
				r -= dif;
				l -= dif;
			}
			if (d > height - 1)
			{
				dif = d - (height - 1);
				d -= dif;
				u -= dif;
			}
			//last-resort capping (for tiny maps, etc)
			if (l < 0)
				l = 0;
			if (u < 0)
				u = 0;
			if (r > width - 1)
				r = width - 1;
			if (d > height - 1)
				d = height - 1;
			
			var pMap:PathMap = new PathMap(l, r, u, d);
			pMap.exploreFrom(getI(fromX, fromY));
			return pMap;
		}
		
		public function saveCreatures(saveTo:Array, savePlayer:Boolean):void
		{
			for (var i:uint = 0; i < creaturesOrder.length; i++)
			{
				var cr:Creature = creaturesOrder[i];
				if (!cr.isPlayer || savePlayer)
					cr.save(saveTo);
			}
		}
		
		public function saveStairs(saveTo:Array):void
		{
			for (var i:uint = 0; i < stairs.length; i++)
				saveTo.push(stairs[i]);
		}
		
		public function loadStairs(loadFrom:Array):void
		{
			stairs = new Array();
			for (var i:uint = 0; i < loadFrom.length; i++)
				stairs.push(loadFrom[i]);
		}
		
		public function loadChests(loadFrom:Array):void
		{
			items = new Array();
			for (var i:uint = 0; i < width * height; i++)
				items.push(null);
				
			for (i = 0; i < loadFrom.length; )
			{
				var chestSize:uint = loadFrom[i++];
				var chest:Array = new Array();
				items[getI(loadFrom[i++], loadFrom[i++])] = chest;
				chest.push(loadFrom[i++]);
				for (var j:uint = 1; j < chestSize; j++)
				{
					var result:Array = Item.loadAny(loadFrom, i);
					chest.push(result[0]);
					i = result[1];
				}
			}
		}
		
		public function saveChests(saveTo:Array):void
		{
			for (var i:uint = 0; i < items.length; i++)
			{
				var chest:Array = items[i];
				if (chest)
				{
					saveTo.push(chest.length);
					saveTo.push(getX(i));
					saveTo.push(getY(i));
					saveTo.push(chest[0]);
					for (var j:uint = 1; j < chest.length; j++)
						Item.saveAny(saveTo, chest[j]);
				}
			}
		}
		
		public function saveTraps(saveTo:Array):void
		{
			for (var i:uint = 0; i < traps.length; i++)
			{
				var t:Trap = traps[i];
				if (t)
					t.save(saveTo);
			}
		}
		
		public function loadTraps(loadFrom:Array):void
		{
			traps = new Array();
			for (var i:uint = 0; i < width * height; i++)
				traps.push(null);
			for (i = 0; i < loadFrom.length; )
			{
				var result:Array = Trap.load(loadFrom, i);
				i = result[1];
				var t:Trap = result[0];
				traps[getI(t.x, t.y)] = t;
			}
		}
		
		public function trapAt(x:uint, y:uint):Boolean
		{
			return traps[getI(x, y)];
		}
		
		public function getTileEffectAt(x:uint, y:uint):uint
		{
			return (Main.data.tile[tiles[getI(x, y)]][8]);
		}
		
		public function triggerTrapAt(x:uint, y:uint):Trap
		{
			var t:Trap = traps[getI(x, y)];
			traps[getI(x, y)] = null;
			return t;
		}
		
		public function loadCreatures(loadFrom:Array):void
		{
			creaturesOrder = new Array();
			creatures = new Array();
			for (var i:uint = 0; i < width * height; i++)
				creatures.push(null);
			for (i = 0; i < loadFrom.length; )
			{
				var result:Array = Creature.load(loadFrom, i);
				var c:Creature = result[0];
				if (c.isPlayer)
					p = c as Player;
				creaturesOrder.push(c);
				creatures[getI(c.x, c.y)] = c;
				i = result[1];
			}
		}
		
		public function saveState(savePlayerTo:Array):void
		{
			p.savePlayerState(savePlayerTo);
		}
		
		public function loadState(loadPlayerFrom:Array):void
		{
			//all saving happens during the player turn, so it's always the players turn when you load
			if (!p)
				return; //can't do anything
			moving = p;
			p.turnStart(false);
			p.loadPlayerState(loadPlayerFrom);
		}
		
		public function loadTiles(loadTilesFrom:Array, loadBackgroundFrom:Array, loadExploredFrom:Array):void
		{
			tiles = new Array();
			background = new Array();
			explored = new Array();
			for (var i:uint = 0; i < width * height; i++)
			{
				tiles.push(loadTilesFrom[i]);
				background.push(loadBackgroundFrom[i]);
				explored.push(loadExploredFrom[i]);
			}
		}
		
		public function saveTiles(saveTilesTo:Array, saveBackgroundTo:Array, saveExploredTo:Array):void
		{
			for (var i:uint = 0; i < width * height; i++)
			{
				saveTilesTo.push(tiles[i]);
				saveBackgroundTo.push(background[i]);
				saveExploredTo.push(explored[i]);
			}
		}
		
		private function addCreature(x:uint, y:uint, cclass:uint, faction:uint, difficulty:uint, type:Class):void
		{
			var cr:Creature = new type(x, y, cclass, faction, difficulty, true) as Creature;
			creatures[getI(x, y)] = cr;
			creaturesOrder.push(cr);
			if (type == Player)
				p = cr as Player;
		}
		
		public function moveOver():void
		{
			moving = null;
			
			//remove any dead people
			var newCrOr:Array = new Array();
			var theresADead:Boolean = false;
			for (var i:uint = 0; i < creaturesOrder.length; i++)
			{
				var cr:Creature = creaturesOrder[i];
				if (!cr.dead)
					newCrOr.push(cr);
				else
				{
					theresADead = true;
					cr.messageUpdate(); //just in case
				}
			}
			creaturesOrder = newCrOr;
			if (theresADead) //don't bother looking if you didn't already find a dead person
				for (i = 0; i < creatures.length; i++)
				{
					cr = creatures[i];
					if (cr && cr.dead)
						creatures[i] = null;
				}
		}
		
		public function get player():Player { return p; }
		
		public override function update():void
		{
			pitEffectTimer += FP.elapsed;
			if (firstCenter >= 0)
				firstCenter += FP.elapsed * 20;
			if (firstCenter >= 1)
			{
				centerCamera(p.x, p.y);
				firstCenter = -1;
			}
			else if (!moving)
			{
				for (var i:uint = 0; i < creaturesOrder.length; i++)
				{
					var cr:Creature = creaturesOrder[i];
					if (cr && !cr.moved && !cr.skipTurn())
					{
						moving = cr;
						break;
					}
				}
				
				if (moving)
					moving.turnStart(true);
				else
					for (i = 0; i < creaturesOrder.length; i++)
						(creaturesOrder[i] as Creature).roundStart();
			}
			
			if (moving)
				moving.update();
			for (i = 0; i < creaturesOrder.length; i++)
				(creaturesOrder[i] as Creature).messageUpdate();
				
			super.update();
		}
		
		private function previewRender():void
		{
			for (var i:uint = 0; i < tiles.length; i++)
			{
				FP.buffer.fillRect(new Rectangle(getX(i) * 3, getY(i) * 3, 3, 3),
									Main.data.tile[tiles[i]][2]);
			}
		}
		
		public function chestHasOwnerXY(x:uint, y:uint):Boolean
		{
			for (var i:uint = 0; i < creaturesOrder.length; i++)
			{
				var cr:Creature = creaturesOrder[i];
				if (!cr.isPlayer)
				{
					var ai:AI = cr as AI;
					if (ai.myChest == getI(x, y))
						return true;
				}
			}
			return false;
		}
		
		public function removeChestAt(x:uint, y:uint):void
		{
			var chID:uint = items[getI(x, y)][0];
			if (chID >= ACCESSEDCHEST)
				chID -= ACCESSEDCHEST;
			if (Main.data.chest[chID][5] == 1)
				items[getI(x, y)] = null;
		}
		
		public function getChestAtI(i:uint):Array
		{
			var ch:Array = items[i];
			if (ch && ch.length > 1)
				return ch;
			else
				return null;
		}
		
		public function getChestAtXY(x:uint, y:uint):Array
		{
			return getChestAtI(getI(x, y));
		}
		
		public function makeChestAt(x:uint, y:uint, id:uint):Array
		{
			if (items[getI(x, y)])
				return items[getI(x, y)]; //it already exists
			var ch:Array = new Array();
			ch.push(id); //the type
			items[getI(x, y)] = ch;
			return ch;
		}
		
		private function getTileColor(x:uint, y:uint, id:uint):uint
		{
			if (squareIsVisible(x, y))
				return Main.data.tile[id][2];
			else if (Main.data.tile[id][3] == 1 && Main.data.tile[id][4] == 1)
				return 0x252525;
			else
				return 0x090909;
		}
		
		private function getTrueTile(x:uint, y:uint, id:uint):uint
		{
			if (explored[getI(x, y)])
				return id;
			else if (Main.data.tile[id][3] == 1 && Main.data.tile[id][4] == 1)
				return 5;
			else
				return 6;
		}
		
		private function renderTile(x:uint, y:uint, id:uint):void
		{
			if (id != Database.NONE)
			{
				id = getTrueTile(x, y, id);
				sprTile.frame = Main.data.tile[id][1];
				sprTile.color = getTileColor(x, y, id);
				sprTile.render(FP.buffer, new Point(x * TILESIZE, y * TILESIZE), FP.camera);
			}
		}
		
		private function renderPitEffect(x:uint, y:uint):void
		{
			if (pitEffect == Database.NONE)
				return;
			
			var i:uint = getI(x, y);
			if (!explored[i] || //cant see it
				(Main.data.tile[tiles[i]][7] != 0 &&
				(background[i] == Database.NONE || Main.data.tile[background[i]][7] != 0))) //not a pit
				return;
				
			sprPitEffect.offsetX = pitEffectTimer * Main.data.pitEffect[pitEffect][3];
			sprPitEffect.offsetY = pitEffect * Main.data.pitEffect[pitEffect][4];
			sprPitEffect.alpha = 0.5;
			sprPitEffect.frame = Main.data.pitEffect[pitEffect][1] * 2 + 1;
			if (squareIsVisible(x, y))
				sprPitEffect.color = Main.data.pitEffect[pitEffect][2];
			else
				sprPitEffect.color = 0x252525;
			
			
			sprPitEffect.render(FP.buffer, new Point(x * TILESIZE, (y + 0.5) * TILESIZE), FP.camera);
			
			if (y == 0 || Main.data.tile[tiles[getI(x, y - 1)]][7] != 2)
			{
				sprPitEffect.frame -= 1;
				sprPitEffect.render(FP.buffer, new Point(x * TILESIZE, y * TILESIZE), FP.camera);
			}
		}
		
		private function renderUpperTileInner(x:uint, y:uint, segments:uint, startC:uint, endC:uint, fr:uint, drawHT:Boolean):void
		{
			var factorStart:uint = 0;
			var tX:uint = fr % 4;
			var tY:uint = fr / 4;
			if (drawHT)
			{
				sprHalfTile.frame = tY * 8 + tX;
				sprHalfTile.color = startC;
				sprHalfTile.render(FP.buffer, new Point(x * TILESIZE, y * TILESIZE), FP.camera);
				factorStart = MAXSEGMENTS / 2;
			}
			for (var i:uint = factorStart; i < segments; i++)
			{
				sprQuarterTile.frame = tY * MAXSEGMENTS * 4 + tX + 4 * i;
				sprQuarterTile.color = FP.colorLerp(startC, endC, (i - factorStart) / (MAXSEGMENTS - factorStart));
				sprQuarterTile.render(FP.buffer, new Point(x * TILESIZE, (y + (i / MAXSEGMENTS)) * TILESIZE), FP.camera);
			}
		}
		
		private function renderUpperTile(x:uint, y:uint):Boolean
		{
			var upper:uint;
			var lower:uint;
			
			//determine which upper to use
			var frontU:uint = getTrueTile(x, y - 1, tiles[getI(x, y - 1)]);
			var backU:uint = Database.NONE;
			if (background[getI(x, y - 1)] != Database.NONE)
				backU = getTrueTile(x, y - 1, background[getI(x, y - 1)]);
			if (Main.data.tile[frontU][6] == Database.NONE && backU != Database.NONE)
				upper = backU;
			else
				upper = frontU;
				
			//determine which lower to use
			var frontL:uint = getTrueTile(x, y, tiles[getI(x, y)]);
			var backL:uint = Database.NONE;
			if (background[getI(x, y)] != Database.NONE)
				backL = getTrueTile(x, y, background[getI(x, y)]);
			if (Main.data.tile[frontL][6] == Database.NONE && backL != Database.NONE)
				lower = backL;
			else
				lower = frontL;
				
			var difference:int = Main.data.tile[upper][7] - Main.data.tile[lower][7];
				
			if (Main.data.tile[upper][6] != Database.NONE && difference > 0)
			{
				//translate it into its fronttile
				upper = Main.data.tile[upper][6];
				
				if (difference == 2)
					renderUpperTileInner(x, y, MAXSEGMENTS, FP.colorLerp(0, getTileColor(x, y, upper), LOWERDARKENFACTOR),
										0, Main.data.tile[upper][1], true);
				else
				{
					var darkenF:Number = LOWERDARKENFACTOR;
					if (Main.data.tile[upper][7] == 1)
						darkenF = LOWERDARKENFACTORHALF;
					var sC:uint = FP.colorLerp(0, getTileColor(x, y, upper), darkenF);
					renderUpperTileInner(x, y, MAXSEGMENTS / 2, sC, 0, Main.data.tile[upper][1], darkenF == LOWERDARKENFACTOR);
				}
				
				return true;
			}
			return false;
		}
		
		public function get someoneTargetingPlayer():Boolean
		{
			for (var i:uint = 0; i < creaturesOrder.length; i++)
			{
				var cr:Creature = creaturesOrder[i];
				if (!cr.isPlayer)
				{
					var ai:AI = cr as AI;
					if (ai.isTargetingPlayer())
						return true;
				}
			}
			return false;
		}
		
		public override function render():void
		{
			/**
			previewRender();
			return;
			/**/
			
			var xStart:uint = FP.camera.x / TILESIZE;
			var yStart:uint = FP.camera.y / TILESIZE;
			var xEnd:uint = xStart + FP.width / TILESIZE;
			var yEnd:uint = yStart + FP.height / TILESIZE;
			for (var y:uint = yStart; y < yEnd && y < height; y++)
				for (var x:uint = xStart; x < xEnd && x < width; x++)
				{
					if (squareIsVisible(x, y) || explored[getI(x, y)] || p.sonar)
					{
						var i:uint = getI(x, y);
						var drawOver:Boolean = Main.data.tile[tiles[i]][7] == 3;
						renderTile(x, y, background[i]);
						if (!drawOver)
							renderTile(x, y, tiles[i]);
							
						var dU:Boolean = false;
						
						//draw upper half tile if necessary
						if (y > 0)
							dU = renderUpperTile(x, y);
						
						//draw traps
						var t:Trap = traps[i];
						if (t && squareIsVisible(x, y))
							t.render(dU);
						
						//render pit effects
						renderPitEffect(x, y);
							
						if (drawOver && squareIsVisible(x, y))
							renderTile(x, y, tiles[i]);
						
						//draw chests
						var chest:Array = items[i];
						if (chest && squareIsVisible(x, y))
						{
							var chID:uint = chest[0];
							if (chID >= ACCESSEDCHEST)
								chID -= ACCESSEDCHEST;
							sprChest.frame = Main.data.chest[chID][1];
							if (Main.data.chest[chID][6] == 1 && chest[0] >= ACCESSEDCHEST)
								sprChest.frame += 1;
							sprChest.color = Main.data.chest[chID][2];
							sprChest.render(FP.buffer, new Point(x * TILESIZE, y * TILESIZE), FP.camera);
						}
					}
				}
				
			p.renderUnderInterface();
			
			for (y = yStart; y < yEnd && y < height; y++)
				for (x = xStart; x < xEnd && x < width; x++)
				{
					var cr:Creature = creatures[getI(x, y)];
					if (cr)
					{
						if (squareIsVisible(x, y))
							cr.render();
						else if (p.xray)
							cr.renderHeat();
					}
				}
			
			p.renderOverInterface();
			if (moving)
				moving.renderIcon();
			
			super.render();
		}
		
		public function placeTrap(type:uint, skill:uint, x:uint, y:uint):void
		{
			traps[getI(x, y)] = new Trap(type, skill, x, y);
		}
		
		private function recalculateVisible(x:uint, y:uint):void
		{
			//reset the array
			for (var i:uint = 0; i < visibleArray.length; i++)
				visibleArray[i] = false;
				
			//start from the desired camera center
			for (var oX:Number = FP.camera.x / TILESIZE; oX < (FP.camera.x + FP.width) / TILESIZE && oX < width; oX += 0.1)
			{
				visibleLine(x, y, oX, FP.camera.y / TILESIZE);
				visibleLine(x, y, oX, (FP.camera.y + FP.height) / TILESIZE);
			}
			for (var oY:Number = FP.camera.y / TILESIZE; oY < (FP.camera.y + FP.height) / TILESIZE && oY < height; oY += 0.1)
			{
				visibleLine(x, y, FP.camera.x / TILESIZE, oY);
				visibleLine(x, y, (FP.camera.x + FP.width) / TILESIZE, oY);
			}
		}
		
		private function visibleLine(xStart:uint, yStart:uint, xEnd:Number, yEnd:Number):void
		{
			var xDif:Number = xEnd - xStart;
			var yDif:Number = yEnd - yStart;
			var distance:Number = Math.sqrt(xDif * xDif + yDif * yDif);
			var xAdd:Number = xDif / distance;
			var yAdd:Number = yDif / distance;
			
			var x:Number = xStart;
			var y:Number = yStart;
			var hitWall:Boolean = false;
			
			distance += 1; //add extra allowance
			
			for (var j:uint = 0; j < distance; j++)
			{
				var rX:uint = Math.round(x);
				var rY:uint = Math.round(y);
				if (!onscreen(rX, rY))
					return;
				var isOp:Boolean = (rX != xStart || rY != yStart) &&
									Main.data.tile[tiles[getI(rX, rY)]][4] == 1;
				if (isOp && !hitWall)
					hitWall = true;
				else if (hitWall)
					return;
				visibleArray[toVisibleI(rX, rY)] = true;
				explored[getI(rX, rY)] = true;
				
				x += xAdd;
				y += yAdd;
			}
		}
		
		public function centerCamera(x:uint, y:uint):void
		{
			var newX:int = x - FP.halfWidth / TILESIZE;
			var newY:int = y - FP.halfHeight / TILESIZE;
			if (newX < 0)
				newX = 0;
			if (newY < 0)
				newY = 0;
			if (newX + (FP.width / TILESIZE) >= width)
				newX = width - (FP.width / TILESIZE);
			if (newY + (FP.height / TILESIZE) >= height)
				newY = height - (FP.height / TILESIZE);
			FP.camera.x = newX * TILESIZE;
			FP.camera.y = newY * TILESIZE;
		
			recalculateVisible(x, y);
		}
		
		//map generator
		private function generate(levelFrom:uint, faction:uint):void
		{
			//first, pick a map type
			_mapID = Main.data.mapType.length * Math.random();
			pitEffect = Main.data.mapType[_mapID][6];
			
			//how much should it shrink?
			var shrinkFactor:Number = 1 - (SHRINKPOTENTIAL * Math.random());
			
			//next, initialize the tile array
			width = Main.data.mapType[_mapID][10] * shrinkFactor;
			height = width;
			tiles = new Array();
			for (var i:uint = 0; i < width * height; i++)
				tiles.push(NOTILE);
			
			
			//next, define the shape of the terrain
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
				{
					var pick:uint = Math.random() * 2;
					if (y == 0 || x == 0 || y == height - 1 || x == width - 1)
						pick = 1; //this ensures that the edges are more rounded
					tiles[getI(x, y)] = pick;
				}
			
			//smooth it
			placeBars(0.1);
			for (i = 0; i < 3; i++)
			{
				placeBars(0.5);
				smooth(3);
			}
			fillHoles();
			
			//load up shopSquares
			var shopSquares:Array = new Array();
			for (i = 0; i < width * height; i++)
				shopSquares.push(0);
			
			//place rooms, and activate their features
			placeRooms(Main.data.mapType[_mapID][3], shopSquares);
			fillHoles();
			
			var prop:Number = proportion;
			trace(prop);
			if (prop < 0.70 || prop > 0.9)
			{
				//that was a bad generation; retry
				shopSquares = null;
				generate(levelFrom, faction);
				return;
			}
			
			//windows and furniture are a cosmetic feature, so you can put off adding them until after the proportion test
			placeFurniture();
			placeWindows();
			
			//next, recenter it properly
			shopSquares = recenter(shopSquares);
			//once you have recentered, initialize the background array
			background = new Array();
			for (i = 0; i < width * height; i++)
				background.push(Database.NONE);
			
			//next, make the texture array
			var shapeArray:Array = tiles;
			tiles = new Array();
			//this should be drawn in larger dots, to make it a bit chunkier
			for (i = 0; i < width * height; i++)
				tiles.push(0);
			for (y = 0; y < height + BRUSHSIZE; y += BRUSHSIZE)
				for (x = 0; x < width + BRUSHSIZE; x += BRUSHSIZE)
				{
					pick = Math.random() * METATILELISTLENGT;
					for (var y2:uint = y; y2 < y + BRUSHSIZE && y2 < height; y2++)
						for (var x2:uint = x; x2 < x + BRUSHSIZE && x2 < width; x2++)
							tiles[getI(x2, y2)] = pick;
				}
			
			for (i = 0; i < 5; i++)
				smooth(2);
				
			//finally, make the meta texture array
			var metaTiles:Array = Main.data.tilelist[Main.data.mapType[_mapID][1]];
			
			var textureArray:Array = tiles;
			tiles = new Array();
			for (i = 0; i < width * height; i++)
				tiles.push(0);
			for (y = 0; y < height + COARSEBRUSHSIZE; y += COARSEBRUSHSIZE)
				for (x = 0; x < width + COARSEBRUSHSIZE; x += COARSEBRUSHSIZE)
				{
					pick = Math.random() * (metaTiles.length - 1) + 1;
					for (y2 = y; y2 < y + COARSEBRUSHSIZE && y2 < height; y2++)
						for (x2 = x; x2 < x + COARSEBRUSHSIZE && x2 < width; x2++)
							tiles[getI(x2, y2)] = pick;
				}
			//also apply the fine brush
			for (i = 0; i < width * height; i++)
				if (Math.random() < FINEBRUSHCHANCE)
				{
					pick = Math.random() * (metaTiles.length - 1) + 1;
					tiles[i] = pick;
				}
			//smooth it
			for (i = 0; i < 5; i++)
				smooth(2);
			
			var furnitureList:Array = Main.data.tilelist[Main.data.mapType[_mapID][2]];
			
			//now combine these three arrays
			for (i = 0; i < width * height; i++)
			{
				var shape:uint = shapeArray[i];
				var drawTo:Array = tiles;
				var spots:Array = Main.data.tilelist[metaTiles[tiles[i]]];
				var toL:Boolean = false;
				if ((i % width) > 0)
					toL = Main.data.tile[tiles[i - 1]][3] == 1;
				
				if (shape == SHAPEDOOR)
				{
					if (toL)
						tiles[i] = 1; //hdoor
					else
						tiles[i] = 2; //vdoor
					drawTo = background;
					shape = SHAPEFLOOR;
				}
				else if (shape == SHAPEWINDOW)
				{
					if (toL)
						tiles[i] = 3; //hwindow
					else
						tiles[i] = 4; //vwindow
					drawTo = background;
					shape = SHAPEFLOOR;
				}
				else if (shape == SHAPEFURNITURE)
				{
					var furniturePick:uint = 1 + (furnitureList.length - 1) * Math.random();
					tiles[i] = furnitureList[furniturePick]; //chair
					drawTo = background;
					shape = SHAPEFLOOR;
				}
				
				if (shape >= SHAPEROOMSOLID)
					shape = SHAPESOLID; //turn it into a normal wall
				drawTo[i] = spots[1 + textureArray[i] * 2 + shape];
			}
			
			
			//free up memory
			shapeArray = null;
			textureArray = null;
			
			//now the basic terrain is done
			//place creatures, items, special features, etc
			
			//initialize the creatures arrays
			creatures = new Array();
			creaturesOrder = new Array();
			for (i = 0; i < width * height; i++)
				creatures.push(null);
				
			//initialize the item arrays
			items = new Array();
			for (i = 0; i < width * height; i++)
				items.push(null);
				
			//initialize the traps array
			traps = new Array();
			for (i = 0; i < width * height; i++)
				traps.push(null);
				
			//initialize the explored array
			explored = new Array();
			for (i = 0; i < width * height; i++)
				explored.push(false);
				
			//determine what the map's faction is
			_faction = faction;
			var conflict:Boolean = false;
			if (Math.random() < 0.3 && _levelNumber != 1)
			{
				_faction = 1 + Math.random() * (Main.data.faction.length - 1);
				if (_faction != faction && faction != 0 && Math.random() < 0.5)
					conflict = true;
			}
			
			//virtual skill array
			//to determine tier of placed items and traps
			var vSkills:Array = new Array();
			var vSkillProgress:Array = new Array();
			for (i = 0; i <= Creature.SKILLEQUIPTIER; i++)
			{
				vSkills.push(0);
				vSkillProgress.push(0);
			}
			Main.setSkillLevel(_difficulty * 1.1, Creature.SKILLEQUIPTIER, vSkills, vSkillProgress);
			Main.setSkillLevel(_difficulty, Creature.SKILLTRAPS, vSkills, vSkillProgress);
			
			//place shops before the feature positions go down
			placeShopFeatures(shopSquares, vSkills);
			
			//get feature positions
			var numStairs:uint = 2;
			if (Math.random() < 0.3)
				numStairs += 1;
			var numMonsters:uint = Math.round(Main.data.faction[_faction][3] * Main.data.mapType[_mapID][7] * 0.01 * shrinkFactor);
			var numDefenders:uint = Main.data.mapType[_mapID][9];
			var numChests:uint = Main.data.mapType[_mapID][4] * shrinkFactor;
			
			if (conflict)
				numMonsters *= 1.5; //since this is a conflict map it should have more monsters
			var positions:Array = getFeaturePositions(numStairs + numMonsters + numDefenders + numChests, shopSquares);
			
			//place the stairs
			stairs = new Array();
			for (i = 0; i < numStairs; i++)
			{
				if (i == 1)
				{
					//this is the staircase back
					//if you aren't from anywhere, don't actually put stairs here, since this is the first level
					
					if (levelFrom != 0)
					{
						stairs.push(levelFrom);
						stairs.push(positions[i]);
						tiles[positions[i]] = 0;
					}
				}
				else
				{
					//this is an unknown staircase
					stairs.push(0);
					stairs.push(positions[i]);
					tiles[positions[i]] = 0;
				}
			}
			
			//place the player
			loadPlayer(getX(positions[1]), getY(positions[1]));
			
			//place monster groups
			var creatureList1:Array = pickEncounterList(_faction);
			var creatureList2:Array = pickEncounterList(faction);
			for (i = numStairs; i < numMonsters + numStairs; i++)
			{
				//which faction/encounter table should you pick from?
				if (i == numStairs)
				{
					//boss encounter
					var bossTable:Array = Main.data.encountertable[creatureList1[1]];
					placeMonsterNear(positions[i], _faction, bossTable, _difficulty);
					generateChestAt(positions[i], vSkills[Creature.SKILLEQUIPTIER], BOSSEQUIPLOOT, Database.NONE);
				}
				if (i < (numMonsters / 2) + numStairs || !conflict)
					placeMonsterGroupAt(positions[i], _faction, creatureList1);
				else
					placeMonsterGroupAt(positions[i], faction, creatureList2);
			}
			
			//place defenders
			for (i = numMonsters + numStairs; i < numDefenders + numMonsters + numStairs; i++)
				placeMonsterNear(positions[i], _faction, [0, 0, Main.data.mapType[_mapID][8]], _difficulty);
			
			//place chests
			for (i = numDefenders + numMonsters + numStairs; i < numDefenders + numMonsters + numStairs + numChests; i++)
				generateChestAt(positions[i], vSkills[Creature.SKILLEQUIPTIER], Math.random() * 2, Database.NONE);
				
			//place traps
			placeTraps(vSkills[Creature.SKILLTRAPS], shopSquares, shrinkFactor);
		}
		
		private function placeTraps(trapDif:uint, shopSquares:Array, shrinkFactor:Number):void
		{
			var numTraps:uint = Main.data.faction[_faction][2];
			numTraps *= (1 - TRAPVARIATION + Math.random() * 2 * TRAPVARIATION) * shrinkFactor;
			var trapList:Array = Main.data.trapList[Main.data.faction[_faction][1]];
			for (var j:uint = 0; j < numTraps; )
			{
				var i:uint = Math.random() * width * height;
				if (spaceEmptyI(i) && !traps[i] && !items[i] && background[i] == Database.NONE && !staircaseAt(i) && shopSquares[i] == 0)
				{
					var trapPick:uint = 1 + Math.random() * (trapList.length - 1);
					placeTrap(trapList[trapPick], trapDif, getX(i), getY(i));
					j++;
				}
			}
		}
		
		public function hasLOS(from:Creature, to:Creature):Boolean
		{
			//a fast shortcut, using the visible array to immediately eliminate many situations
			if (from.isPlayer && !squareIsVisible(to.x, to.y))
				return false; //if the player is targeting, the enemy must be visible
			else if (to.isPlayer && !squareIsVisible(from.x, from.y))
				return false; //if the enemy is targeting the player, the player must be visible
			
			var xDif:int = to.x - from.x;
			var yDif:int = to.y - from.y;
			var dis:uint = Math.sqrt(xDif * xDif + yDif * yDif);
			var xAdd:Number = xDif / dis;
			var yAdd:Number = yDif / dis;
			
			var x:Number = from.x;
			var y:Number = from.y;
			for (var j:uint = 0; j < dis; j++)
			{
				var i:uint = getI(Math.round(x), Math.round(y));
				if (creatures[i] == from || creatures[i] == to || Main.data.tile[tiles[i]][5] == 0)
				{
					y += yAdd;
					x += xAdd;
				}
				else
					return false;
			}
			return true;
		}
		
		private function generateChestAt(i:uint, tier:uint, equipLoot:uint, fixedChest:uint):void
		{
			if (tier > Creature.MAXEQUIPTIER)
				tier = Creature.MAXEQUIPTIER;
			
			//pick the type, if not provided already
			var chestID:uint;
			if (fixedChest == Database.NONE)
			{
				chestID = 11 + (Main.data.mapType[_mapID].length - 11) * Math.random();
				chestID = Main.data.mapType[_mapID][chestID];
			}
			else
				chestID = fixedChest;
			
			//get the chest
			var chest:Array;
			if (!items[i])
			{
				//generate the chest
				chest = new Array();
				chest.push(chestID); //the type
				items[i] = chest; //place it down
			}
			else
				chest = items[i];
			
			var contents:Array = Main.getRandomitems(Main.data.chest[chestID][3],
										CHESTMIN + Math.random() * (CHESTMAX - CHESTMIN));
			for (var j:uint = 0; j < contents.length; j++)
				chestAdd(contents[j], chest);
			//maybe add some equipment
			for (var eq:uint = 0; eq < equipLoot; eq++)
			{
				//now pick a list to generate from
				var eqlootID:uint = Main.data.chest[chestID][4];
				if (eqlootID != Database.NONE) //some chests have no equipment loot
				{
					var eqloot:Array = Main.data.equiploot[eqlootID];
					var eqListPick:uint = Math.random() * ((eqloot.length - 1) / 2);
					var eqList:Array = Main.data.armortrack[eqloot[eqListPick * 2 + 1]];
					var variations:uint = eqList[1];
					var pickID:uint = Math.random() * variations + 2 + variations * tier;
					pickID = eqList[pickID];
					if (eqloot[eqListPick * 2 + 2] == 0)
					{
						var wep:Weapon = new Weapon(pickID);
						if (!wep.unlisted)
							chestAdd(wep, chest);
					}
					else
					{
						var arm:Armor = new Armor(pickID);
						if (!arm.unlisted)
							chestAdd(arm, chest);
					}
				}
			}
			if (Math.random() < 0.01 * Main.data.chest[chestID][7])
			{
				//generate a random human-valid augment
				while (true)
				{
					var augID:uint = Math.random() * Main.data.augment.length;
					if (Main.data.augmentType[Main.data.augment[augID][4]][1] == 1)
					{
						chestAdd(new Augment(augID), chest);
						break;
					}
				}
			}
		}
		
		private function placeMonsterGroupAt(i:uint, factionPick:uint, creatureList:Array):void
		{
			var numMonsters:uint;
			if (Math.random() < 0.5)
				numMonsters = 1;
			else
				numMonsters = MONSTERGROUPMINNUMBER + (MONSTERGROUPMAXNUMBER - MONSTERGROUPMINNUMBER) * Math.random();
				
			for (var j:uint = 0; j < numMonsters; j++)
				placeMonsterNear(i, factionPick, creatureList, _difficulty);
		}
		
		private function placeMonsterNear(i:uint, factionPick:uint, creatureList:Array, difficulty:uint):void
		{
			for (var j:uint = 0; j < 100; j++)
			{
				var x:uint = getX(i);
				var y:uint = getY(i);
				if (x > MONSTERGROUPSIZE)
					x -= MONSTERGROUPSIZE;
				else
					x = 0;
				if (y > MONSTERGROUPSIZE)
					y -= MONSTERGROUPSIZE;
				else
					y = 0;
				x += Math.random() * 2 * MONSTERGROUPSIZE;
				y += Math.random() * 2 * MONSTERGROUPSIZE;
				if (x >= width)
					x = width - 1;
				if (y >= height)
					y = height - 1;
				
				if (spaceEmptyXY(x, y))
					while (true)
					{
						var type:uint = (creatureList.length - 2) * Math.random() + 2;
						type = creatureList[type];
						if (Main.data.cclass[type][12] + Main.STARTLEVEL <= _difficulty) //min difficulty is relative to startlevel
						{
							//the difficulty is high enough to spawn it
							addCreature(x, y, type, factionPick, _difficulty, AI);
							return;
						}
					}
			}
		}
		
		private function pickEncounterList(faction:uint):Array
		{
			var fl:Array = Main.data.faction[faction];
			var pick:uint = 4 + Math.random() * (fl.length - 4);
			return Main.data.encountertable[fl[pick]];
		}
		
		public function onscreen(x:uint, y:uint):Boolean
		{
			return x >= FP.camera.x / TILESIZE &&
					y >= FP.camera.y / TILESIZE &&
					x < (FP.camera.x + FP.width) / TILESIZE &&
					y < (FP.camera.y + FP.height) / TILESIZE;
		}
		
		private function placeBars(factor:Number):void
		{
			var numBars:uint = 1 + width * height * 0.0015 * (0.5 + Math.random());
			for (var i:uint = 0; i < numBars; i++)
			{
				//get the material
				var material:uint = Math.random() * 2;
				
				//get the dimensions
				var w:uint = Math.random() * Math.random() * width;
				var h:uint = Math.random() * Math.random() * height;
				var xS:uint = Math.random() * (width - w);
				var yS:uint = Math.random() * (height - h);
				
				//place it
				var x:Number = xS;
				var y:Number = yS;
				var distance:Number = Math.sqrt(w * w + h * h);
				var xAdd:Number = w / distance;
				var yAdd:Number = h / distance;
				for (var j:uint = 0; j < distance; j++)
				{
					x += xAdd;
					y += yAdd;
					if (Math.random() < factor)
						tiles[getI(x, y)] = material;
				}
			}
		}
		
		private function get proportion():Number
		{
			var numSolid:uint = 0;
			var numFloor:uint = 0;
			for (var i:uint = 0; i < width * height; i++)
			{
				if (tiles[i] == 1)
					numSolid += 1;
				else
					numFloor += 1;
			}
			
			return numSolid * 1.0 / (numFloor + numSolid);
		}
		
		private function fillHoles():void
		{
			var explored:Array = new Array();
			for (var i:uint = 0; i < width * height; i++)
				explored.push(false);
			
			//find all of the pockets/groups
			var groups:Array = new Array();
			for (i = 0; i < width * height; i++)
			{
				if (!explored[i] && tiles[i] == 0)
					pocketExploreStart(i, explored, groups);
			}
			
			//find the largest group
			var largestGroup:Array = null;
			for (i = 0; i < groups.length; i++)
			{
				var group:Array = groups[i];
				if (largestGroup == null || group.length > largestGroup.length)
					largestGroup = group;
			}
			
			//fill in all other groups
			for (i = 0; i < groups.length; i++)
			{
				group = groups[i];
				if (group != largestGroup)
					for (var j:uint = 0; j < group.length; j++)
						tiles[group[j]] = 1;
			}
		}
		
		private function pocketExploreStart(startI:uint, explored:Array, groups:Array):void
		{
			var group:Array = new Array();
			
			var iQ:Array = new Array();
			group.push(startI);
			iQ.push(startI);
			explored[startI] = true;
			
			while (iQ.length > 0)
				pocketExplore(iQ, explored, group);
			
			groups.push(group);
		}
		
		private function pocketExplore(iQ:Array, explored:Array, group:Array):void
		{
			var i:uint = iQ.pop();
			var x:uint = getX(i);
			var y:uint = getY(i);
			pocketExploreOne(x, y, 0, -1, iQ, explored, group);
			pocketExploreOne(x, y, 0, 1, iQ, explored, group);
			pocketExploreOne(x, y, -1, 0, iQ, explored, group);
			pocketExploreOne(x, y, 1, 0, iQ, explored, group);
		}
		
		private function pocketExploreOne(oX:uint, oY:uint, xDir:int, yDir:int, iQ:Array, explored:Array, group:Array):void
		{
			var x:int = oX + xDir;
			var y:int = oY + yDir;
			if (x < 0 || y < 0 || x >= width || y >= height)
				return;
			var i:uint = getI(x, y);
			if (explored[i] || tiles[i] == SHAPESOLID || tiles[i] == SHAPEDEPLETEDROOMSOLID)
				return;
			if (tiles[i] == SHAPEROOMSOLID)
			{
				if (tiles[getI(x + xDir, y + yDir)] == 0 && tiles[getI(oX, oY)] == 0)
					placeDoor(x, y, xDir, yDir, iQ, explored, group);
				return; //quit whether or not you can place a door
			}
			group.push(i);
			explored[i] = true;
			iQ.push(i);
		}
		
		private function placeDoor(x:uint, y:uint, xDir:int, yDir:int, iQ:Array, explored:Array, group:Array):void
		{
			var xEx:int = 0;
			var yEx:int = 0;
			if (xDir != 0)
				yEx = 1;
			else
				xEx = 1;
			
			var possibilities:Array = new Array();
			for (var j:uint = 0; j < 2; j++)
			{
				//explore one direction
				var xOn:uint = x;
				var yOn:uint = y;
				while (true)
				{
					if (xOn == 0 || yOn == 0 || xOn == width - 1 || yOn == height - 1)
						break;
					else
					{
						var l:uint = tiles[getI(xOn + xDir, yOn + yDir)];
						var r:uint = tiles[getI(xOn - xDir, yOn - yDir)];
						var c:uint = tiles[getI(xOn, yOn)];
						var f:uint = tiles[getI(xOn + xEx, yOn + yEx)];
						var b:uint = tiles[getI(xOn - xEx, yOn - yEx)];
						if (c == SHAPEROOMSOLID && f == SHAPEROOMSOLID && b == SHAPEROOMSOLID && r == 0 && l == 0)
							possibilities.push(getI(xOn, yOn));
						else
							break;
					}
					xOn += xEx;
					yOn += yEx;
				}
				
				//explore the next way next time
				xEx *= -1;
				yEx *= -1;
			}
			
			for (var i:uint = 0; i < possibilities.length; i++)
				tiles[possibilities[i]] = SHAPEDEPLETEDROOMSOLID; //deplete wall
			
			var pick:uint = possibilities.length * Math.random();
			pick = possibilities[pick];
			tiles[pick] = SHAPEDOOR; //add a door
			pocketExploreOne(getX(pick), getY(pick), 0, 0, iQ, explored, group);
		}
		
		private function placeFurniture():void
		{
			var numFurniture:uint = Main.data.mapType[_mapID][5];
			for (var j:uint = 0; j < numFurniture; j++)
			{
				for (var k:uint = 0; k < FLOORFAILS;)
				{
					var x:uint = Math.random() * (width - 2) + 1;
					var y:uint = Math.random() * (height - 2) + 1;
					
					if (tiles[getI(x, y)] == SHAPEFLOOR)
					{
						k++;
						var nearAr:Array = [
							tiles[getI(x - 1, y - 1)],
							tiles[getI(x, y - 1)],
							tiles[getI(x + 1, y - 1)],
							tiles[getI(x + 1, y)],
							tiles[getI(x + 1, y + 1)],
							tiles[getI(x, y + 1)],
							tiles[getI(x - 1, y + 1)],
							tiles[getI(x - 1, y)]];
							
						if (checkNearArForFurniture(nearAr, 0))
						{
							tiles[getI(x, y)] = SHAPEFURNITURE;
							break;
						}
					}
				}
			}
		}
		
		private function checkNearArForFurniture(nearAr:Array, rotation:uint):Boolean
		{
			if (rotation == 8)
				return false;
			var arOn:uint = rotation;
			var checkOn:uint = 0;
			var strikes:uint = 0;
			do
			{
				if ((checkOn < 3 && nearAr[arOn] != SHAPESOLID && nearAr[arOn] < SHAPEROOMSOLID) ||
					(checkOn >= 3 && nearAr[arOn] != SHAPEFLOOR))
					strikes++;
				if (strikes == 2)
					return checkNearArForFurniture(nearAr, rotation + 2);
				
				checkOn += 1;
				arOn += 1;
				if (arOn == nearAr.length)
					arOn = 0;
			}
			while (arOn != rotation)
			
			return true;
		}
		
		private function placeWindows():void
		{
			var possibilities:Array = new Array();
			for (var y:uint = 1; y < height - 1; y++)
				for (var x:uint = 1; x < width - 1; x++)
				{
					var c:uint = tiles[getI(x, y)];
					if (c >= SHAPEROOMSOLID)
					{
						var u:uint = tiles[getI(x, y - 1)];
						var d:uint = tiles[getI(x, y + 1)];
						var l:uint = tiles[getI(x - 1, y)];
						var r:uint = tiles[getI(x + 1, y)];
						if ((u == 0 && d == 0 && l >= SHAPEROOMSOLID && r >= SHAPEROOMSOLID) ||
							(l == 0 && r == 0 && u >= SHAPEROOMSOLID && d >= SHAPEROOMSOLID))
							possibilities.push(getI(x, y));
					}
				}
			for (var i:uint = 0; i < possibilities.length; i++)
				if (Math.random() < WINDOWCHANCE)
					tiles[possibilities[i]] = SHAPEWINDOW;
		}
		
		private function recenter(shopSquares:Array):Array
		{
			//find the dimensions
			var xStart:uint = width;
			var yStart:uint = height;
			var xEnd:uint = 0;
			var yEnd:uint = 0;
			
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
				{
					if (tiles[getI(x, y)] == 0)
					{
						if (x < xStart)
							xStart = x;
						if (y < yStart)
							yStart = y;
						if (x > xEnd)
							xEnd = x;
						if (y > yEnd)
							yEnd = y;
					}
				}
				
			var newWidth:uint = xEnd - xStart + 1 + BORDERSIZE * 2;
			var newHeight:uint = yEnd - yStart + 1 + BORDERSIZE * 2;
			
			//make the new tiles array
			var newTiles:Array = new Array();
			var newShopSquares:Array = new Array();
			for (var i:uint = 0; i < newWidth * newHeight; i++)
			{
				newTiles.push(1);
				newShopSquares.push(0);
			}
			
			for (y = yStart; y <= yEnd; y++)
				for (x = xStart; x <= xEnd; x++)
				{
					var newI:uint = (x + BORDERSIZE - xStart) + (y + BORDERSIZE - yStart) * newWidth;
					newTiles[newI] = tiles[getI(x, y)];
					newShopSquares[newI] = shopSquares[getI(x, y)];
				}
			
			tiles = newTiles;
			width = newWidth;
			height = newHeight;
			return newShopSquares;
		}
		
		private function smooth(neighborsNeeded:uint):void
		{
			for (var i:uint = 0; i < width * height; i++)
			{
				var x:uint = getX(i);
				var y:uint = getY(i);
				
				var neighbors:Array = new Array();
				if (x > 0)
					neighbors.push(tiles[getI(x - 1, y)]);
				if (x < width - 1)
					neighbors.push(tiles[getI(x + 1, y)]);
				if (y > 0)
					neighbors.push(tiles[getI(x, y - 1)]);
				if (y < height - 1)
					neighbors.push(tiles[getI(x, y + 1)]);
				
				var difNeighbors:uint = 0;
				for (var j:uint = 0; j < neighbors.length; j++)
				{
					if (neighbors[j] != tiles[i])
						difNeighbors += 1;
				}
				
				if (difNeighbors >= neighborsNeeded)
				{
					var pick:uint = Math.random() * neighbors.length;
					tiles[i] = neighbors[pick];
				}
			}
		}
		
		private function chestAdd(it:Item, chest:Array):void
		{
			if (it.category == 2)
			{
				//check to see if there's conflicts
				var st:Stackable = it as Stackable;
				for (var i:uint = 1; i < chest.length; i++)
				{
					if ((chest[i] as Item).category == 2)
					{
						var st2:Stackable = (chest[i]) as Stackable;
						if (st2.id == st.id)
						{
							st2.combine(st);
							return;
						}
					}
				}
			}
			
			chest.push(it); //just add it
		}
		
		private function placeShopFeatures(shopSquares:Array, vSkills:Array):void
		{
			var shops:Array = new Array();
			
			for (var i:uint = 0; i < width * height; i++)
			{
				var s:uint = shopSquares[i];
				if (s != 0 && spaceEmptyI(i))
				{
					if (!shops[s - 1])
						shops[s - 1] = new Array();
					shops[s - 1].push(i);
				}
			}
			
			//now populate the shops
			for (s = 0; s < shops.length; s++)
			{
				if (shops[s])
				{
					//pick the merchant type
					var merchantType:uint = Math.random() * Main.data.merchantType.length;
					
					//place the merchant's chest
					var chest:uint = pickShopFreeArea(shops[s], true);
					var merchFailed:Boolean = false;
					var guardFailed:Boolean = false;
					
					//place the merchant
					var merchantI:uint = pickShopFreeArea(shops[s], true);
					if (merchantI != 0)
					{
						addCreature(getX(merchantI), getY(merchantI), Main.data.merchantType[merchantType][1], 0, _difficulty, AI);
						(creatures[merchantI] as AI).myChest = chest;
					}
					else
						merchFailed = true;
					
					if (!merchFailed)
					{
						//place the merchants guards
						var numGuards:uint = Main.data.merchantType[merchantType][3];
						numGuards = Math.random() * (Main.data.merchantType[merchantType][4] - numGuards) + numGuards;
						for (j = 0; j < numGuards; j++)
						{
							var guardI:uint = pickShopFreeArea(shops[s], true);
							if (guardI != 0)
								addCreature(getX(guardI), getY(guardI), Main.data.merchantType[merchantType][2], 0, _difficulty, AI);
							else
								guardFailed = true;
						}
					}
					
					//populate the merchant's chest
					var chestsLeft:uint = Main.data.merchantType[merchantType].length;
					if (merchFailed)
						chestsLeft = 1; //if no merchant generated, just pretend this is a normal chest
					else if (guardFailed)
						chestsLeft = 2; //if its a merchant with missing guards, give them a severely reduced stock
					for (var j:uint = 6; j < Main.data.merchantType[merchantType].length && chestsLeft > 0; j++)
					{
						generateChestAt(chest, vSkills[Creature.SKILLEQUIPTIER], MERCHANTEQUIPLOOT, Main.data.merchantType[merchantType][j]);
						chestsLeft -= 1;
					}
					
					//place furniture
					var furnitureList:Array = Main.data.tilelist[Main.data.merchantType[merchantType][5]];
					for (var furnitureFails:uint = 0; furnitureFails < FLOORFAILS; furnitureFails++)
					{
						var furnI:uint = pickShopFreeArea(shops[s], false);
						if (furnI != 0)
						{
							var x:uint = getX(furnI);
							var y:uint = getY(furnI);
							var nearAr:Array = [
								tiles[getI(x - 1, y - 1)],
								tiles[getI(x, y - 1)],
								tiles[getI(x + 1, y - 1)],
								tiles[getI(x + 1, y)],
								tiles[getI(x + 1, y + 1)],
								tiles[getI(x, y + 1)],
								tiles[getI(x - 1, y + 1)],
								tiles[getI(x - 1, y)]];
							if (background[furnI] == Database.NONE && checkNearArForFurniture(nearAr, 0))
							{
								background[furnI] = tiles[furnI];
								var pick:uint = 1 + Math.random() * (furnitureList.length - 1);
								tiles[furnI] = furnitureList[pick];
							}
						}
					}
				}
			}
		}
		
		private function pickShopFreeArea(shop:Array, noBorder:Boolean):uint
		{
			for (var j:uint = 0; j < FLOORFAILS; j++)
			{
				var i:uint = shop.length * Math.random();
				i = shop[i];
				
				
				if (spaceEmptyI(i) &&
					(!noBorder || (spaceTotallyEmptyI(i - 1) && spaceTotallyEmptyI(i + 1) &&
					spaceTotallyEmptyI(i - width) && spaceTotallyEmptyI(i + width))) &&
					items[i] == null)
					return i;
			}
			return 0;
		}
		
		private function spaceTotallyEmptyI(i:uint):Boolean
		{
			return spaceEmptyI(i) && background[i] == Database.NONE;
		}
		
		private function placeRooms(numRooms:uint, shopSquares:Array):void
		{
			var numShops:uint = 2;
			
			for (var i:uint = 0; i < numRooms + numShops;)
			{
				var shop:Boolean = i < numShops;
				var rW:uint = MINROOMSIZE + (MAXROOMSIZE - MINROOMSIZE) * Math.random();
				var rH:uint = MINROOMSIZE + (MAXROOMSIZE - MINROOMSIZE) * Math.random();
				if (shop)
				{
					rW = SHOPSIZE;
					rH = SHOPSIZE;
				}
				var x:uint = 2 + (width - rW - 4) * Math.random();
				var y:uint = 2 + (height - rH - 4) * Math.random();
				
				var valid:Boolean = false;
				var ruined:Boolean = false;
				
				//check the area to see if its good
				for (var y2:uint = y + 1; !ruined && !valid && y2 < y + rH - 1; y2++)
					for (var x2:uint = x + 1; !ruined && !valid && x2 < x + rW - 1; x2++)
					{
						if (shopSquares[getI(x2, y2)] != 0)
							ruined = true;
						else if (tiles[getI(x2, y2)] == SHAPEFLOOR)
							valid = true;
					}
				
				if (valid)
				{
					if (shop)
					{
						//clear out the floor
						for (y2 = y + 1; y2 < y + rH - 1; y2++)
							for (x2 = x + 1; x2 < x + rW - 1; x2++)
							{
								tiles[getI(x2, y2)] = SHAPEFLOOR;
								shopSquares[getI(x2, y2)] = i + 1; //mark this as a shop square
							}
					}
					
					for (var j:uint = 0; j < rW; j++)
					{
						tiles[getI(x + j, y)] = SHAPEROOMSOLID;
						tiles[getI(x + j, y + rH - 1)] = SHAPEROOMSOLID;
					}
					
					for (j = 0; j < rH; j++)
					{
						tiles[getI(x, y + j)] = SHAPEROOMSOLID;
						tiles[getI(x + rW - 1, y + j)] = SHAPEROOMSOLID;
					}
					
					i++;
				}
			}
		}
		
		private function getFeaturePositions(numFeatures:uint, shopSquares:Array):Array
		{
			var positions:Array = new Array();
			
			//to start, pick a random open spot
			while (true)
			{
				var i:uint = Math.random() * width * height;
				if (spaceEmptyI(i))
				{
					positions.push(i);
					break;
				}
			}
			
			while (positions.length < numFeatures)
			{
				var furthest:uint = 0;
				var furthestD:uint;
				for (i = width; i < width * height; i++)
				{
					var upper:uint = Main.data.tile[tiles[i - width]][6];
					if (spaceEmptyI(i) && Main.data.tile[tiles[i]][4] == 0 && //it can't be solid or opaque
						shopSquares[i] == 0 && //it can't be inside a shop
						background[i] == Database.NONE && //can't be in a tile with a background (IE a door or a chair)
						(upper == Database.NONE || upper == 0 || upper == 1)) //the tile above it must have no upper bit
					{
						//get the distance to the closest staircase
						var d:uint;
						for (var j:uint = 0; j < positions.length; j++)
						{
							var thisD:uint =
								Math.abs(getX(positions[j]) - getX(i)) +
								Math.abs(getY(positions[j]) - getY(i));
							if (j == 0 || thisD < d)
								d = thisD;
						}
						
						//is this distance longer than the previous best?
						if (furthest == 0 || furthestD < d)
						{
							furthest = i;
							furthestD = d;
						}
					}
				}
				
				//now place a staircase there!
				positions.push(furthest);
			}
			
			return positions;
		}
	}

}