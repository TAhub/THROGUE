package game 
{
	import flash.geom.Point;
	import net.flashpunk.World;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	public class CharacterCreation extends World
	{
		private static const MAXBALDCATEGORY:uint = 7;
		private static const MAXCATEGORY:uint = 10;
		private static const NAMELESS:String = "Nameless";
		private var p:Player;
		
		//player statistics
		private var job:uint;
		private var hairStyle:uint;
		private var hairColor:uint;
		private var skinColor:uint;
		private var eyeColor:uint;
		private var gender:uint;
		private var crime:uint;
		private var name:String;
		
		//interface statistics
		private var categoryOn:uint;
		
		public function CharacterCreation() 
		{
			loadDefaultCharacter();
			categoryOn = 0;
			
			generatePlayer();
		}
		
		private function saveDefaultCharacter():void
		{
			Saver.loadDefaultCharacter();
			
			var on:uint = 0;
			Saver.defaultCharacter[on++] = name;
			Saver.defaultCharacter[on++] = job;
			Saver.defaultCharacter[on++] = hairStyle;
			Saver.defaultCharacter[on++] = hairColor;
			Saver.defaultCharacter[on++] = skinColor;
			Saver.defaultCharacter[on++] = eyeColor;
			Saver.defaultCharacter[on++] = gender;
			Saver.defaultCharacter[on++] = crime;
			
			Saver.closeDefaultCharacter();
		}
		
		private function loadDefaultCharacter():void
		{
			Saver.loadDefaultCharacter();
			
			if (Saver.defaultCharacter.length == 0)
			{
				name = NAMELESS;
				job = 0;
				hairStyle = 0;
				hairColor = 0xFFFFFF;
				skinColor = 0;
				eyeColor = 0;
				gender = 0;
				crime = 0;
			}
			else
			{
				var on:uint = 0;
				name = Saver.defaultCharacter[on++];
				job = Saver.defaultCharacter[on++];
				hairStyle = Saver.defaultCharacter[on++];
				hairColor = Saver.defaultCharacter[on++];
				skinColor = Saver.defaultCharacter[on++];
				eyeColor = Saver.defaultCharacter[on++];
				gender = Saver.defaultCharacter[on++];
				crime = Saver.defaultCharacter[on++];
			}
			
			Saver.closeDefaultCharacter();
		}
		
		private function nameAppend(start:String, end:String, cStart:uint):void
		{
			var adjustment:int = cStart - start.charCodeAt(0);
			for (var i:uint = start.charCodeAt(0); i <= end.charCodeAt(0); i++)
			{
				if (Input.pressed(i + adjustment))
				{
					if (name == NAMELESS)
						name = "";
					name += String.fromCharCode(i);
				}
			}
		}
		
		public override function update():void
		{
			if (categoryOn > maxCategory)
				categoryOn = maxCategory;
			
			if (categoryOn == 0)
			{
				if (Input.pressed(Key.BACKSPACE))
				{
					if (name == NAMELESS)
						name = "";
					else
						name = name.substr(0, name.length - 1);
				}
				else
				{
					nameAppend(" ", " ", Key.SPACE);
					if (Input.check(Key.SHIFT))
						nameAppend("A", "Z", Key.A);
					else
						nameAppend("a", "z", Key.A);
				}
			}
				
				
			var vAdd:int = 0;
			if (Input.pressed(Key.UP))
				vAdd -= 1;
			if (Input.pressed(Key.DOWN))
				vAdd += 1;
				
			categoryOn = wrapAdd(categoryOn, maxCategory, vAdd);
			
			if (vAdd == 0 && categoryOn == maxCategory)
			{
				if (Input.pressed(Key.SPACE))
				{
					//save the player and start the game
					p.save(Saver.playerArray);
					saveDefaultCharacter();
					Main.startMap();
				}
			}
			else if (vAdd == 0)
			{
				var hAdd:int = 0;
				if (Input.pressed(Key.LEFT))
					hAdd -= 1;
				if (Input.pressed(Key.RIGHT))
					hAdd += 1;
					
				if (categoryOn == 7)
				{
					hairColor = FP.getColorRGB(colorChange(FP.getRed), FP.getGreen(hairColor), FP.getBlue(hairColor));
					generatePlayer();
				}
				else if (categoryOn == 8)
				{
					hairColor = FP.getColorRGB(FP.getRed(hairColor), colorChange(FP.getGreen), FP.getBlue(hairColor));
					generatePlayer();
				}
				else if (categoryOn == 9)
				{
					hairColor = FP.getColorRGB(FP.getRed(hairColor), FP.getGreen(hairColor), colorChange(FP.getBlue));
					generatePlayer();
				}
				else if (hAdd != 0)
				{
					switch (categoryOn)
					{
					case 1: //job
						job = wrapAdd(job, Main.data.occupation.length - 1, hAdd);
						break;
					case 2: //crime
						crime = wrapAdd(crime, Main.data.crime.length - 1, hAdd);
						break;
					case 3: //gender
						gender = wrapAdd(gender, 1, hAdd);
						break;
					case 4: //skincolor
						skinColor = wrapAdd(skinColor, 4, hAdd);
						break;
					case 5: //eyecolor
						eyeColor = wrapAdd(eyeColor, 4, hAdd);
						break;
					case 6: //hairstyle
						if (hairStyle == 0 && hAdd == -1)
							hairStyle = Database.NONE;
						else if (hairStyle == Creature.NUMHAIRSTYLES - 1 && hAdd == 1)
							hairStyle = Database.NONE;
						else if (hairStyle == Database.NONE && hAdd == -1)
							hairStyle = Creature.NUMHAIRSTYLES - 1;
						else if (hairStyle == Database.NONE && hAdd == 1)
							hairStyle = 0;
						else
							hairStyle += hAdd;
						break;
					}
					generatePlayer();
				}
			}
		}
		
		private function colorChange(reduce:Function):uint
		{
			var c:uint = reduce(hairColor);
			var dir:int = 0;
			if (Input.check(Key.LEFT))
				dir -= 1;
			if (Input.check(Key.RIGHT))
				dir += 1;
			if (c == 0 && dir == -1)
				return c;
			if (c == 0xFF && dir == 1)
				return c;
			return c + dir;
		}
		
		private function get maxCategory():uint
		{
			if (hairStyle == Database.NONE)
				return MAXBALDCATEGORY;
			else
				return MAXCATEGORY;
		}
		
		private function wrapAdd(value:uint, max:uint, add:int):uint
		{
			if (value == max && add == 1)
				value = 0;
			else if (value == 0 && add == -1)
				value = max;
			else
				value += add;
			return value;
		}
		
		private function generatePlayer():void
		{
			Item.count = false;
			p = new Player(0, 0, Main.data.occupation[job][1], 0, Main.STARTLEVEL, true);
			p.setPlayerStats(gender, hairColor, hairStyle, skinColor, eyeColor, job, crime, name);
			Item.count = true;
		}
		
		private function drawCategory(text:String, heightNumber:uint, selected:Boolean, description:String):void
		{
			var pt:Point = new Point(0, Map.TILESIZE + 15 * heightNumber);
			var t:Text = new Text(text);
			if (selected)
				t.color = 0xFFFFFF;
			else
				t.color = 0x999999;
				
			t.render(FP.buffer, pt, FP.camera);
			
			if (description && selected)
			{
				var d:Text = new Text(Player.processLine(description));
				d.render(FP.buffer, new Point(200, 0), FP.camera);
			}
		}
		
		public override function render():void
		{
			FP.camera.x = 0;
			FP.camera.y = 0;
			
			p.render();
			super.render();
			
			var hOn:uint = 0;
			var cOn:uint = 0;
			drawCategory("Name: " + name, hOn++, categoryOn == cOn++, null);
			drawCategory("Background:", hOn++, categoryOn == 1 || categoryOn == 2, null);
			drawCategory("Occupation: " + Main.data.occupation[job][0], hOn++, categoryOn == cOn++, "Before your exile...@" + Main.data.lines[Main.data.occupation[job][4]]);
			drawCategory("Crime: " + Main.data.crime[crime][1], hOn++, categoryOn == cOn++, "You are in the Waste because...@" + Main.data.lines[Main.data.crime[crime][2]]);
			drawCategory("Appearance: ", hOn++, categoryOn >= cOn && categoryOn != maxCategory, null);
			if (gender == 0)
				drawCategory("Gender: Male", hOn++, categoryOn == cOn++, null);
			else
				drawCategory("Gender: Female", hOn++, categoryOn == cOn++, null);
			drawCategory("Skin Color: " + (1 + skinColor), hOn++, categoryOn == cOn++, null);
			drawCategory("Eye Color: " + (1 + eyeColor), hOn++, categoryOn == cOn++, null);
			if (hairStyle != Database.NONE)
			{
				drawCategory("Hair Style: " + (1 + hairStyle), hOn++, categoryOn == cOn++, null);
				drawCategory("Hair Red: " + FP.getRed(hairColor), hOn++, categoryOn == cOn++, null);
				drawCategory("Hair Green: " + FP.getGreen(hairColor), hOn++, categoryOn == cOn++, null);
				drawCategory("Hair Blue: " + FP.getBlue(hairColor), hOn++, categoryOn == cOn++, null);
			}
			else
				drawCategory("Hair Style: None", hOn++, categoryOn == cOn++, null);
			drawCategory("Finish", hOn++, categoryOn == cOn++, "Press SPACE to finish and start the game.");
		}
	}

}