package game 
{
	import flash.net.SharedObject;
	
	public class Saver 
	{
		public static const SAVEPREFIX:String = "ryavis/throgue/";
		private static var profileName:String;
		private static var profile:SharedObject;
		private static var savedDC:SharedObject;
		
		private static function getLevelName(levelNumber:uint):String
		{
			return "" + SAVEPREFIX + profileName + "/level" + levelNumber;
		}
		
		public static function openProfile(name:String):void
		{
			profileName = name;
			profile = SharedObject.getLocal(SAVEPREFIX + profileName + "/profile");
			if (!profile.data.valid)
			{
				//wipe everything
				trace("WIPING PROFILE " + name);
				//delete the level files
				for (var i:uint = 1; i <= profile.data.levelGenOn; i++)
					SharedObject.getLocal(getLevelName(i)).clear();
				profile.data.player = null;
				profile.data.levelOn = 0;
				profile.data.levelGenOn = 0;
			}
			profile.data.valid = false;
		}
		
		public static function closeProfile():void
		{
			profile.data.valid = true;
			profile.close();
			profile = null;
		}
		
		public static function get defaultCharacter():Array
		{
			if (!savedDC.data.dC)
				savedDC.data.dC = new Array();
			return savedDC.data.dC;
		}
		
		public static function loadDefaultCharacter():void
		{
			savedDC =  SharedObject.getLocal(SAVEPREFIX + "defaultCharacter");
		}
		
		public static function closeDefaultCharacter():void
		{
			savedDC.close();
		}
		
		public static function playerExists():Boolean
		{
			return profile.data.player;
		}
		
		public static function get playerArray():Array
		{
			if (!profile.data.player)
				profile.data.player = new Array();
			
			return profile.data.player;
		}
		
		public static function get freeLevelNumber():uint
		{
			profile.data.levelGenOn += 1;
			return profile.data.levelGenOn;
		}
		
		public static function get levelOn():uint
		{
			if (profile.data.levelOn == 0)
				profile.data.levelOn = freeLevelNumber;
			return profile.data.levelOn;
		}
		
		public static function setLevelOn(levelOn:uint):void
		{
			profile.data.levelOn = levelOn;
		}
		
		public static function levelExists(levelNumber:uint):Boolean
		{
			var toCheck:SharedObject = SharedObject.getLocal(getLevelName(levelNumber));
			return (toCheck.data.tiles != null);
		}
		
		public static function save(levelNumber:uint, m:Map, savePlayer:Boolean):void
		{
			var toSave:SharedObject = SharedObject.getLocal(getLevelName(levelNumber));
			
			toSave.data.settings = new Array();
			m.saveSettings(toSave.data.settings);
			
			toSave.data.tiles = new Array();
			toSave.data.background = new Array();
			toSave.data.explored = new Array();
			m.saveTiles(toSave.data.tiles, toSave.data.background, toSave.data.explored);
			
			toSave.data.creatures = new Array();
			m.saveCreatures(toSave.data.creatures, savePlayer);
			
			toSave.data.chests = new Array();
			m.saveChests(toSave.data.chests);
			
			toSave.data.playerState = new Array();
			m.saveState(toSave.data.playerState);
			
			toSave.data.stairs = new Array();
			m.saveStairs(toSave.data.stairs);
			
			toSave.data.traps = new Array();
			m.saveTraps(toSave.data.traps);
			
			toSave.close();
		}
		
		public static function load(levelNumber:uint, m:Map):void
		{
			var toLoad:SharedObject = SharedObject.getLocal(getLevelName(levelNumber));
			
			m.loadSettings(toLoad.data.settings);
			
			m.loadTiles(toLoad.data.tiles, toLoad.data.background, toLoad.data.explored);
			m.loadCreatures(toLoad.data.creatures);
			m.loadChests(toLoad.data.chests);
			m.loadState(toLoad.data.playerState);
			m.loadStairs(toLoad.data.stairs);
			m.loadTraps(toLoad.data.traps);
			
			toLoad.clear();
			toLoad.close();
		}
	}

}