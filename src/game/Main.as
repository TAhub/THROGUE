package game
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	import net.flashpunk.World;
	
	public class Main extends Engine
	{
		public static const data:Database = new Database();
		public static const STARTLEVEL:uint = 6; //this should be a little bit over 0, with my change to how difficulty works
												//you should get to a new tier every 10 points of difficulty
		
		public function Main()
		{
			super(800, 600);
			
			FP.screen.color = 0x202020;
			Saver.openProfile("default");
			if (!Saver.playerExists())
				FP.world = new CharacterCreation();
			else
				startMap();
		}
		
		public static function startMap():void
		{
			FP.world = new Map(0, 0, STARTLEVEL, 2);
		}
		
		public static function validShutdown():void
		{
			Saver.closeProfile();
			FP.world = new World();
			//TODO: at some point make this return to menu
		}
		
		public static function valueSort(a:Item, b:Item):Number
		{
			return b.baseValue - a.baseValue;
		}
		
		public static function randomize(a:Object, b:Object):Number
		{
			return Math.floor(Math.random() * 3) - 1;
		}
		
		public static function setSkillLevel(difficulty:uint, skillNum:uint, skills:Array, skillProgress:Array):void
		{
			//placing this in main is to make sure that the calculation is the same for everything
			//chest items, player equipment, etc
			skillProgress[skillNum] = difficulty * 2000 / data.skill[skillNum][4];
			
			levelSkill(0, skillNum, skills, skillProgress); //use this to set the level appropriately
		}
		
		public static function getSkillCost(skillNum:uint, skillLevel:uint):uint
		{
			return skillLevel * data.skill[skillNum][2] + data.skill[skillNum][1];
		}
		
		public static function levelSkill(amount:uint, skillNum:uint, skills:Array, skillProgress:Array):void
		{
			skillProgress[skillNum] += amount;
			while (true)
			{
				var cost:uint = getSkillCost(skillNum, skills[skillNum]);
				if (skillProgress[skillNum] >= cost)
				{
					skillProgress[skillNum] -= cost;
					skills[skillNum] += 1;
				}
				else
					return;
			}
		}
		
		public static function getRandomitems(list:uint, picks:uint):Array
		{
			var table:Array = data.miscitemslist[list];
			var items:Array = new Array();
			for (var i:uint = 0; i < picks; i++)
			{
				var pick:uint = (table.length - 1) / 3;
				pick = Math.random() * pick;
				var min:uint = table[2 + 3 * pick];
				var max:uint = table[3 + 3 * pick];
				var num:uint = (max - min) * Math.random() + min;
				if (num != 0) //it's possible to roll a 0
				{
					var item:Stackable = new Stackable(table[1 + 3 * pick]);
					item.multiply(num);
					items.push(item);
				}
			}
			return items;
		}
	}
}