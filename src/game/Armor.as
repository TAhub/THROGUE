package game 
{
	public class Armor extends Item
	{
		public static const BASEDODGE:uint = 10;
		private static const RANDOMDURABILITYVARIATION:Number = 0.055;
		private var durability:uint;
		private var maxDurability:uint;
		private var health:uint;
		private var maxHealth:uint;
		private var _sprite:uint;
		private var _id:uint;
		private var _natural:Boolean;
		private var _color:uint;
		private var _dodgeMod:int;
		private var _speedBonus:uint;
		private var _strengthBonus:uint;
		private var _limbType:uint;
		private var _weight:uint;
		private var organic:Boolean;
		private var dropWhenDestroyed:uint;
		private var descriptionID:uint;
		
		public function save(toArray:Array):void
		{
			toArray.push(_id);
			toArray.push(maxDurability);
			toArray.push(durability);
			toArray.push(health);
		}
		
		public static function load(fromArray:Array, on:uint):Array
		{
			var loaded:Armor = new Armor(fromArray[on++]);
			loaded.setModStats(fromArray[on++], fromArray[on++], fromArray[on++]);
			var result:Array = new Array();
			result.push(loaded);
			result.push(on);
			return result;
		}
		
		public function setModStats(maxD:uint, d:uint, h:uint):void
		{
			maxDurability = maxD;
			durability = d;
			health = h;
		}
		
		public function Armor(id:uint) 
		{
			super(1);
			_id = id;
			maxDurability = Main.data.armor[id][1];
			
			//apply durability randomness
			maxDurability *= 1 - RANDOMDURABILITYVARIATION + (2 * RANDOMDURABILITYVARIATION * Math.random());
			
			_dodgeMod = Main.data.armor[id][2];
			_dodgeMod -= BASEDODGE; //to make 20 be +0
			_speedBonus = Main.data.armor[id][3];
			_strengthBonus = Main.data.armor[id][4];
			_limbType = Main.data.armor[id][5];
			maxHealth = Main.data.limbtype[limbType][8];
			health = maxHealth;
			_sprite = Main.data.armor[id][6];
			_color = Main.data.armor[id][7];
			_natural = Main.data.armor[id][8] == 1;
			organic = Main.data.armor[id][9] == 1;
			dropWhenDestroyed = Main.data.armor[id][10];
			descriptionID = Main.data.armor[id][11];
			_weight = Main.data.armor[id][12];
			//displayname is 13
			//value is 14
			
			//adjust durability to account for true health, if necessary
			if (maxDurability < maxHealth)
				maxDurability = 0;
			else
				maxDurability -= maxHealth;
			durability = maxDurability;
		}
		
		public function applyTierBonus(newTier:uint):void
		{
			maxDurability = maxHealth + maxDurability;
			if (newTier > 0)
				maxDurability *= 1 + (0.1 * newTier);
			else
				maxDurability *= Creature.T0PENALTY; //starter armor is extra weak for monsters
			
			if (maxDurability < maxHealth)
				maxDurability = 0;
			else
				maxDurability -= maxHealth;
				
			health = maxHealth;
			durability = maxDurability;
		}
		
		public function takeHit(damage:uint, pieceArmor:Boolean):void
		{
			if (!pieceArmor || maxHealth == 0)
			{
				if (durability <= damage)
				{
					damage -= durability;
					durability = 0;
				}
				else
				{
					durability -= damage;
					damage = 0;
				}
			}
			
			if (health <= damage)
				health = 0;
			else
				health -= damage;
		}
		
		public function heal(strength:uint, orgHeal:Boolean):uint
		{
			if (orgHeal && health < maxHealth)
			{
				if ((maxHealth - health) >= strength)
				{
					health += strength;
					return 0;
				}
				else
				{
					strength -= (maxHealth - health);
					health = maxHealth;
				}
			}
			
			if ((orgHeal && organic) || (!orgHeal && !organic))
			{
				if ((maxDurability - durability) >= strength)
				{
					durability += strength;
					return 0;
				}
				else
				{
					strength -= (maxDurability - durability);
					durability = maxDurability;
				}
			}
			
			return strength;
		}
		
		public function cmdTrace():void
		{
			trace("   " + Main.data.armor[_id][0] + ": " + durability + "/" + maxDurability + " (" + health + "/" + maxHealth + ")");
		}
		
		public function getHealth():uint
		{
			return health;
		}
		
		public function applyHealth(nHealth:uint):void
		{
			health = nHealth;
		}
		
		public function getDebris():Stackable
		{
			if (dropWhenDestroyed == Database.NONE)
				return null;
			else
				return new Stackable(dropWhenDestroyed);
		}
		public override function get value():uint { return Main.data.armor[_id][14]; }
		public override function get baseValue():uint { return value; }
		public function get totalHealth():uint { return health + durability; }
		public override function get weight():uint { return _weight; }
		public function get percentage():Number { return 1.0 * (health + durability) / (maxHealth + maxDurability); }
		public override function get unlisted():Boolean { return _id == 0 || _id == 1; }
		public function get limbType():uint { return _limbType; }
		public override function get name():String { return Main.data.armor[_id][13]; }
		public function get strengthBonus():uint { return _strengthBonus; }
		public function get speedBonus():uint { return _speedBonus; }
		public function get dodgeMod():int { return _dodgeMod; }
		public function get dead():Boolean { return health == 0 && durability == 0; }
		public function get natural():Boolean { return _natural; }
		public function get sprite():uint { return _sprite; }
		public function get color():uint { return _color; }
		public override function getEffectText(skills:Array, strBonus:Number):String
		{
			var efT:String = durability + "/" + maxDurability + " durability\n";
			var dName:String  = "";
			if (Main.data.limbtype[limbType][3] == 1)
				dName = "dodge";
			else if (Main.data.limbtype[limbType][4] == 1)
				dName = "block";
			if (_dodgeMod > 0)
				efT += "+";
			if (_dodgeMod != 0)
				efT += dodgeMod + "% " + dName + " chance\n";
			if (_speedBonus > 0)
			{
				var sB:Number = _speedBonus * 0.01;
				efT += "+" + sB.toFixed(2) + " moves\n";
			}
			if (_strengthBonus > 0)
				efT += "+" + _strengthBonus + "% melee damage\n";
			if (organic)
				efT += "organic\n";
			if (descriptionID != Database.NONE)
				efT += "\n" + Main.data.lines[descriptionID];
			
			return efT;
		}
	}

}