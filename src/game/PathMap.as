package game 
{
	import net.flashpunk.FP;
	
	public class PathMap 
	{
		public static const UNEXPLORED:uint = 0;
		public static const BEGINNING:uint = 1;
		public static const NORTH:uint = 2;
		public static const EAST:uint = 3;
		public static const WEST:uint = 4;
		public static const SOUTH:uint = 5;
		
		private static const TRAPPENALTY:uint = 2;
		
		private var width:uint;
		private var height:uint;
		private var left:uint;
		private var top:uint;
		
		private var distances:Array;
		private var directions:Array;
		
		public function PathMap(l:uint, r:uint, u:uint, d:uint) 
		{
			left = l;
			top = u;
			width = r - l + 1;
			height = d - u + 1;
			
			distances = new Array();
			directions = new Array();
			
			for (var i:uint = 0; i < width * height; i++)
			{
				distances.push(0);
				directions.push(UNEXPLORED);
			}
		}
		
		private function getInnerI(outerI:uint):uint
		{
			var x:uint = (FP.world as Map).getX(outerI) - left;
			var y:uint = (FP.world as Map).getY(outerI) - top;
			return width * y + x;
		}
		
		private function getOuterI(innerI:uint):uint
		{
			var x:uint = innerI % width;
			x += left;
			var y:uint = innerI / width;
			y += top;
			return (FP.world as Map).getI(x, y);
		}
		
		public function getRandomPosition():uint
		{
			var i:uint = Math.random() * width * height;
			return getOuterI(i);
		}
		
		public function getValidSpaces():Array
		{
			var valid:Array = new Array();
			for (var i:uint = 0; i < width * height; i++)
				if (directions[i] != UNEXPLORED)
					valid.push(getOuterI(i));
			valid.sort(Main.randomize);
			return valid;
		}
		
		public function getPathTo(i:uint):Array
		{
			i = getInnerI(i);
			
			var path:Array = new Array();
			while (directions[i] != BEGINNING)
			{
				path.push(getOuterI(i));
				switch(directions[i])
				{
				case NORTH:
					i -= width;
					break;
				case SOUTH:
					i += width;
					break;
				case WEST:
					i -= 1;
					break;
				case EAST:
					i += 1;
					break;
				}
			}
			return path;
		}
		
		public function exploreFrom(i:uint):void
		{
			i = getInnerI(i);
			directions[i] = BEGINNING;
			var iQ:Array = new Array();
			iQ.push(i);
			
			while (iQ.length > 0)
			{
				explore(iQ);
				if (Math.random() < 0.3)
					iQ.sort(Main.randomize);
			}
		}
		
		private function explore(iQ:Array):void
		{
			var i:uint = iQ.pop();
			
			var d:uint = distances[i] + 1;
			
			var x:int = i % width;
			var y:int = i / width;
			
			exploreOne(x - 1, y, d, EAST, iQ);
			exploreOne(x + 1, y, d, WEST, iQ);
			exploreOne(x, y - 1, d, SOUTH, iQ);
			exploreOne(x, y + 1, d, NORTH, iQ);
		}
		
		private function exploreOne(x:int, y:int, d:uint, dir:uint, iQ:Array):void
		{
			if (x < 0 || y < 0 || x >= width || y >= height)
				return; //out of bounds
				
			var i:uint = x + y * width;
			
			if ((FP.world as Map).trapAt(x, y))
				d += TRAPPENALTY; //you would run into a trap, so discourage this move
			
			if (directions[i] != UNEXPLORED && distances[i] <= d)
				return; //there's already a better path there
			
			if (!(FP.world as Map).spaceEmptyI(getOuterI(i)))
				return; //it's solid
				
			//explore from there
			directions[i] = dir;
			distances[i] = d;
			iQ.push(i);
		}
		
		public function valid(i:uint):Boolean
		{
			var x:uint = (FP.world as Map).getX(i);
			var y:uint = (FP.world as Map).getY(i);
			return x >= left && y >= top && x < left + width && y < top + height;
		}
	}

}