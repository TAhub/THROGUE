package game
{
	public class Database 
	{
		
		[Embed(source = "data/data.txt", mimeType = "application/octet-stream")] private static const DATA:Class;
		[Embed(source="data/lines.txt", mimeType = "application/octet-stream")] private static const LINES:Class;
		
		public static const NONE:uint = 9999;
		public var limbtype:Array = new Array();
		public var armor:Array = new Array();
		public var morph:Array = new Array();
		public var weapon:Array = new Array();
		public var eyemorph:Array = new Array();
		public var colormorph:Array = new Array();
		public var limbtable:Array = new Array();
		public var skill:Array = new Array();
		public var armortrack:Array = new Array();
		public var cclass:Array = new Array();
		public var tile:Array = new Array();
		public var stackable:Array = new Array();
		public var stackableCategory:Array = new Array();
		public var specialattack:Array = new Array();
		public var lines:Array = new Array();
		public var recipie:Array = new Array();
		public var recipieType:Array = new Array();
		public var encountertable:Array = new Array();
		public var miscitemslist:Array = new Array();
		public var equiploot:Array = new Array();
		public var specialeffect:Array = new Array();
		public var faction:Array = new Array();
		public var chest:Array = new Array();
		public var mapType:Array = new Array();
		public var augment:Array = new Array();
		public var augmentType:Array = new Array();
		public var tilelist:Array = new Array();
		public var layedTrap:Array = new Array();
		public var trapList:Array = new Array();
		public var specialTileEffect:Array = new Array();
		public var occupation:Array = new Array();
		public var crime:Array = new Array();
		public var pitEffect:Array = new Array();
		public var merchantType:Array = new Array();
		
		public function Database() 
		{
			var fillerData:Array = new Array();
			
			//read lines
			var lineNames:Array = new Array();
			var data:Array = new LINES().toString().split("\n");
			for (var i:uint = 0; i < data.length - 1; i++)
			{
				var line:String = data[i];
				if (line.charAt(0) != "/")
				{
					var lineName:String = "";
					var lineContent:String = "";
					var onName:Boolean = true;
					for (var j:uint = 0; j < line.length; j++)
					{
						if (onName && line.charAt(j) == " ")
							onName = false;
						else if (onName)
							lineName += line.charAt(j);
						else
							lineContent += line.charAt(j);
					}
					lineNames.push(lineName);
					lines.push(lineContent);
				}
			}
			
			//read data
			
			data = new DATA().toString().split("\n");
			
			//analyze data
			var allArrays:Array = new Array();
			//remember to push each data array into allarrays
			//if you don't put something into allArrays, it won't be linked with anything
			
			allArrays.push(limbtype);
			allArrays.push(skill);
			allArrays.push(armor);
			allArrays.push(weapon);
			allArrays.push(morph);
			allArrays.push(limbtable);
			allArrays.push(eyemorph);
			allArrays.push(colormorph);
			allArrays.push(armortrack);
			allArrays.push(stackableCategory);
			allArrays.push(stackable);
			allArrays.push(specialeffect);
			allArrays.push(specialattack);
			allArrays.push(cclass);
			allArrays.push(tile);
			allArrays.push(recipieType);
			allArrays.push(recipie);
			allArrays.push(miscitemslist);
			allArrays.push(encountertable);
			allArrays.push(equiploot);
			allArrays.push(faction);
			allArrays.push(chest);
			allArrays.push(mapType);
			allArrays.push(pitEffect);
			allArrays.push(augment);
			allArrays.push(augmentType);
			allArrays.push(tilelist);
			allArrays.push(layedTrap);
			allArrays.push(trapList);
			allArrays.push(specialTileEffect);
			allArrays.push(occupation);
			allArrays.push(crime);
			allArrays.push(merchantType);
			
			var arrayOn:Array;
			for (i = 0; i < data.length; i++)
			{
				line = data[i];
				line = line.substr(0, line.length - 1);
				if (line.charAt(0) != "/")
				{
					switch(line)
					{
					case "MERCHANTTYPE:":
						arrayOn = merchantType;
						break;
					case "PITEFFECT:":
						arrayOn = pitEffect;
						break;
					case "CRIME:":
						arrayOn = crime;
						break;
					case "OCCUPATION:":
						arrayOn = occupation;
						break;
					case "SPECIALTILEEFFECT:":
						arrayOn = specialTileEffect;
						break;
					case "TRAPLIST:":
						arrayOn = trapList;
						break;
					case "LAYEDTRAP:":
						arrayOn = layedTrap;
						break;
					case "TILELIST:":
						arrayOn = tilelist;
						break;
					case "AUGMENT:":
						arrayOn = augment;
						break;
					case "AUGMENTTYPE:":
						arrayOn = augmentType;
						break;
					case "MAPTYPE:":
						arrayOn = mapType;
						break;
					case "CHEST:":
						arrayOn = chest;
						break;
					case "FACTION:":
						arrayOn = faction;
						break;
					case "SPECIALEFFECT:":
						arrayOn = specialeffect;
						break;
					case "EQUIPLOOT:":
						arrayOn = equiploot;
						break;
					case "MISCITEMLIST:":
						arrayOn = miscitemslist;
						break;
					case "ENCOUNTERTABLE:":
						arrayOn = encountertable;
						break;
					case "RECIPIE:":
						arrayOn = recipie;
						break;
					case "RECIPIETYPE:":
						arrayOn = recipieType;
						break;
					case "SPECIALATTACK:":
						arrayOn = specialattack;
						break;
					case "STACKABLE:":
						arrayOn = stackable;
						break;
					case "STACKABLECATEGORY:":
						arrayOn = stackableCategory;
						break;
					case "CCLASS:":
						arrayOn = cclass;
						break;
					case "TILE:":
						arrayOn = tile;
						break;
					case "EQUIPTRACK:":
						arrayOn = armortrack;
						break;
					case "SKILL:":
						arrayOn = skill;
						break;
					case "ARMOR:":
						arrayOn = armor;
						break;
					case "MORPH:":
						arrayOn = morph;
						break;
					case "EYEMORPH:":
						arrayOn = eyemorph;
						break;
					case "COLORMORPH:":
						arrayOn = colormorph;
						break;
					case "LIMBTYPE:":
						arrayOn = limbtype;
						break;
					case "FILLERDATA:":
						arrayOn = fillerData;
						break;
					case "WEAPON:":
						arrayOn = weapon;
						break;
					case "LIMBTABLE:":
						arrayOn = limbtable;
						break;
					default:
						//tbis is a data line
						var ar:Array = line.split(" ");
						var newEntry:Array = new Array();
						for (j = 0; j < ar.length; j++)
						{
							//see if it's a string or a number
							if (j == 0)
								newEntry.push(ar[j]); //it's the name
							else if (ar[j] == "none") //it's an empty reference
								newEntry.push(NONE);
							else if (ar[j] == "true")
								newEntry.push(1);
							else if (ar[j] == "false")
								newEntry.push(0);
							else if (isNaN(ar[j]))
							{
								var st:String = ar[j] as String;
								if (st.charAt(0) == "@") //it's a line!
								{
									if (ar[j] == "@none") //it's an empty line
										newEntry.push(NONE);
									else
									{
										//find the line
										var foundLine:Boolean = false;
										for (var k:uint = 0; k < lineNames.length; k++)
											if ("@" + lineNames[k] == ar[j])
											{
												foundLine = true;
												newEntry.push(k);
												break;
											}
										if (!foundLine)
										{
											trace("Unable to find line " + ar[j]);
											newEntry.push(NONE);
										}
									}
								}
								else
									newEntry.push(st);
							}
							else
								newEntry.push((uint) (ar[j]));
						}
						//push the finished list
						arrayOn.push(newEntry);
						break;
					}
				}
			}
			
			//link them
			link(allArrays);
		}
		
		private function link(allArrays:Array):void
		{
			for (var i:uint = 0; i < allArrays.length; i++)
			{
				var arrayOn:Array = allArrays[i];
				
				for (var j:uint = 0; j < arrayOn.length; j++)
				{
					var entry:Array = arrayOn[j];
					
					for (var k:uint = 1; k < entry.length; k++)
					{
						if (isNaN(entry[k]))
						{
							var st:String = entry[k] as String;
							if (st.charAt(0) == "#") //it's a literal word
							{
								var newSt:String = "";
								for (var l:uint = 1; l < st.length; l++)
								{
									if (st.charAt(l) == "#")
										newSt += " ";
									else
										newSt += st.charAt(l);
								}
								entry[k] = newSt;
							}
							else
							{
								//link it somewhere
								
								var found:Boolean = false;
								for (l = 0; l < allArrays.length && !found; l++)
								{
									var arrayCheck:Array = allArrays[l];
									
									for (var m:uint = 0; m < arrayCheck.length; m++)
									{
										if (arrayCheck[m][0] == st)
										{
											entry[k] = m;
											found = true;
											break;
										}
									}
								}
								
								if (!found)
									trace("Unable to find " + entry[k]);
							}
						}
					}
				}
			}
		}
	}

}