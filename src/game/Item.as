package game 
{
	public class Item 
	{
		public static var count:Boolean = true;
		
		public static function loadAny(fromArray:Array, on:uint):Array
		{
			switch(fromArray[on++])
			{
			case 0:
				return Weapon.load(fromArray, on);
			case 1:
				return Armor.load(fromArray, on);
			case 2:
				return Stackable.load(fromArray, on);
			case 3:
				return Augment.load(fromArray, on);
			}
			return null;
		}
		
		public static function saveAny(toArray:Array, it:Item):void
		{
			toArray.push(it.category);
			switch(it.category)
			{
			case 0:
				(it as Weapon).save(toArray);
				break;
			case 1:
				(it as Armor).save(toArray);
				break;
			case 2:
				(it as Stackable).save(toArray);
				break;
			case 3:
				(it as Augment).save(toArray);
				break;
			}
		}
		
		private static var CURRENTORDERID:uint = 0;
		private var _orderID:uint;
		private var _category:uint;
		
		public function Item(category:uint) 
		{
			_orderID = CURRENTORDERID;
			if (Item.count)
				CURRENTORDERID += 1;
			_category = category;
		}
		
		public function get value():uint { return 100; }
		public function get baseValue():uint { return 100; }
		public function get weight():uint { return 0; }
		public function getEffectText(skills:Array, strBonus:Number):String { return ""; }
		public function get unlisted():Boolean { return false; }
		public function get name():String { return null; }
		public function get category():uint { return _category; }
		public function get orderID():uint { return _orderID; }
	}

}