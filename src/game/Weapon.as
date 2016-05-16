package game 
{
	public class Weapon extends Item
	{
		private var _id:uint;
		
		private var _color:uint;
		private var _sprite:uint;
		private var _range:uint;
		private var damage:uint;
		private var table:uint;
		private var _skill:uint;
		private var _hands:uint;
		private var _slow:Boolean;
		private var burstSize:uint;
		private var shotsLeft:uint;
		private var _weight:uint;
		private var descriptionID:uint;
		
		private static const PLAYERMELEEBONUS:Number = 1.2;
		
		public function save(toArray:Array):void
		{
			toArray.push(_id);
		}
		
		public static function load(fromArray:Array, on:uint):Array
		{
			var loaded:Weapon = new Weapon(fromArray[on++]);
			var result:Array = new Array();
			result.push(loaded);
			result.push(on);
			return result;
		}
		
		public function Weapon(id:uint) 
		{
			super(0);
			_id = id;
			
			damage = Main.data.weapon[id][1];
			_range = Main.data.weapon[id][2];
			burstSize = Main.data.weapon[id][3];
			_slow = Main.data.weapon[id][4] == 1;
			_hands = Main.data.weapon[id][5];
			table = Main.data.weapon[id][6];
			_skill = Main.data.weapon[id][7];
			_sprite = Main.data.weapon[id][8];
			_color = Main.data.weapon[id][9];
			descriptionID = Main.data.weapon[id][10];
			_weight = Main.data.weapon[id][11];
			//display name is 12
			//value is 13
			
			shotsLeft = burstSize;
		}
		
		public function useShot():void { shotsLeft -= 1; }
		public function resetShots():void { shotsLeft = burstSize; }
		public function hasShot():Boolean { return shotsLeft > 0; }
		public function get expPerAttack():uint
		{
			return _hands * 12 / burstSize;
		}
		
		public function attack(target:Creature, skill:uint, deftness:Number, canBlock:Boolean, strBonus:Number, playerUsing:Boolean):Boolean
		{
			var limbChart:Array = new Array();
			for (var i:uint = 1; i < Main.data.limbtable[table].length; i++)
				limbChart.push(Main.data.limbtable[table][i]);
			return target.takeHit(limbChart, getDamage(skill, deftness, strBonus, playerUsing), skill, deftness, canBlock, expPerAttack);
		}
		
		private function getDamage(skill:uint, deftness:Number, strBonus:Number, playerUsing:Boolean):uint
		{
			var dam:uint = damage;
			if (range == 1)
			{
				if (playerUsing)
					dam *= PLAYERMELEEBONUS;
				dam *= strBonus;
			}
			dam *= Main.data.skill[_skill][8] * skill * 0.01 + 1; //damage bonus from skill
			dam *= deftness; //apply deftness here, so special attacks dont use it
			return dam;
		}
		
		public function copy():Weapon
		{
			return new Weapon(_id);
		}
		
		public function get ammoID():uint
		{
			return Main.data.skill[_skill][5];
		}
		public function get ammoStart():uint
		{
			return Main.data.skill[_skill][6] * burstSize;
		}
		public override function get value():uint { return Main.data.weapon[_id][13]; }
		public override function get baseValue():uint { return value; }
		public override function get unlisted():Boolean { return _id == 0; }
		public override function get name():String { return Main.data.weapon[_id][12]; }
		public function get slow():Boolean { return _slow; }
		public function get hands():uint { return _hands; }
		public function get skill():uint { return _skill; }
		public function get range():uint { return _range; }
		public function get color():uint { return _color; }
		public function get sprite():uint { return _sprite; }
		public override function get weight():uint { return _weight; }
		public override function getEffectText(skills:Array, strBonus:Number):String
		{
			var efT:String = getDamage(skills[_skill], 1, strBonus, true) + " damage\n";
			if (burstSize > 1)
				efT += burstSize + " attacks per round\n";
			if (_range > 1)
				efT += _range + " range\n";
			if (_slow)
				efT += "unwieldly\n";
				
			if (descriptionID != Database.NONE)
			{
				efT += "\n" + Main.data.lines[descriptionID];
			}
			
			return efT;
		}
	}

}