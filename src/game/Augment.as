package game 
{
	public class Augment extends Item
	{
		private static const AUGMENTBASE:uint = 10;
		
		public static function load(fromArray:Array, on:uint):Array
		{
			var result:Array = new Array();
			result.push(new Augment(fromArray[on++]));
			result.push(on);
			return result;
		}
		
		public function save(toArray:Array):void
		{
			toArray.push(_id);
		}
		
		private var _id:uint;
		private var _spriteNumber:uint;
		private var _overPart:uint;
		private var _color:uint;
		private var _type:uint;
		private var descriptionID:uint;
		private var _accuracyBonus:int;
		private var _dodgeBonus:int;
		private var _blockBonus:int;
		private var _strengthBonus:int;
		private var _soakBonus:int;
		private var _speedBonus:uint;
		private var _xray:Boolean;
		private var _sonar:Boolean;
		
		public function Augment(id:uint) 
		{
			super(3);
			
			_id = id;
			_spriteNumber = Main.data.augment[id][1];
			_overPart = Main.data.augment[id][2];
			_color = Main.data.augment[id][3];
			_type = Main.data.augment[id][4];
			descriptionID = Main.data.augment[id][5];
			_accuracyBonus = Main.data.augment[id][6] - AUGMENTBASE;
			_dodgeBonus = Main.data.augment[id][7] - AUGMENTBASE;
			_blockBonus = Main.data.augment[id][8] - AUGMENTBASE;
			_strengthBonus = Main.data.augment[id][9] - AUGMENTBASE;
			_soakBonus = Main.data.augment[id][10] - AUGMENTBASE;
			_speedBonus = Main.data.augment[id][11];
			_xray = Main.data.augment[id][12] == 1;
			_sonar = Main.data.augment[id][13] == 1;
			//display name is 14
			//value is 15
		}
		
		public override function get value():uint { return Main.data.augment[_id][15]; }
		public override function get baseValue():uint { return value; }
		public function get speedBonus():uint { return _speedBonus; }
		public function get color():uint { return _color; }
		public function get sprite():uint { return _spriteNumber; }
		public function get overPart():uint { return _overPart; }
		public function get binds():Boolean { return Main.data.augmentType[type][2] == 1; }
		public function get type():uint { return _type; }
		public function get xray():Boolean { return _xray; }
		public function get sonar():Boolean { return _sonar; }
		public function get accuracyBonus():int { return _accuracyBonus; }
		public function get strengthBonus():int { return _strengthBonus; }
		public function get soakBonus():int { return _soakBonus; }
		public function get dodgeBonus():int { return _dodgeBonus; }
		public function get blockBonus():int { return _blockBonus; }
		public override function get name():String { return Main.data.augment[_id][14]; }
		public override function getEffectText(skills:Array, strBonus:Number):String
		{
			var efT:String = "";
			
			if (_accuracyBonus > 0)
				efT += "+";
			if (_accuracyBonus != 0)
				efT += _accuracyBonus + "% accuracy\n";
				
			if (_soakBonus > 0)
				efT += "+";
			if (_soakBonus != 0)
				efT += _soakBonus + "% damage reduction\n";
			
			if (_dodgeBonus > 0)
				efT += "+";
			if (_dodgeBonus != 0)
				efT += _dodgeBonus + "% dodge chance\n";
				
			if (_blockBonus > 0)
				efT += "+";
			if (_blockBonus != 0)
				efT += _blockBonus + "% block chance\n";
				
			if (_speedBonus != 0)
			{
				var sB:Number = _speedBonus * 0.01;
				efT += "+" + sB.toFixed(2) + " moves\n";
			}
				
			if (_strengthBonus > 0)
				efT += "+";
			if (_strengthBonus != 0)
				efT += _strengthBonus + "% melee damage\n";
			
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