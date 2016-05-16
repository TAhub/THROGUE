package game 
{
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.Entity;
	
	public class HitText extends Entity
	{
		private static const RISERATE:Number = 40;
		private static const FADERATE:Number = 2;
		private static const FADESTART:Number = 0.5;
		private var contents:Text;
		private var timer:Number;
		private var d:Number;
		
		public function HitText(str:String, over:Creature, delay:Number) 
		{
			x = over.x * Map.TILESIZE;
			y = over.y * Map.TILESIZE;
			contents = new Text(str);
			graphic = contents;
			timer = 0;
			d = delay;
		}
		
		public override function update():void
		{
			if (d > 0)
			{
				d -= FP.elapsed;
				visible = false;
			}
			else
			{
				visible = true;
				timer += FP.elapsed;
				y -= RISERATE * FP.elapsed;
				if (timer > FADESTART)
				{
					contents.alpha -= FADERATE * FP.elapsed;
					if (contents.alpha <= 0)
						FP.world.remove(this);
				}
			}
		}
		
	}

}