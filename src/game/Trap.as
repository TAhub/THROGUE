package game 
{
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.FP;
	public class Trap 
	{
		[Embed(source = "sprites/traps.png")] private static const TRAPS:Class;
		private static const sprTrap:Spritemap = new Spritemap(TRAPS, Map.TILESIZE, Map.TILESIZE / 2);
		
		public static function load(loadFrom:Array, on:uint):Array
		{
			var t:Trap = new Trap(loadFrom[on++], loadFrom[on++], loadFrom[on++], loadFrom[on++]);
			
			var result:Array = new Array();
			result.push(t);
			result.push(on);
			return result;
		}
		
		public function save(saveTo:Array):void
		{
			saveTo.push(_id);
			saveTo.push(_skill);
			saveTo.push(_x);
			saveTo.push(_y);
		}
		
		private var _x:uint;
		private var _y:uint;
		private var _id:uint;
		private var _skill:uint;
		
		//derived/loaded stats
		private var sprite:uint;
		private var color:uint;
		private var _damage:uint;
		private var _table:uint;
		private var _stun:Boolean;
		
		public function Trap(id:uint, skill:uint, x:uint, y:uint) 
		{
			_x = x;
			_y = y;
			_id = id;
			_skill = skill;
			
			sprite = Main.data.layedTrap[id][1];
			color = Main.data.layedTrap[id][2];
			_damage = Main.data.layedTrap[id][3] * (1 + 0.1 * skill);
			_table = Main.data.layedTrap[id][4];
			_stun = Main.data.layedTrap[id][5] == 1;
		}
		
		public function get damage():uint { return _damage; }
		public function get stun():Boolean { return _stun; }
		public function get table():Array
		{
			var tb:Array = new Array();
			for (var i:uint = 1; i < Main.data.limbtable[_table].length; i++)
				tb.push(Main.data.limbtable[_table][i]);
			return tb;
		}
		public function get x():uint { return _x; }
		public function get y():uint { return _y; }
		
		public function render(forceDown:Boolean):void
		{
			sprTrap.frame = sprite;
			sprTrap.color = color;
			var downFactor:Number;
			if (forceDown)
				downFactor = 0.5;
			else
			{
				var dfstep:uint = (5 + _x) * _y;
				downFactor = 0.2 + (dfstep % 10) * 0.03;
			}
			sprTrap.render(FP.buffer, new Point(_x * Map.TILESIZE, (downFactor + _y) * Map.TILESIZE), FP.camera);
		}
	}

}