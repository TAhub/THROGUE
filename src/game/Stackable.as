package game 
{
	public class Stackable extends Item
	{
		private var _id:uint;
		private var _useCategory:uint;
		private var _strength:uint; 
		private var _number:uint;
		private var _weight:uint;
		private var _value:uint;
		private var descriptionID:uint;
		
		public function save(toArray:Array):void
		{
			toArray.push(id);
			toArray.push(number);
		}
		
		public static function load(fromArray:Array, on:uint):Array
		{
			var st:Stackable = new Stackable(fromArray[on++]);
			st.multiply(fromArray[on++]);
			
			var result:Array = new Array();
			result.push(st);
			result.push(on);
			return result;
		}
		
		public function Stackable(id:uint) 
		{
			super(2);
			
			_id = id;
			_strength = Main.data.stackable[id][1];
			_useCategory = Main.data.stackable[id][2];
			descriptionID = Main.data.stackable[id][3];
			_weight = Main.data.stackable[id][4];
			//display name is 5
			_value = Main.data.stackable[id][6];
			
			_number = 1;
		}
		
		public function combine(other:Stackable):void
		{
			_number += other._number;
		}
		
		public function useOne():Boolean
		{
			_number -= 1;
			return _number == 0;
		}
		
		public override function get name():String
		{
			var nm:String = Main.data.stackable[_id][5];
			if (_number > 1)
				nm += " x" + _number;
			return nm;
		}
		public function get copy():Stackable
		{
			var nS:Stackable = new Stackable(id);
			nS.multiply(number);
			return nS;
		}
		public function get split():Stackable
		{
			_number -= 1;
			return new Stackable(id);
		}
		public function multiply(amount:uint):void { _number *= amount; }
		public function get number():uint { return _number; }
		public function get id():uint { return _id; }
		public function get strength():uint { return _strength; }
		public function get useCategory():uint { return _useCategory; }
		public override function get weight():uint { return _weight * _number; }
		public override function get value():uint { return _value * _number; }
		public override function get baseValue():uint { return _value; }
		public override function getEffectText(skills:Array, strBonus:Number):String
		{
			var efT:String;
			switch (_useCategory)
			{
			case 0: //mechanical healing item
				efT = "heals non-organic armor for " + Math.floor((1 + skills[Creature.SKILLMENDING] * 0.1) * _strength) + "\n";
				break;
			case 1: //organic healing item
				efT = "heals organic matter for " + Math.floor((1 + skills[Creature.SKILLMENDING] * 0.1) * _strength) + "\n";
				break;
			case 3: //food
				efT = "restores satiation\n";
				break;
			case 4: //drink
				efT = "restores hydration\n";
				break;
			case 5: //trap
				efT = "lays a trap on your square\n";
				break;
			case 6: //valuable
				efT = "can be used when buying from merchants\n";
				break;
			default:
				efT = "";
				break;
			}
			
			if (descriptionID != Database.NONE)
			{
				if (efT.length > 0)
					efT += "\n";
				efT += Main.data.lines[descriptionID];
			}
			
			return efT;
		}
	}

}