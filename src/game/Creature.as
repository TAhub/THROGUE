package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.FP;
	
	public class Creature 
	{
		//SKILL CONSTANTS
		private static var SKILLCONSTON:uint = 0;
		public static const SKILLDODGE:uint = SKILLCONSTON++;
		public static const SKILLBLOCK:uint = SKILLCONSTON++;
		public static const SKILLBLADE:uint = SKILLCONSTON++;
		public static const SKILLBLUNT:uint = SKILLCONSTON++;
		public static const SKILLMANUAL:uint = SKILLCONSTON++;
		public static const SKILLAUTOMATIC:uint = SKILLCONSTON++;
		public static const SKILLBEAM:uint = SKILLCONSTON++;
		public static const SKILLROCKET:uint = SKILLCONSTON++;
		public static const SKILLDISRUPTOR:uint = SKILLCONSTON++;
		public static const SKILLUNARMED:uint = SKILLCONSTON++;
		public static const SKILLMENDING:uint = SKILLCONSTON++;
		public static const SKILLTRAPS:uint = SKILLCONSTON++;
		public static const SKILLTRADE:uint = SKILLCONSTON++;
		public static const SKILLFLESHCRAFT:uint = SKILLCONSTON++;
		public static const SKILLMECHCRAFT:uint = SKILLCONSTON++;
		public static const SKILLARMORCRAFT:uint = SKILLCONSTON++;
		public static const SKILLSPECIALATTACK:uint = SKILLCONSTON++;
		public static const SKILLEQUIPTIER:uint = SKILLCONSTON++;
		
		public static const MAXEQUIPTIER:uint = 5;
		private static const MONSTERAUGCHANCE:Number = 0.5;
		
		//ITEM/COMBAT CONSTANTS
		private static const RANDOMITEMS:uint = 2;
		public static const T0PENALTY:Number = 0.65;
		private static const PLAYERRESISTANCE:Number = 0.60;
		private static const WEAPONDROPCHANCE:Number = 0.3;
		
		
		[Embed(source = "sprites/hair.png")] private static const HAIR:Class;
		[Embed(source = "sprites/parts.png")] private static const PARTS:Class;
		[Embed(source = "sprites/wideparts.png")] private static const WIDEPARTS:Class;
		[Embed(source = "sprites/icons.png")] private static const ICONS:Class;
		protected static const ICONSIZE:uint = 20;
		private static const ICONHEIGHT:uint = 25;
		private static const PARTSIZE:uint = 15;
		private static const WIDEPARTWIDTH:uint = 40;
		private static const HAIRWIDTH:uint = 12;
		private static const HAIRHEIGHT:uint = 36;
		private static const HAIRX:uint = 14;
		private static const HAIRY:uint = 4;
		private static const WEPYADD:uint = 6;
		private static const sprParts:Spritemap = new Spritemap(PARTS, PARTSIZE, PARTSIZE);
		private static const sprWideParts:Spritemap = new Spritemap(WIDEPARTS, WIDEPARTWIDTH, PARTSIZE);
		private static const sprHair:Spritemap = new Spritemap(HAIR, HAIRWIDTH, HAIRHEIGHT);
		protected static const sprIcons:Spritemap = new Spritemap(ICONS, ICONSIZE, ICONSIZE);
		
		private var _name:String;
		private var _faction:uint;
		private var _cclass:uint;
		private var morph:uint;
		private var specialAttack:uint;
		private var genderAdd:uint;
		protected var skills:Array;
		protected var skillProgress:Array;
		protected var canLevel:Boolean;
		protected var _isPlayer:Boolean;
		protected var armors:Array;
		protected var weapons:Array;
		protected var aug:Augment;
		private var wepSlots:Array;
		protected var pack:Array;
		private var _x:uint;
		private var _y:uint;
		private var _moved:Boolean;
		private var _dead:Boolean;
		
		//player-only stats
		private var satiation:uint;
		private var hydration:uint;
		
		//color
		private var skinColor:uint;
		private var eyeColor:uint;
		private var hairColor:uint;
		private var hairNumber:uint;
		public static const NUMHAIRSTYLES:uint = 3;
		
		//animation
		private var rumble:String;
		private var animLeft:Number = 0;
		private var animIcon:uint;
		private var animHitting:Creature;
		private var trapHit:Trap;
		private var animAttOn:uint;
		private var animSlow:Boolean;
		private var animSpecial:Boolean;
		private var animMissMessage:String;
		private static const ANIMLENGTH:Number = 0.3;
		private static const RUMBLEPOWER:uint = 2;
		private static const DODGERUMBLEPOWER:uint = 6;
		private static const MISSRUMBLEPOWER:uint = 1;
		private static const ATTACKRUMBLEPOWER:uint = 1;
		private static const MISSEDMESSAGE:String = "MISSED!";
		private static const DODGEDMESSAGE:String = "DODGED!";
		private static const HITMESSAGE:String = "HIT!";
		private static const ATTACKMESSAGE:String = "ATTACK!";
		private static const TRAPMESSAGE:String = "TRAP!";
		
		//status effect information
		private var stunnedMessage:String;
		private var poisonDamage:uint;
		private var poisonDuration:uint;
		private static const STUNNEDGRAPPLEMESSAGE:String = "GRAPPLED!";
		private static const STUNNEDTRAPMESSAGE:String = "TRAPPED!";
		private static const BASEPOISON:uint = 8;
		private static const POISONLENGTH:uint = 5;
		private static const EXPLOSIONGRANULARITY:uint = 3;
		
		//hunger/thirst constants
		private static const STARTSATIATION:uint = 1000;
		private static const BLOATEDSATIATION:uint = 2000;
		private static const MAXSATIATION:uint = 2400;
		private static const HUNGRYSATIATION:uint = 500;
		private static const HUNGERRATE:uint = 2;
		
		
		//message array values
		private var messageArrayTimer:Number = 0;
		private static const MESSAGEARRAYTIME:Number = 0.3;
		private var lastTotalHealth:uint;
		
		public function save(toArray:Array):void
		{
			//general traits
			toArray.push(isPlayer);
			if (isPlayer)
			{
				toArray.push(satiation);
				toArray.push(hydration);
				toArray.push(_name);
			}
			else
			{
				toArray.push((this as AI).myChest);
			}
			toArray.push(_x);
			toArray.push(_y);
			toArray.push(_cclass);
			toArray.push(_faction);
			toArray.push(genderAdd);
			toArray.push(skinColor);
			toArray.push(eyeColor);
			toArray.push(hairColor);
			toArray.push(hairNumber);
			toArray.push(poisonDamage);
			toArray.push(poisonDuration);
			toArray.push(stunnedMessage);
			
			//ordering information
			toArray.push(_moved);
			
			//skills
			toArray.push(skills.length);
			for (var i:uint = 0; i < skills.length; i++)
			{
				toArray.push(skills[i]);
				if (isPlayer)
					toArray.push(skillProgress[i]);
			}
			
			//armors
			toArray.push(armors.length);
			for (i = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (arm)
				{
					toArray.push(true);
					arm.save(toArray);
				}
				else
					toArray.push(false);
			}
			
			//weapons
			toArray.push(weapons.length);
			for (i = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep)
				{
					toArray.push(true);
					wep.save(toArray);
				}
				else
					toArray.push(false);
			}
			
			//pack
			toArray.push(pack.length);
			for (i = 0; i < pack.length; i++)
				Item.saveAny(toArray, pack[i]);
				
			//augment
			if (aug)
			{
				toArray.push(true);
				aug.save(toArray);
			}
			else
				toArray.push(false);
		}
		
		public static function load(fromArray:Array, on:uint):Array
		{
			var result:Array = new Array();
			
			var c:Creature;
			var iP:Boolean;
			if (fromArray[on++])
			{
				c = new Player(0, 0, 0, 0, 0, false);
				iP = true;
			}
			else
			{
				c = new AI(0, 0, 0, 0, 0, false);
				iP = false;
			}
				
			result.push(c);
			result.push(c.loadFrom(fromArray, on, iP));
			
			return result;
		}
		
		public function loadFrom(fromArray:Array, on:uint, iP:Boolean):uint
		{
			//general traits
			if (iP)
			{
				satiation = fromArray[on++];
				hydration = fromArray[on++];
				_name = fromArray[on++];
			}
			else
			{
				(this as AI).myChest = fromArray[on++];
			}
			_x = fromArray[on++];
			_y = fromArray[on++];
			_cclass = fromArray[on++];
			_faction = fromArray[on++];
			genderAdd = fromArray[on++];
			skinColor = fromArray[on++];
			eyeColor = fromArray[on++];
			hairColor = fromArray[on++];
			hairNumber = fromArray[on++];
			poisonDamage = fromArray[on++];
			poisonDuration = fromArray[on++];
			stunnedMessage = fromArray[on++];
			
			//ordering information
			_moved = fromArray[on++];
			
			derive1();
			
			//skills
			skills = new Array();
			if (isPlayer)
				skillProgress = new Array();
			var numSkills:uint = fromArray[on++];
			for (var i:uint = 0; i < numSkills; i++)
			{
				skills.push(fromArray[on++]);
				if (isPlayer)
					skillProgress.push(fromArray[on++]);
			}
			
			//armors
			armors = new Array();
			var numArmors:uint = fromArray[on++];
			for (i = 0; i < numArmors; i++)
			{
				if (fromArray[on++])
				{
					var result:Array = Armor.load(fromArray, on);
					armors.push(result[0]);
					on = result[1];
				}
				else
					armors.push(null);
			}
			
			derive2();
			
			//weapons
			weapons = new Array();
			var numWeapons:uint = fromArray[on++];
			for (i = 0; i < numWeapons; i++)
			{
				if (fromArray[on++])
				{
					result = Weapon.load(fromArray, on);
					weapons.push(result[0]);
					on = result[1];
				}
				else
					weapons.push(null);
			}
			
			//pack
			pack = new Array();
			var numPackItems:uint = fromArray[on++];
			for (i = 0; i < numPackItems; i++)
			{
				result = Item.loadAny(fromArray, on);
				pack.push(result[0]);
				on = result[1];
			}
			
			//load augment
			if (fromArray[on++])
			{
				result = Augment.load(fromArray, on);
				aug = result[0];
				on = result[1];
			}
			
			return on;
		}
		
		private function derive1():void
		{
			morph = Main.data.cclass[_cclass][1];
			specialAttack = Main.data.morph[morph][7];
		}
		
		private function derive2():void
		{
			wepSlots = new Array();
			for (var i:uint = 0; i < armors.length; i++)
				if (Main.data.limbtype[Main.data.morph[morph][getLimbStart(i)]][2] == 1)
					wepSlots.push(i);
			lastTotalHealth = totalHealth;
			messageArrayTimer = 0;
		}
		
		private function get totalHealth():uint
		{
			var tH:uint = 0;
			for (var i:uint = 0; i < armors.length; i++)
				if (armors[i])
					tH += (armors[i] as Armor).totalHealth;
			return tH;
		}
		
		public function Creature(x:uint, y:uint, cclass:uint, faction:uint, difficulty:uint, generate:Boolean)
		{
			_moved = false;
			_dead = false
			_isPlayer = false;
			animHitting = null;
			trapHit = null;
			rumble = null;
			canLevel = false;
			stunnedMessage = null;
			poisonDuration = 0;
			satiation = STARTSATIATION;
			hydration = STARTSATIATION;
			aug = null;
			
			_x = x;
			_y = y;
			if (generate)
			{
				_cclass = cclass;
				_name = Main.data.cclass[cclass][0];
				_faction = faction;
				derive1();
				if (Main.data.morph[morph][3] == 1)
					genderAdd = Math.random() * 2;
				else
					genderAdd = 0; //always male
			
				//coloration
				var colormorph:uint = Main.data.morph[morph][2];
				var hasHair:Boolean = Main.data.colormorph[colormorph][6] == 1;
				if (hasHair)
				{
					//generate a random hair color
					var cMax:uint = 0x8F;
					var rFix:uint = 0x2F;
					var gFix:uint = 0x2F;
					var bFix:uint = 0x2F;
					var mPick:uint = Math.random() * 4;
					switch(mPick)
					{
					case 0:
						rFix = 0x5F; //red hair
						break;
					case 1:
						gFix = 0x5F; //green hair
						break;
					case 2:
						bFix = 0x5F; //blue hair
						break;
					case 3:
						cMax = 0x6F; //dark hair
						break;
					}
					hairColor = ((cMax - rFix) * Math.random() + rFix) +
								(((cMax - gFix) * Math.random() + gFix) << 8) +
								(((cMax - bFix) * Math.random() + bFix) << 16);
					hairNumber = Math.random() * NUMHAIRSTYLES;
				}
				else
					hairColor = 0;
				var cPick:uint = 5 * Math.random();
				eyeColor = Main.data.colormorph[colormorph][1 + cPick];
				cPick = 5 * Math.random();
				skinColor = Main.data.colormorph[colormorph][7 + cPick];
			
				skills = new Array();
				skillProgress = new Array();
				for (var i:uint = 0; i < Main.data.skill.length; i++)
				{
					skills.push(0);
					skillProgress.push(0);
				}
			
				//auto level your class skills
				if (Main.data.cclass[cclass][7] != Database.NONE)
					setSkillLevel(difficulty, Main.data.cclass[cclass][7]);
				if (Main.data.cclass[cclass][8] != Database.NONE)
					setSkillLevel(difficulty, Main.data.cclass[cclass][8]);
				if (Main.data.cclass[cclass][9] != Database.NONE)
					setSkillLevel(difficulty * 0.75, Main.data.cclass[cclass][9]);
				if (Main.data.cclass[cclass][10] != Database.NONE)
					setSkillLevel(difficulty * 0.75, Main.data.cclass[cclass][10]);
			
				pack = new Array();
			
				armors = new Array();
				//pick armor pieces of the appropriate type for your class
				var numLimbs:uint = getNumLimbs();
				setSkillLevel(difficulty, SKILLEQUIPTIER);
				if (skills[SKILLEQUIPTIER] > MAXEQUIPTIER)
					skills[SKILLEQUIPTIER] = MAXEQUIPTIER;
				for (i = 0; i < numLimbs; i++)
				{
					var limbType:uint = Main.data.morph[morph][getLimbStart(i)];
					if (Main.data.limbtype[limbType][7] == 0)
					{
						var limbTrack:Array = Main.data.armortrack[Main.data.cclass[_cclass][2 + limbType]];
						var variations:uint = limbTrack[1];
						var arm:Armor
						if (variations == 0)
						{
							arm = new Armor(limbTrack[2]);
							arm.applyTierBonus(skills[SKILLEQUIPTIER]);
						}
						else
						{
							var pick:uint = Math.random() * variations;
							arm = new Armor(limbTrack[2 + variations * (skills[SKILLEQUIPTIER]) + pick]);
						}
						armors.push(arm);
					}
					else
						armors.push(null);
				}
				
				derive2();
			
				weapons = new Array();
				for (i = 0; i < armors.length; i++)
					if (Main.data.limbtype[Main.data.morph[morph][getLimbStart(i)]][2] == 1)
						weapons.push(null);
				
				var wepTrackNum:uint = Main.data.cclass[cclass][6];
				if (wepTrackNum == Database.NONE)
					addFists();
				else
				{
					/*
					if (cclass == 0)
					{
						for (var jk:uint = 0; jk < Main.data.weapon.length; jk++)
						{
							if (Main.data.weapon[jk][0] == "wrench")
							{
								equipWeapon(new Weapon(jk), true);
								break;
							}
						}
					}
					else
					/**/
					{
					var wepTrack:Array = Main.data.armortrack[wepTrackNum];
					equipWeapon(new Weapon(wepTrack[skills[SKILLEQUIPTIER] * wepTrack[1] + 2]), true);
					}
				}
				
				//get ammo for your weapons
				for (i = 0; i < weapons.length; i++)
				{
					var wep:Weapon = weapons[i];
					if (wep && wep.ammoID != Database.NONE)
						for (var j:uint = 0; j < wep.ammoStart; j++)
							inventoryAdd(new Stackable(wep.ammoID));
				}
				
				//add misc items based on class
				var randomIt:Array = Main.getRandomitems(Main.data.cclass[cclass][11], RANDOMITEMS);
				for (i = 0; i < randomIt.length; i++)
					inventoryAdd(randomIt[i]);
					
				//add an augment
				if (Math.random() < MONSTERAUGCHANCE)
				{
					while (true)
					{
						var augPick:uint = Math.random() * Main.data.augment.length;
						var humanAug:Boolean = Main.data.augmentType[Main.data.augment[augPick][4]][1] == 1;
						if ((humanAug && morph == 0) || (!humanAug && morph != 0))
						{
							aug = new Augment(augPick);
							break;
						}
					}
				}
			}
		}
		
		protected function inventoryAdd(it:Item):void
		{
			switch(it.category)
			{
			default:
				//weapon, armor, etc, so don't do stackable checks
				pack.push(it);
				break;
			case 2:
				//stackable, so do stackable checks
				var st:Stackable = it as Stackable;
				for (var i:uint = 0; i < pack.length; i++)
				{
					var it2:Item = pack[i];
					if (it2.category == 2)
					{
						var st2:Stackable = it2 as Stackable;
						if (st2.id == st.id)
						{
							st2.combine(st);
							return;
						}
					}
				}
				pack.push(it);
				break;
			}
		}
		
		private function heal(strength:uint, orgHeal:Boolean):void
		{
			strength *= 1 + (skills[SKILLMENDING] * 0.1);
			
			var changed:Boolean = false;
			for (var i:uint = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (arm)
				{
					var oldStr:uint = strength;
					strength = arm.heal(strength, orgHeal);
					if (strength != oldStr)
						changed = true; //you actually healed something
					if (strength == 0)
						break;
				}
			}
			
			if (changed)
				levelSkill(SKILLMENDING, 1);
		}
		
		protected function craft(recipie:uint):void
		{
			var rec:Array = Main.data.recipie[recipie];
			
			for (var i:uint = 0; i < 3; i++)
			{
				var itemID:uint = rec[8 + i * 2];
				var itemNum:uint = rec[9 + i * 2];
				if (itemID != Database.NONE)
				{
					var st:Stackable;
					for (var j:uint = 0; j < pack.length; j++)
					{
						var it:Item = pack[j];
						if (it.category == 2)
						{
							st = it as Stackable;
							if (st.id == itemID)
							{
								for (var k:uint = 0; k < itemNum; k++)
									st.split;
								break;
							}
						}
					}
					
					if (st.number == 0)
					{
						var newPack:Array = new Array();
						for (j = 0; j < pack.length; j++)
							if (pack[j] != st)
								newPack.push(pack[j]);
						pack = newPack;
					}
				}
			}
			
			switch(rec[2])
			{
			case 0:
				inventoryAdd(new Weapon(rec[1]));
				break;
			case 1:
				inventoryAdd(new Armor(rec[1]));
				break;
			case 2:
				inventoryAdd(new Stackable(rec[1]));
				break;
			}
			
			levelSkill(rec[3], rec[7]);
		}
		
		private function useAmmo(ammoID:uint):Boolean
		{
			if (ammoID == Database.NONE)
				return true; //didn't need to use ammo
			for (var i:uint = 0; i < pack.length; i++)
			{
				if ((pack[i] as Item).category == 2)
				{
					var st:Stackable = pack[i];
					if (st.id == ammoID)
					{
						if (st.useOne()) //remove it
						{
							var newPack:Array = new Array();
							for (i = 0; i < pack.length; i++)
								if (pack[i] != st)
									newPack.push(pack[i]);
							pack = newPack;
						}
						return true;
					}
				}
			}
			return false;
		}
		
		protected function useItem(st:Stackable):Boolean
		{
			switch(st.useCategory)
			{
			case 0: //mechanical healing item
				heal(st.strength, false);
				break;
			case 1: //organic healing item
				heal(st.strength, true);
				break;
			case 3: //food
				if (satiation >= BLOATEDSATIATION)
					return false; //too full
				satiation += st.strength;
				if (satiation >= MAXSATIATION)
					satiation = MAXSATIATION;
				break;
			case 4: //drink
				if (hydration >= BLOATEDSATIATION)
					return false; //too full
				hydration += st.strength;
				if (hydration >= MAXSATIATION)
					hydration = MAXSATIATION;
				break;
			case 5: //trap
				(FP.world as Map).placeTrap(st.strength, skills[SKILLTRAPS], _x, _y);
				levelSkill(SKILLTRAPS, 1); //level traps skill
				break;
			default: //something that isnt usable
				return false;
			}
			
			if (st.useOne())
			{
				//remove it from your pack
				var newPack:Array = new Array();
				for (var i:uint = 0; i < pack.length; i++)
					if (pack[i] != st)
						newPack.push(pack[i]);
				pack = newPack;
			}
			
			return true; //used successfully
		}
		
		protected function unequipArmor(arm:Armor):void
		{
			for (var i:uint = 0; i < armors.length; i++)
				if (armors[i] == arm)
				{
					var health:uint = arm.getHealth();
					if (Main.data.limbtype[arm.limbType][5] == 1)
					{
						armors[i] = new Armor(arm.limbType); //put in a noarmor there, since it's vital
						(armors[i] as Armor).applyHealth(health);
					}
					else
						armors[i] = null;
					if (!arm.unlisted)
						pack.push(arm);
					limbWasRemoved(i, arm.limbType);
					return;
				}
		}
		
		protected function equipArmor(arm:Armor):Boolean
		{
			if (arm.natural && Main.data.limbtype[arm.limbType][5] == 0)
				return false; //can't re-equip severed limbs!
			for (var i:uint = 0; i < armors.length; i++)
			{
				if ((!armors[i] || (armors[i] as Armor).unlisted)
					&& Main.data.morph[morph][getLimbStart(i)] == arm.limbType)
				{
					if (armors[i])
						arm.applyHealth((armors[i] as Armor).getHealth());
					armors[i] = arm;
					//remove it from the pack
					var newPack:Array = new Array();
					for (i = 0; i < pack.length; i++)
						if (pack[i] != arm)
							newPack.push(pack[i]);
					pack = newPack;
					addFists();
					return true;
				}
			}
			return false;
		}
		
		protected function addFists():void
		{
			equipWeapon(new Weapon(0), true);
		}
		protected function removeFists():void
		{
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep && wep.unlisted)
					weapons[i] = null;
			}
		}
		
		protected function equipAugment(nAug:Augment):Boolean
		{
			if (!aug || aug.type == nAug.type || !aug.binds)
			{
				if (aug)
					pack.push(aug);
				aug = nAug;
				var nPack:Array = new Array();
				for (var i:uint = 0; i < pack.length; i++)
					if (pack[i] != nAug)
						nPack.push(pack[i]);
				pack = nPack;
				return true;
			}
			return false;
		}
		
		protected function unequipAugment():void
		{
			if (aug && !aug.binds)
			{
				pack.push(aug);
				aug = null;
			}
		}
		
		protected function unequipWeapon(wep:Weapon):void
		{
			removeFists();
			for (var i:uint = 0; i < weapons.length; i++)
				if (wep == weapons[i])
				{
					weapons[i] = null;
					if (!wep.unlisted)
						pack.push(wep);
					addFists();
					return;
				}
			addFists();
		}
		
		protected function equipWeapon(wep:Weapon, automatic:Boolean):Boolean
		{
			removeFists();
			for (var k:uint = 0; k < wepSlots.length; k++)
			{
				var i:uint = wepSlots[k];
				if (!weapons[k] && armors[i])
				{
					var group:uint = Main.data.morph[morph][getLimbStart(i) + 4];
					
					var handsLeft:uint = 2;
					//examine this group. how many hands are being used here?
					for (var j:uint = 0; j < weapons.length; j++)
					{
						if (Main.data.morph[morph][getLimbStart(wepSlots[j]) + 4] == group)
						{
							if (!armors[wepSlots[j]])
								handsLeft -= 1; //because you don't have a weapon there
							else if (weapons[j])
								handsLeft -= (weapons[j] as Weapon).hands;
						}
					}
					
					if (handsLeft >= wep.hands)
					{
						weapons[k] = wep;
						if (automatic)
							wep = wep.copy();
						else
						{
							//remove it from the pack, if necessary
							var newPack:Array = new Array();
							for (i = 0; i < pack.length; i++)
								if (pack[i] != wep)
									newPack.push(pack[i]);
							pack = newPack;
							addFists();
							return true;
						}
					}
				}
			}
			
			return false;
		}
		
		public function get faction():uint { return _faction; }
		protected function get animating():Boolean
		{
			return animHitting != null || trapHit != null;
		}
		
		private function setSkillLevel(difficulty:uint, skillNum:uint):void
		{
			Main.setSkillLevel(difficulty, skillNum, skills, skillProgress);
		}
		
		protected function levelSkill(num:uint, amount:uint):void
		{
			if (canLevel)
				Main.levelSkill(amount, num, skills, skillProgress);
		}
		
		public function get dead():Boolean { return _dead; }
		
		public function get cclass():uint { return _cclass; }
		public function cmdTrace():void
		{
			trace(Main.data.cclass[_cclass][0] + ":");
			trace("   " + skills);
			for (var i:uint = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (!arm)
					trace("   BROKEN");
				else
					arm.cmdTrace();
			}
		}
		
		public function setPosition(x:uint, y:uint):void
		{
			_x = x;
			_y = y;
		}
		
		protected function move(xTo:uint, yTo:uint):Boolean
		{
			(FP.world as Map).move(_x, _y, xTo, yTo);
			_x = xTo;
			_y = yTo;
			
			//trigger traps
			var t:Trap = (FP.world as Map).triggerTrapAt(_x, _y);
			if (t)
			{
				trapHit = t;
				animLeft = ANIMLENGTH;
				return true; //return true to show you hit a trap
			}
			return false; //return false to show you didnt hit a trap
		}
		
		private function get satPenalty():Number
		{
			var pen:Number = 1;
			if (satiation > BLOATEDSATIATION)
				pen *= 0.8;
			else if (satiation < HUNGRYSATIATION)
				pen *= 0.6;
			else if (satiation == 0)
				pen *= 0.5;
			if (hydration > BLOATEDSATIATION)
				pen *= 0.9;
			else if (hydration < HUNGRYSATIATION)
				pen *= 0.7;
			else if (hydration == 0)
				pen *= 0.6;
			return pen;
		}
		
		protected function get satName():String
		{
			if (satiation > BLOATEDSATIATION)
				return "STUFFED";
			else if (satiation == 0)
				return "STARVING";
			else if (satiation < HUNGRYSATIATION)
				return "HUNGRY";
			else
				return null;
		}
		
		protected function get poisonName():String
		{
			if (poisonDuration > 0)
				return "POISONED";
			else
				return null;
		}
		
		protected function get hydrName():String
		{
			if (hydration > BLOATEDSATIATION)
				return "BLOATED";
			else if (hydration == 0)
				return "DEHYDRATED";
			else if (hydration < HUNGRYSATIATION)
				return "THIRSTY";
			else
				return null;
		}
		
		protected function get movespeed():uint
		{
			var ms:Number = Main.data.morph[morph][4];
			if (ms == 0)
				return 0; //if your base movespeed is 0, you are MEANT to be immobile
			var mult:Number = 1;
			//add ms modifiers from armor
			for (var i:uint = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (!arm)
				{
					var pen:uint = Main.data.limbtype[Main.data.morph[morph][getLimbStart(i)]][6];
					mult *= 1 - (0.01 * pen); //multiplicative penalty
				}
				else
				{
					//add ms bonuses
					ms += arm.speedBonus * 0.01;
				}
			}
			//add ms modifier from augment
			if (aug)
				ms += aug.speedBonus * 0.01;
			ms *= mult; //apply the total mult last, so it doesn't interact wierdly with bonuses
			//add modifier from satiation
			if (isPlayer)
				ms *= satPenalty;
			if (ms < 1)
				ms = 1; //minimum speed
			return ms;
		}
		
		public function setPlayerStats(gA:uint, hC:uint, hS:uint, sC:uint, eC:uint, job:uint, crime:uint, n:String):void
		{
			//add crime items
			for (var i:uint = 3; i < Main.data.crime[crime].length; i += 2)
			{
				var st:Stackable = new Stackable(Main.data.crime[crime][i]);
				st.multiply(Main.data.crime[crime][i + 1]);
				inventoryAdd(st);
			}
			
			_name = n;
			skills[Main.data.occupation[job][3]] += 1;
			if (Main.data.occupation[job][2] != Database.NONE)
				aug = new Augment(Main.data.occupation[job][2]);
			else
				aug = null;
			genderAdd = gA;
			if (hS == Database.NONE)
				hairColor = 0;
			else
			{
				hairColor = hC;
				hairNumber = hS;
			}
			eyeColor = Main.data.colormorph[Main.data.morph[morph][2]][eC + 1];
			skinColor = Main.data.colormorph[Main.data.morph[morph][2]][sC + 7];
		}
		
		protected function ratePosition(i:uint, target:Creature):uint
		{
			var oldX:uint = _x;
			var oldY:uint = _y;
			_x = (FP.world as Map).getX(i);
			_y = (FP.world as Map).getY(i);
			var distance:uint = Math.abs(_x - oldX) + Math.abs(_y - oldY);
			var nIR:uint = numInRange(target, true);
			var oNIR:uint = target.numInRange(this, true);
			if (inSpecialRange(target))
				nIR += 1;
			var trapPenalty:uint = 0;
			if ((FP.world as Map).trapAt(_x, _y))
				trapPenalty = 1;
			_x = oldX;
			_y = oldY;
			if (nIR == 0)
				return 0; //it's a bad spot
			else
				return nIR * 10000 - oNIR * 100 - distance - trapPenalty * 5; //try to avoid traps and their weapons if you can
		}
		
		protected function numOfItem(type:uint):uint
		{
			for (var i:uint = 0; i < pack.length; i++)
			{
				var it:Item = pack[i];
				if (it.category == 2)
				{
					var st:Stackable = it as Stackable;
					if (st.id == type)
						return st.number;
				}
			}
			return 0;
		}
		
		private function wepInRange(i:uint, target:Creature, slowCanShoot:Boolean, shouldUseAmmo:Boolean):Boolean
		{
			var distance:uint = Math.abs(target._x - _x) + Math.abs(target._y - _y);
			var wep:Weapon = weapons[i];
			return (wep && //exists
					(slowCanShoot || !wep.slow) && //stable enough to attack
					wep.range >= distance && //in range
					!target.dead && //can't shoot a dead man
					(!wep.slow || wep.range == 1 || distance > 1) && //slow ranged weapons can't be used in melee
					(distance == 1 || (FP.world as Map).hasLOS(this, target)) && //has LoS
					(wep.ammoID == Database.NONE || !isPlayer ||
						((!shouldUseAmmo && numOfItem(wep.ammoID) > 0) || (shouldUseAmmo && useAmmo(wep.ammoID))))); //has ammo
		}
		
		private function numInRange(target:Creature, slowCanShoot:Boolean):uint
		{
			var nIR:uint = 0;
			for (var i:uint = 0; i < weapons.length; i++)
				if (wepInRange(i, target, slowCanShoot, false))
					nIR += 1;
			return nIR;
		}
		
		protected function inSpecialRange(target:Creature):Boolean
		{
			if (specialAttack == Database.NONE)
				return false;
				
			//also see if you CAN use the special
			var limbRequired:uint = Main.data.specialattack[specialAttack][6];
			if (limbRequired != Database.NONE)
			{
				var hasL:Boolean = false;
				for (var i:uint = 0; i < armors.length; i++)
					if (armors[i] && Main.data.morph[morph][getLimbStart(i)] == limbRequired)
					{
						hasL = true;
						break;
					}
				if (!hasL)
					return false; //lacking in the proper limb
			}
			
			var distance:uint = (Math.abs(target._x - _x) + Math.abs(target._y - _y));
			
			return (distance <= Main.data.specialattack[specialAttack][2]) &&
					((distance == 1 || (FP.world as Map).hasLOS(this, target))); //has LOS
		}
		
		protected function inSightRange(target:Creature):Boolean
		{
			return (Math.abs(target._x - _x) + Math.abs(target._y - _y)) <= Main.data.morph[morph][6];
		}
		
		protected function get name():String { return _name; }
		protected function get onscreen():Boolean
		{
			return (FP.world as Map).onscreen(_x, _y);
		}
		
		protected function inRange(target:Creature, slowCanShoot:Boolean):Boolean
		{
			return numInRange(target, slowCanShoot) != 0;
		}
		
		protected function hasSlowWeapon():Boolean
		{
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep && wep.slow)
					return true;
			}
			return false;
		}
		
		protected function allInRange(target:Creature, slowCanShoot:Boolean):Boolean
		{
			var nW:uint = 0;
			for (var i:uint = 0; i < weapons.length; i++)
				if (weapons[i])
					nW += 1;
			return numInRange(target, slowCanShoot) == nW;
		}
		
		protected function attack(target:Creature, slowCanShoot:Boolean):void
		{
			if (isPlayer && target.faction == 0 && !(FP.world as Map).crime)
				(FP.world as Map).crime = true; //you committed a crime
			
			//restore the shots on all of your weapons
			for (var i:uint = 0; i < weapons.length; i++)
				if (weapons[i])
					(weapons[i] as Weapon).resetShots();
			
			animHitting = target;
			if (!target.isPlayer)
				(target as AI).switchTarget(this);
			animSlow = slowCanShoot;
			animLeft = 0;
			animAttOn = weapons.length;
			animSpecial = false;
		}
		
		protected function useSpecial(target:Creature):void
		{
			animHitting = target;
			animLeft = ANIMLENGTH;
			animSpecial = true;
			animIcon = Main.data.specialattack[specialAttack][5];
			if (!target.isPlayer)
				(target as AI).switchTarget(this);
			
			var acB:Number = 0;
			if (aug)
				acB = aug.accuracyBonus * 0.01;
			if (Main.data.specialattack[specialAttack][4] == 1 &&
				Math.random() <= animHitting.getDodgeChance(skills[SKILLSPECIALATTACK], acB))
			{
				animHitting.levelSkill(SKILLDODGE, 12);
				animMissMessage = DODGEDMESSAGE;
			}
			else
				animMissMessage = null;
		}
		
		private function hText(contents:String):void
		{
			if (onscreen)
			{
				FP.world.add(new HitText(contents, this, messageArrayTimer));
				messageArrayTimer += MESSAGEARRAYTIME;
			}
		}
		
		public function takeHit(limbChart:Array, damage:uint, skill:uint, deftness:Number, canBlock:Boolean, expIfBlocked:uint):Boolean
		{
			if (isPlayer)
				damage *= PLAYERRESISTANCE;
				
			if (aug)
				damage = Math.round(damage * (1 - (aug.soakBonus * 0.01)));
			
			if (damage == 0)
				return true; //you are hit, but take no damage
			
			//if it's an explosion
			if (limbChart.length == 0)
			{
				while (damage > 0)
				{
					if (dead)
						return true;
					var aPick:uint = armors.length * Math.random();
					var arm:Armor = armors[aPick];
					if (arm)
					{
						var eSize:uint;
						if (damage > EXPLOSIONGRANULARITY)
							eSize = EXPLOSIONGRANULARITY;
						else
							eSize = damage;
						hitLimb(aPick, eSize, false);
						damage -= eSize;
					}
				}
				return true;
			}
			
			//MAYBE randomize the hit location
			if (Math.random() < 0.15)
				limbChart.sort(Main.randomize);
			if (Math.random() < 0.15) //the body is always likely to be hit
				limbChart[0] = 1;
			
			for (var i:uint = 0; i < limbChart.length; i++)
			{
				if (i == 0 && canBlock &&
					(Main.data.limbtype[limbChart[i]][4] == 0 || //don't bother blocking if they are targeting your arms anyway
					Math.random() < 0.5)) //there's a chance to block anyway though, to reduce the damage
				{
					//see if you blocked the attack
					//try out each blockable limb
					for (var j:uint = 0; j < armors.length; j++)
					{
						arm = armors[j];
						if (arm) //can't block with a broken arm
						{
							var type:uint = Main.data.morph[morph][getLimbStart(j)];
							if (Main.data.limbtype[type][4] == 1)
							{
								//this limb can block, so try out a block
								var blockChance:Number = skills[SKILLBLOCK] * 0.03 - skill * 0.03 + arm.dodgeMod * 0.01;
								if (aug)
									blockChance += aug.blockBonus * 0.01;
								if (blockChance > 0.5)
									blockChance = 0.5;
								if (Math.random() < blockChance)
								{
									//it's blocked!
									levelSkill(SKILLBLOCK, expIfBlocked); //level blocking
									hText("Blocked!");
									hitLimb(j, damage * 0.5, false); //if you block the hit does less damage
									return false;
								}
							}
						}
					}
				}
				
				var candidates:Array = new Array();
				for (j = 0; j < armors.length; j++)
				{
					if (armors[j] && //it's not broken
						Main.data.morph[morph][getLimbStart(j)] == limbChart[i]) //it's the right type
						candidates.push(j);
				}
				
				if (candidates.length > 0)
				{
					//pick a random one
					
					var picked:uint = Math.random() * candidates.length;
					hitLimb(candidates[picked], damage, false);
					return true; //you hit, so end it here
				}
			}
			
			//none of the limbs on your hit table were present
			hText(MISSEDMESSAGE);
			return false; //nothing happened
		}
		
		private function hitLimb(i:uint, damage:uint, pierceArmor:Boolean):void
		{
			var arm:Armor = armors[i];
			var type:uint = Main.data.morph[morph][getLimbStart(i)];
			arm.takeHit(damage, pierceArmor);
			if (arm.dead)
			{
				//get the debris from it
				var debris:Stackable = (armors[i] as Armor).getDebris();
				if (debris)
					inventoryAdd(debris);
				armors[i] = null;
				//if it's vital you die
				if (Main.data.limbtype[type][5] == 1)
				{
					_dead = true;
					convertLimbs();
					dropItems();
					trace(Main.data.cclass[_cclass][0] + " died!");
				}
				else
					limbWasRemoved(i, type);
			}
		}
		
		private function convertLimbs():void
		{
			//turns all of your limbs into debris and nulls them
			for (var i:uint = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (arm)
				{
					var debris:Stackable = arm.getDebris();
					if (debris)
						inventoryAdd(debris);
					armors[i] = null;
				}
			}
		}
		
		private function limbWasRemoved(i:uint, type:uint):void
		{
			removeFists();
			if (Main.data.limbtype[type][2] == 1)
				{
				//it might be holding a weapon; check just in case
				var wepOn:uint = 0;
				for (var j:uint = 0; j < weapons.length; j++)
				{
					var wep:Weapon = weapons[j];
					if (wep != null)
					{
						if ((wepSlots[j] == i && wep.hands == 1) ||
							(Main.data.morph[morph][getLimbStart(wepSlots[j]) + 4] ==
							Main.data.morph[morph][getLimbStart(i) + 4] && wep.hands > 1))
						{
							if (!(weapons[j] as Weapon).unlisted)
								pack.push(weapons[j]); //it goes into your pack
							weapons[j] = null; //drop it
							break;
						}
						wepOn += 1;
					}
				}
			}
			addFists(); //removing and adding fists is so that losing an arm with a 2h weapon
						//will make you have a fist left over
		}
		
		protected function get strBonus():Number
		{
			var _strBonus:Number = 1;
			for (var i:uint = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (arm)
					_strBonus += arm.strengthBonus * 0.01;
			}
			if (aug)
				_strBonus += aug.strengthBonus * 0.01;
			//satiation penalty
			if (isPlayer)
				_strBonus *= satPenalty;
			return _strBonus;
		}
		private function getNumLimbs():uint { return (Main.data.morph[morph].length - 9) / 6; }
		private function getLimbStart(i:uint):uint { return 9 + 6 * i; }
		
		public function messageUpdate():void
		{
			var tH:uint = totalHealth;
			if (tH != lastTotalHealth && dead)
				hText("KILLED!");
			else if (tH < lastTotalHealth)
				hText("-" + (lastTotalHealth - tH));
			else if (tH > lastTotalHealth)
				hText("+" + (tH - lastTotalHealth));
			lastTotalHealth = tH;
			
			messageArrayTimer -= FP.elapsed;
			if (messageArrayTimer < 0)
				messageArrayTimer = 0;
		}
		
		public function update():void
		{
			if (trapHit)
			{
				//you are being hit by a trap
				rumble = TRAPMESSAGE;
				animLeft -= FP.elapsed;
				if (animLeft <= 0)
				{
					takeHit(trapHit.table, trapHit.damage, 0, 1, false, 0); //simulate it as an undodgeable hit
					if (trapHit.stun)
						stunnedMessage = STUNNEDTRAPMESSAGE;
					trapHit = null;
				}
			}
			else if (animHitting)
			{
				if (animMissMessage != null)
					animHitting.rumble = animMissMessage;
				else
					animHitting.rumble = HITMESSAGE;
				rumble = ATTACKMESSAGE;
				animLeft -= FP.elapsed;
				if (!onscreen)
					animLeft = 0;
				if (animLeft <= 0)
				{
					var distance:uint = Math.abs(animHitting._x - _x) + Math.abs(animHitting._y - _y);
					var deftness:Number = Main.data.morph[morph][5] * 0.01;
					
					if (animSpecial)
					{
						if (animMissMessage != null)
						{
							//you had missed
							animHitting.hText(animMissMessage);
						}
						else 
						{
							var spLimbTable:Array = new Array();
							var spLimbTableOr:Array = Main.data.limbtable[Main.data.specialattack[specialAttack][3]];
							for (var i:uint = 1; i < spLimbTableOr.length; i++)
								spLimbTable.push(spLimbTableOr[i]);
							var multiplier:Number = (1 + 0.1 * skills[SKILLSPECIALATTACK]);
							/** //disabled because weapons dont get this penalty, I just realized
							if (skills[SKILLSPECIALATTACK] == 0)
								multiplier = T0PENALTY; //special attacks are extra weak at t0
							/**/
							if (animHitting.takeHit(spLimbTable, Main.data.specialattack[specialAttack][1] * multiplier,
													SKILLSPECIALATTACK,
													1, Main.data.specialattack[specialAttack][4] == 1, 12))
							{
								//apply the special effect, if appropriate
								switch(Main.data.specialattack[specialAttack][8])
								{
								case 0: //grapple
									animHitting.stunnedMessage = STUNNEDGRAPPLEMESSAGE;
									break;
								case 1: //poison
									if (animHitting.poisonDuration == 0 || animHitting.poisonDamage <= BASEPOISON * multiplier)
									{
										animHitting.poisonDamage = multiplier * BASEPOISON;
										animHitting.poisonDuration = POISONLENGTH;
									}
									break;
								}
							}
						}
					}
					else if (animAttOn == weapons.length)
						animAttOn = 0; //start first attack
					else
					{
						var wep:Weapon = weapons[animAttOn];
						
						//use up one shot from the weapon, whether it hits or not
						wep.useShot();
						
						if (animMissMessage != null)
						{
							//you had missed
							animHitting.hText(animMissMessage);
						}
						else if (wep.attack(animHitting, skills[wep.skill] * satPenalty, deftness, distance == 1, strBonus, isPlayer))
						{
							//you hit them!
							//so level your attacking skill
							levelSkill(wep.skill, wep.expPerAttack);
						}
					}
					
					while (animAttOn < weapons.length)
					{
						wep = weapons[animAttOn];
						
						if (wep && wep.hasShot() && wepInRange(animAttOn, animHitting, animSlow, true))
						{
							//see if it is going to miss or be dodged
							animMissMessage = null;
							
							//low deftness makes the attack miss on its own sometimes
							if (Math.random() > deftness)
								animMissMessage = MISSEDMESSAGE;
							else
							{
								//see if it was dodged
								var acB:Number = 0;
								if (aug)
									acB = aug.accuracyBonus * 0.01;
								if (Math.random() <= animHitting.getDodgeChance(skills[wep.skill] * satPenalty, acB))
								{
									animHitting.levelSkill(SKILLDODGE, wep.expPerAttack);
									animMissMessage = DODGEDMESSAGE;
									//get half EXP for missing
									levelSkill(wep.skill, wep.expPerAttack / 2);
								}
							}
							
							animLeft = ANIMLENGTH;
							animIcon = Main.data.skill[wep.skill][3];
							break;
						}
						else
							animAttOn += 1; //couldn't use that weapon, so go further
					}
					
					if (animAttOn == weapons.length || animSpecial)
					{
						//out of attacks
						animHitting = null;
					}
				}
			}
		}
		
		public function getDodgeChance(skill:uint, accuracyBonus:Number):Number
		{
			var dodgeChance:Number = 0.2 //base dodge chance
					- accuracyBonus //accuracy bonus, like from augs (reduces dodge chance)
					+ skills[SKILLDODGE] * 0.03 //skill dodge bonus
					- skill * 0.03 //skill accuracy
					- Main.data.skill[skill][7] * 0.01; //weapon accuracy bonus
			if (aug)
				dodgeChance += aug.dodgeBonus * 0.01;
			for (var i:uint = 0; i < armors.length; i++)
			{
				if (Main.data.limbtype[Main.data.morph[morph][getLimbStart(i)]][3] == 1)
				{
					var arm:Armor = armors[i];
					if (!arm)
						dodgeChance -= Armor.BASEDODGE * 0.01;
					else
						dodgeChance += arm.dodgeMod * 0.01;
				}
			}
			if (dodgeChance < 0.05)
				dodgeChance = 0.05;
			if (dodgeChance > 0.9)
				dodgeChance = 0.9;
			return dodgeChance;
		}
		
		protected function resetStun():void { stunnedMessage = null; applyPoison(); }
		public function skipTurn():Boolean
		{
			if (stunnedMessage)
			{
				_moved = true; //give up your turn
				hText(stunnedMessage);
				stunnedMessage = null;
				applyPoison();
				return true;
			}
			return false;
		}
		public function get isPlayer():Boolean { return _isPlayer; }
		public function turnStart(applyEffects:Boolean):void
		{
			_moved = true;
			//cmdTrace();
			if (applyEffects) //don't apply poison or get hungrier if you are resuming from a save
			{
				applyPoison();
				if (isPlayer)
				{
					if (satiation > HUNGERRATE)
						satiation -= HUNGERRATE;
					else
						satiation = 0;
					if (hydration > HUNGERRATE)
						hydration -= HUNGERRATE;
					else
						hydration = 0;
						
					if (satiation == 0)
					{
						//starvation damage
						hurtBody(1, false, true);
					}
					if (hydration == 0)
					{
						//thirst damage
						hurtBody(1, false, true);
					}
				}
			}
		}
		
		private function applyPoison():void
		{
			if (poisonDuration > 0)
			{
				hurtBody(poisonDamage, false, false);
				poisonDuration -= 1;
			}
		}
		
		private function hurtBody(amount:uint, canKill:Boolean, pierceArmor:Boolean):void
		{
			for (var i:uint = 0; i < armors.length; i++)
			{
				if (Main.data.morph[morph][getLimbStart(i)] == 1)
				{
					if (!canKill)
					{
						var h:uint = (armors[i] as Armor).getHealth();
						if (h == 1)
							return;
						else if (h <= amount)
							amount = h - 1;
					}
					hitLimb(i, amount, pierceArmor);
					return;
				}
			}
		}
		
		protected function get specialChance():Boolean
		{
			if (specialAttack == Database.NONE)
				return false;
			else
				return Math.random() < 0.01 * Main.data.specialattack[specialAttack][7];
		}
		public function get moved():Boolean { return _moved; }
		public function roundStart():void
		{
			_moved = false;
		}
		
		public function get x():uint { return _x; }
		public function get y():uint { return _y; }
		
		public function renderIcon():void
		{
			if (animHitting)
			{
				var p:Point = new Point(
						_x * Map.TILESIZE - ICONSIZE / 2 + Map.TILESIZE / 2,
						_y * Map.TILESIZE - ICONSIZE / 2 + Map.TILESIZE / 2 - ICONHEIGHT);
				sprIcons.frame = animIcon;
				sprIcons.color = 0xFFFFFF;
				sprIcons.render(FP.buffer, p, FP.camera);
			}
		}
		
		public function renderHeat():void
		{
			for (var i:uint = 0; i < armors.length; i++)
			{
				var limbBase:uint = getLimbStart(i);
				var type:uint = Main.data.morph[morph][limbBase];
				var p:Point = new Point(x * Map.TILESIZE + Main.data.morph[morph][limbBase + 1],
										y * Map.TILESIZE + Main.data.morph[morph][limbBase + 2]);
				var arm:Armor = armors[i];
				if ((arm && arm.natural) ||
					(Main.data.limbtype[type][7] == 1))
				{
					sprParts.frame = Main.data.morph[morph][limbBase + 3];
					if (Main.data.limbtype[type][1] == 1)
						sprParts.frame += genderAdd;
					sprParts.flipped = Main.data.morph[morph][limbBase + 5] == 1;
					sprParts.color = Main.data.colormorph[Main.data.morph[morph][2]][12];
					sprParts.render(FP.buffer, p, FP.camera);
				}
			}
		}
		
		public function render():void
		{
			var bX:uint = _x * Map.TILESIZE;
			var bY:uint = _y * Map.TILESIZE;
			
			if (rumble)
			{
				var xPow:uint;
				var yPow:uint;
				switch(rumble)
				{
				case DODGEDMESSAGE:
					xPow = DODGERUMBLEPOWER;
					yPow = 0;
					break;
				case MISSEDMESSAGE:
					xPow = MISSRUMBLEPOWER;
					yPow = MISSRUMBLEPOWER;
					break;
				case ATTACKMESSAGE:
					xPow = ATTACKRUMBLEPOWER;
					yPow = ATTACKRUMBLEPOWER;
					break;
				default:
					xPow = RUMBLEPOWER;
					yPow = RUMBLEPOWER;
					break;
				}
				bX += Math.random() * xPow * 2 - xPow;
				bY += Math.random() * yPow * 2 - yPow;
				rumble = null;
			}
			
			//draw eyes
			var eyeMorph:Array = Main.data.eyemorph[Main.data.morph[morph][1]];
			for (var i:uint = 0; i < (eyeMorph.length - 1) / 3; i++)
			{
				var tEC:uint = eyeColor;
				if (i == 0 && aug && aug.overPart == Database.NONE && aug.color != 0)
					tEC = aug.color;
				FP.buffer.fillRect(new Rectangle(
									bX + eyeMorph[1 + i * 3] - FP.camera.x,
									bY + eyeMorph[2 + i * 3] - FP.camera.y,
									eyeMorph[3 + i * 3], eyeMorph[3 + i * 3]), tEC);
			}
			
			//draw body
			for (i = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				
				var limbBase:uint = getLimbStart(i);
				var p:Point = new Point(bX + Main.data.morph[morph][limbBase + 1],
										bY + Main.data.morph[morph][limbBase + 2]);
				sprParts.flipped = Main.data.morph[morph][limbBase + 5] == 1;
				var type:uint = Main.data.morph[morph][limbBase];
				
				if (((arm && arm.natural) || Main.data.limbtype[type][7] == 1)
					&& (Main.data.morph[morph][limbBase + 3] != Database.NONE))
				{
					sprParts.frame = Main.data.morph[morph][limbBase + 3];
					if (Main.data.limbtype[type][1] == 1)
						sprParts.frame += genderAdd;
					sprParts.color = skinColor;
					sprParts.render(FP.buffer, p, FP.camera);
				}
				
				if (arm)
				{
					if (hairColor != 0 && type == 0)
					{
						//add hair
						sprHair.color = hairColor;
						sprHair.frame = hairNumber;
						sprHair.render(FP.buffer, new Point(bX + HAIRX, bY + HAIRY), FP.camera);
					}
					
					if (aug && arm && aug.overPart == arm.limbType)
					{
						sprParts.frame = aug.sprite;
						sprParts.color = aug.color;
						sprParts.render(FP.buffer, p, FP.camera);
					}
					
					if (arm.sprite != Database.NONE)
					{
						sprParts.frame = arm.sprite;
						if (Main.data.limbtype[type][1] == 1)
							sprParts.frame += genderAdd;
						sprParts.color = arm.color;
						sprParts.render(FP.buffer, p, FP.camera);
					}
				}
			}
			
			//draw weapons
			var wepOn:uint = 0;
			for (i = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep != null && wep.sprite != Database.NONE)
				{
					var hand:uint = wepSlots[i];
					
					p = new Point(bX + Main.data.morph[morph][getLimbStart(hand) + 1],
								bY + Main.data.morph[morph][getLimbStart(hand) + 2] + WEPYADD);
					var sp:Spritemap;
					if (wep.hands == 1)
						sp = sprParts;
					else
						sp = sprWideParts;
					sp.flipped = Main.data.morph[morph][getLimbStart(hand) + 5] == 1;
					if (!sp.flipped && wep.hands > 1)
						p.x -= WIDEPARTWIDTH - PARTSIZE;
					sp.color = wep.color;
					sp.frame = wep.sprite;
					sp.render(FP.buffer, p, FP.camera);
					
					wepOn += 1;
				}
			}
		}
		
		private function dropItems():void
		{
			var corpse:uint = Main.data.morph[morph][8];
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep && !wep.unlisted && Math.random() < WEAPONDROPCHANCE)
					placeItemOnGround(wep, corpse);
			}
			for (i = 0; i < pack.length; i++)
				placeItemOnGround(pack[i] as Item, corpse);
		}
		
		protected function placeItemOnGround(place:Item, chestID:uint):void
		{
			//now put it in a chest
			var ch:Array = (FP.world as Map).getChestAtXY(x, y);
			if (!ch)
				ch = (FP.world as Map).makeChestAt(x, y, chestID);
			else if (ch[0] < Map.ACCESSEDCHEST)
				ch[0] += Map.ACCESSEDCHEST;
			
			for (var i:uint = 1; i < ch.length; i++)
			{
				var it:Item = ch[i];
				if (it.category == 2 && place.category == 2)
				{
					var st:Stackable = place as Stackable;
					var st2:Stackable = it as Stackable;
					if (st.id == st2.id)
					{
						st2.combine(st);
						return;
					}
				}
			}
			//it wasn't combined, so stick it on the end
			ch.push(place);
		}
	}

}