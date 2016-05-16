package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	
	public class Player extends Creature
	{
		[Embed(source = "sprites/interfaceparts.png")] private static const INTERFACEPARTS:Class;
		private static const INTERFACEPARTSIZE:uint = 10;
		private static const sprIntParts:Spritemap = new Spritemap(INTERFACEPARTS, INTERFACEPARTSIZE, INTERFACEPARTSIZE);
		
		//gameplay constants
		private static const BASEENCUMBRANCE:uint = 3000;
		
		private var moveLeft:uint;
		private var phase:uint;
		private var targets:Array;
		private var transaction:Array;
		private var targetOn:uint;
		private var hasMoved:Boolean;
		private var talkingTo:AI;
		
		public function savePlayerState(toArray:Array):void
		{
			toArray.push(moveLeft);
			toArray.push(hasMoved);
		}
		
		public function loadPlayerState(fromArray:Array):void
		{
			var on:uint = 0;
			moveLeft = fromArray[on++];
			hasMoved = fromArray[on++];
		}
		
		public function Player(_x:uint, _y:uint, cclass:uint, faction:uint, difficulty:uint, generate:Boolean)
		{
			super(_x, _y, cclass, faction, difficulty, generate);
			canLevel = true;
			_isPlayer = true;
			moveLeft = 0;
			phase = 0;
			if (generate)
			{
				//reset skill progress
				for (var i:uint = 0; i < skillProgress.length; i++)
					skillProgress[i] = 0;
			}
		}
		
		public override function turnStart(applyEffects:Boolean):void
		{
			super.turnStart(applyEffects);
			moveLeft = movespeed;
			if (phase == 1) //dont change if you were in your inventory
				phase = 0; //free move
			hasMoved = false;
			
			if (encumbrance >= maxEncumbrance)
				moveLeft = 1;
		}
		
		private function moveControls():Boolean
		{
			var xAdd:int = 0;
			var yAdd:int = 0;
			if (Input.pressed(Key.LEFT))
				xAdd = -1;
			else if (Input.pressed(Key.RIGHT))
				xAdd = 1;
			else if (Input.pressed(Key.UP))
				yAdd = -1;
			else if (Input.pressed(Key.DOWN))
				yAdd = 1;
			if ((xAdd != 0 || yAdd != 0) && (FP.world as Map).inBounds(x + xAdd, y + yAdd))
			{
				var hit:Creature = (FP.world as Map).creatureAtXY(x + xAdd, y + yAdd);
				if (hit)
				{
					if (hit.faction == 0 && !(FP.world as Map).crime)
					{
						//talk to them instead
						resetVariables();
						talkingTo = hit as AI;
						targetOn = 1;
						
						//load merchant phase
						phase = 6;
						transaction = new Array();
					}
					else if (inRange(hit, !hasMoved))
					{
						attack(hit, !hasMoved);
						moveLeft = 0;
					}
				}
				else if ((xAdd != -1 || x != 0) && (yAdd != -1 || y != 0) &&
						(FP.world as Map).spaceEmptyXY(x + xAdd, y + yAdd))
				{
					if (!hasMoved && (FP.world as Map).someoneTargetingPlayer)
						hasMoved = true;
					if (move(x + xAdd, y + yAdd))
						moveLeft = 0;
					else
						moveLeft -= 1;
					(FP.world as Map).centerCamera(x, y);
				}
				return false;
			}
			return true; //not getting move input, so you can take other input
		}
		
		public function sortByCategory(a:Item, b:Item):int
		{
			if (a.category == b.category)
				return a.orderID - b.orderID;
			else
				return a.category - b.category;
		}
		
		private function get selectedItem():Item
		{
			var invOn:uint = 0;
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep && !wep.unlisted && invOn++ == targetOn)
					return wep;
			}
			for (i = 0; i < armors.length; i++)
			{
				var arm:Armor = armors[i];
				if (arm && !arm.unlisted && invOn++ == targetOn)
					return arm;
			}
			if (aug && invOn++ == targetOn)
				return aug;
			for (i = 0; i < pack.length; i++)
				if (invOn++ == targetOn)
					return pack[i];
			return null;
		}
		
		private function get invLength():uint
		{
			var len:uint = pack.length;
			for (var i:uint = 0; i < armors.length; i++)
				if (armors[i] != null && !(armors[i] as Armor).unlisted)
					len += 1;
			if (aug)
				len += 1;
			for (i = 0; i < weapons.length; i++)
				if (weapons[i] != null && !(weapons[i] as Weapon).unlisted)
					len += 1;
			return len;
		}
		
		private function targetControls():Boolean
		{
			var targetAdd:int = 0;
			if (Input.pressed(Key.LEFT))
				targetAdd -= 1;
			if (Input.pressed(Key.RIGHT))
				targetAdd += 1;
			if (targetAdd == -1 && targetOn == 0)
				targetOn = targets.length - 1;
			else if (targetAdd == 1 && targetOn == targets.length - 1)
				targetOn = 0;
			else
				targetOn += targetAdd;
			
			if (Input.pressed(Key.SPACE))
			{
				attack(targets[targetOn], !hasMoved);
				targets = null;
				moveLeft = 0;
				return false;
			}
				
			return targetAdd == 0;
		}
		
		private function drawLimb(x:uint, y:uint, arm:Armor, spr:uint, flipped:Boolean):void
		{
			var percentage:Number;
			if (!arm)
				sprIntParts.color = 0x000000;
			else
				sprIntParts.color =
					((0xFF * arm.percentage) << 8) +
					((0xFF * (1 - arm.percentage)) << 16);
			sprIntParts.frame = spr;
			sprIntParts.flipped = flipped;
			sprIntParts.render(FP.buffer, new Point(x, y), new Point(0, 0));
		}
		
		private function drawWeapons(y:uint):uint
		{
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep)
				{
					sprIcons.frame = Main.data.skill[wep.skill][3];
					
					if (!wep.slow || !hasMoved)
						sprIcons.color = 0x00FF00;
					else
						sprIcons.color = 0xFF0000;
						
					if (wep.ammoID != Database.NONE)
					{
						var num:uint = numOfItem(wep.ammoID);
						if (num == 0)
							sprIcons.color = 0xFF0000;
						var amTx:Text = new Text("" + num);
						amTx.width = FP.width - ICONSIZE;
						amTx.align = "right";
						amTx.render(FP.buffer, new Point(0, y), new Point(0, 0));
					}
						
					sprIcons.render(FP.buffer, new Point(FP.width - ICONSIZE, y), new Point(0, 0));
					
					y += ICONSIZE;
				}
			}
			return y;
		}
		
		public function renderUnderInterface():void
		{
			if (targets)
			{
				//draw targeting
				for (var i:uint = 0; i < targets.length; i++)
				{
					var t:Creature = targets[i];
					var c:uint = 0x990000;
					if (i == targetOn)
						c = 0xFF0000;
					FP.buffer.fillRect(new Rectangle(t.x * Map.TILESIZE - FP.camera.x,
													t.y * Map.TILESIZE - FP.camera.y,
													Map.TILESIZE, Map.TILESIZE), c);
				}
			}
		}
		
		private function drawMiscText(str:String, yOn:uint):uint
		{
			if (!str)
				return yOn;
				
			var txt:Text = new Text(str);
			txt.align = "right";
			txt.width = FP.width;
			txt.render(FP.buffer, new Point(0, yOn), new Point(0, 0));
			
			return yOn + ICONSIZE;
		}
		
		private function getNamePlace(rec:uint):uint
		{
			switch(getCraftArray(rec))
			{
			case Main.data.stackable:
				return 5;
				break;
			case Main.data.armor:
				return 13;
				break;
			default:
				return 0;
			}
		}
		
		public function renderOverInterface():void
		{
			//draw the sidebar
			
			drawMiscText(name, 0);
			
			//head
			drawLimb(FP.width - 2 * INTERFACEPARTSIZE, ICONSIZE, armors[0], 0, false);
			//left arm
			drawLimb(FP.width - 3 * INTERFACEPARTSIZE, INTERFACEPARTSIZE + ICONSIZE, armors[1], 2, true);
			//right arm
			drawLimb(FP.width - INTERFACEPARTSIZE, INTERFACEPARTSIZE + ICONSIZE, armors[2], 2, false);
			//right leg
			drawLimb(FP.width - 2 * INTERFACEPARTSIZE, 2 * INTERFACEPARTSIZE + ICONSIZE, armors[3], 3, false);
			//left leg
			drawLimb(FP.width - 2 * INTERFACEPARTSIZE, 2 * INTERFACEPARTSIZE + ICONSIZE, armors[4], 3, true);
			//body
			drawLimb(FP.width - 2 * INTERFACEPARTSIZE, INTERFACEPARTSIZE + ICONSIZE, armors[5], 1, false);
			
			//draw weapons
			var yOn:uint = drawWeapons(3 * INTERFACEPARTSIZE + ICONSIZE);
			
			//draw misc values
			yOn = drawMiscText("" + moveLeft, yOn);
			yOn = drawMiscText("" + Math.round(encumbrance * 100.0 / maxEncumbrance) + "%", yOn);
			yOn = drawMiscText(satName, yOn);
			yOn = drawMiscText(hydrName, yOn);
			yOn = drawMiscText(poisonName, yOn);
			
			
			if (phase == 2 && moveLeft > 0)
			{
				//draw description of current item
				var itOn:Item = selectedItem;
				var nameTxt:Text = new Text(itOn.name);
				var efTxt:Text = new Text(processLine(itOn.getEffectText(skills, strBonus)));
				nameTxt.render(FP.buffer, new Point(200, 15), new Point(0, 0));
				efTxt.render(FP.buffer, new Point(200, 30), new Point(0, 0));
				
				//draw inventory
				var inOn:uint = 0;
				var hOn:uint = 0;
				//draw weapons
				{
					drawInvText("WEAPONS:", false, hOn++);
					for (var i:uint = 0; i < weapons.length; i++)
					{
						var wep:Weapon = weapons[i];
						if (wep && !wep.unlisted)
							drawInvText(wep.name, (inOn++ == targetOn), hOn++);
					}
				}
				//draw armors
				{
					if (inOn != 0)
						hOn += 1;
					drawInvText("ARMORS:", false, hOn++);
					for (i = 0; i < armors.length; i++)
					{
						var arm:Armor = armors[i];
						if (arm && !arm.unlisted)
							drawInvText(arm.name, (inOn++ == targetOn), hOn++);
					}
				}
				//draw augment
				if (aug)
				{
					if (inOn != 0)
						hOn += 1;
					drawInvText("AUGMENT:", false, hOn++);
					drawInvText(aug.name, (inOn++ == targetOn), hOn++);
				}
				//draw pack
				{
					if (inOn != 0)
						hOn += 1;
					drawInvText("BACKPACK:", false, hOn++);
					for (i = 0; i < pack.length; i++)
						drawInvText((pack[i] as Item).name, (inOn++ == targetOn), hOn++);
				}
			}
			else if (phase == 3 && moveLeft > 0)
			{
				var ch:Array = (FP.world as Map).getChestAtXY(x, y);
				itOn = ch[targetOn];
				nameTxt = new Text(itOn.name);
				efTxt = new Text(processLine(itOn.getEffectText(skills, strBonus)));
				nameTxt.render(FP.buffer, new Point(200, 15), new Point(0, 0));
				efTxt.render(FP.buffer, new Point(200, 30), new Point(0, 0));
				
				drawInvText("CONTAINER:", false, 0);
				for (i = 1; i < ch.length; i++)
					drawInvText((ch[i] as Item).name, targetOn == i, i);
			}
			else if (phase == 4 && moveLeft > 0)
			{
				var recs:Array = validRecipies;
				var selRec:Array = Main.data.recipie[recs[targetOn]];
				nameTxt = new Text(getCraftArray(recs[targetOn])[selRec[1]][getNamePlace(recs[targetOn])]);
				var efStr:String = "";
				for (i = 0; i < 3; i++)
				{
					var itemID:uint = selRec[8 + 2 * i];
					var itemNum:uint = selRec[9 + 2 * i];
					if (itemID != Database.NONE)
					{
						if (efStr.length != 0)
							efStr += "\n";
						efStr += Main.data.stackable[itemID][0] + " x" + itemNum + " (have " + numOfItem(itemID) + ")";
					}
				}
				efTxt = new Text(efStr);
				nameTxt.render(FP.buffer, new Point(200, 15), new Point(0, 0));
				efTxt.render(FP.buffer, new Point(200, 30), new Point(0, 0));
				
				var sef:uint = (FP.world as Map).getTileEffectAt(x, y);
				var sefName:String;
				if (sef != Database.NONE)
					sefName = Main.data.specialTileEffect[sef][1];
				else
					sefName = "By Hand";
				drawInvText("Crafting (" + sefName + "):", false, 0);
				for (i = 0; i < recs.length; i++)
				{
					drawInvText(getCraftArray(recs[i])[Main.data.recipie[recs[i]][1]][getNamePlace(recs[i])], i == targetOn, i + 1);
				}
			}
			else if (phase == 5 && moveLeft > 0)
			{
				drawInvText("SKILLS:", false, 0);
				hOn = 1;
				for (i = 0; i < skills.length; i++)
				{
					if (skills[i] != 0 || skillProgress[i] != 0)
					{
						var sTxt:String = Main.data.skill[i][9] + " level " + skills[i];
						if (skillProgress[i] != 0)
							sTxt += " (" + Math.round(skillProgress[i] * 100.0 / Main.getSkillCost(i, skills[i])) +
									"% of the way to " + (skills[i] + 1) + ")";
						drawInvText(sTxt, false, hOn++);
					}
				}
			}
			else if (phase == 6 && moveLeft > 0)
			{
				if (targetOn != shopInventory.length)
				{
					if (targetOn > shopInventory.length)
						itOn = transaction[targetOn - shopInventory.length - 1];
					else
						itOn = shopInventory[targetOn];
					nameTxt = new Text(itOn.name);
					efTxt = new Text(processLine(itOn.getEffectText(skills, strBonus)));
					nameTxt.render(FP.buffer, new Point(200, 15), new Point(0, 0));
					efTxt.render(FP.buffer, new Point(200, 30), new Point(0, 0));
				}
				
				drawInvText("SHOP INVENTORY:", false, 0);
				for (i = 1; i < shopInventory.length; i++)
					drawInvText(shopInventory[i].name, targetOn == i, i + 1);
				drawInvText("Finish", targetOn == i, i + 2);
				if (transaction.length > 0)
				{
					i += 4;
					drawInvText("Purchasing:", false, i++);
					for (var j:uint = 0; j < transaction.length; j++)
						drawInvText(transaction[j].name, j == targetOn - shopInventory.length - 1, i++);
					
					i += 2;
					
					var tC:Array = transactionCost;
					if (!tC)
						drawInvText("Cannot Afford", false, i);
					else
					{
						drawInvText("Asking Price:", false, i++);
						for (j = 0; j < tC.length; j++)
							drawInvText(tC[j].name, false, i++);
					}
				}
			}
		}
		
		private function get baseVCost():uint
		{
			var vCost:uint = 0;
			for (var i:uint = 0; i < transaction.length; i++)
				vCost += transaction[i].value;
			return vCost;
		}
		
		private function get transactionCost():Array
		{
			//this will instantiate a lot of items, so turn off item counting for a sec
			Item.count = false;
			
			var cost:Array = new Array();
				
			//find the cost of what they are buying modify the cost by the player's merchantile value
			var vCostMod:Number = 2 - (skills[SKILLTRADE] * 0.1);
			if (vCostMod < 1)
				vCostMod = 1; //the minimum price multiplier
			var vCost:uint = baseVCost * vCostMod;
			
			//now find what items the player has that can be purchased with
			var possibleChange:Array = new Array();
			for (var i:uint = 0; i < pack.length; i++)
				if (pack[i].category == 2 && pack[i].useCategory == 6)
					possibleChange.push(pack[i].copy);
					
			//sort the change in descending order of BASE value
			possibleChange.sort(Main.valueSort);
			
			//now do an initial pass
			for (i = 0; i < possibleChange.length; i++)
			{
				while (vCost >= possibleChange[i].baseValue && possibleChange[i].number > 0)
				{
					cost.push(possibleChange[i].split);
					vCost -= possibleChange[i].baseValue;
				}
			}
			
			if (vCost > 0)
			{
				//if you can afford the item at all, this should be one coin away from paying from it now
				//so find your cheapest "coin"
				possibleChange.reverse();
				for (i = 0; i < possibleChange.length && vCost > 0; i++)
				{
					if (vCost <= possibleChange[i].baseValue && possibleChange[i].number > 0)
					{
						cost.push(possibleChange[i].split);
						vCost = 0;
					}
				}
			}
			
			Item.count = true;
			
			if (vCost > 0)
				return null; //you couldn't afford it
			
			//flatten cost
			for (i = 0; i < cost.length; i++)
			{
				var st:Stackable = cost[i];
				var newCost:Array = new Array();
				for (var j:uint = 0; j < cost.length; j++)
				{
					var st2:Stackable = cost[j];
					if (st2.id == st.id && st2 != st)
						st.combine(st2);
					else
						newCost.push(st2);
				}
				cost = newCost; //this shouldn't disrupt the order any, so no need to restart the for loop
			}
			
			return cost;
		}
		
		private function getCraftArray(rec:uint):Array
		{
			switch(Main.data.recipie[rec][2])
			{
			case 0:
				return Main.data.weapon;
			case 1:
				return Main.data.armor;
			case 2:
				return Main.data.stackable;
			}
			return null;
		}
		
		private function drawInvText(str:String, selected:Boolean, hOn:uint):void
		{
			var c:uint = 0x999999;
			if (selected)
				c = 0xFFFFFF;
			var txt:Text = new Text(str);
			txt.color = c;
			txt.render(FP.buffer, new Point(0, 12 * hOn), new Point(0, 0));
		}
		
		private function inventoryControls():Boolean
		{
			var invAdd:int = 0;
			if (Input.pressed(Key.UP))
				invAdd -= 1;
			if (Input.pressed(Key.DOWN))
				invAdd += 1;
			
			if (invAdd != 0)
			{
				if (targetOn == 0 && invAdd == -1)
					targetOn = invLength - 1;
				else if (targetOn == invLength - 1 && invAdd == 1)
					targetOn = 0;
				else
					targetOn += invAdd;
					
				return false;
			}
			else if (Input.pressed(Key.D))
			{
				drop(selectedItem, Input.check(Key.SHIFT));
				if (targetOn >= invLength)
					targetOn = invLength - 1;
				return false;
			}
			else if (Input.pressed(Key.SPACE))
			{
				//figure out what's selected
				var itSel:Item = selectedItem;
				switch(itSel.category)
				{
				case 0: //weapon
					if (pack.indexOf(itSel) != -1)
					{
						//it's in the pack, so equip it
						equipWeapon(itSel as Weapon, false);
					}
					else
					{
						//it's equipped, so remove it
						unequipWeapon(itSel as Weapon);
					}
					break;
				case 1: //armor
					if (pack.indexOf(itSel) != -1)
					{
						//it's in the pack, so equip it
						if (equipArmor(itSel as Armor))
							moveLeft = 0;
					}
					else
					{
						//it's equipped, so remove it
						unequipArmor(itSel as Armor);
						moveLeft = 0;
					}
					break;
				case 2: //stackable
					if (useItem(itSel as Stackable))
						moveLeft = 0;
					break;
				case 3: //augment
					if (pack.indexOf(itSel) != -1)
					{
						if (equipAugment(itSel as Augment))
							moveLeft = 0;
					}
					else
						unequipAugment();
					break;
				}
				
				if (targetOn >= invLength)
					targetOn = invLength - 1;
					
				return false;
			}
			else
				return true; //not doing anything, so take other input
		}
		
		public static function processLine(str:String):String
		{
			var newStr:String = "";
			for (var i:uint = 0; i < str.length; i++)
				if (str.charAt(i) == "@")
					newStr += "\n";
				else
					newStr += str.charAt(i);
			return newStr;
		}
		
		public function get sonar():Boolean
		{
			if (!aug)
				return false;
			else
				return aug.sonar;
		}
		
		public function get xray():Boolean
		{
			if (!aug)
				return false;
			else
				return aug.xray;
		}
		
		private function craftControls():Boolean
		{
			var valRec:Array = validRecipies;
			
			if (valRec.length == 0)
			{
				phase = 0;
				return true;
			}
			
			if (targetOn >= valRec.length)
				targetOn = valRec.length - 1;
			
			var yAdd:int = 0;
			if (Input.pressed(Key.UP))
				yAdd -= 1;
			if (Input.pressed(Key.DOWN))
				yAdd += 1;
			if (yAdd != 0)
			{
				if (targetOn == 0 && yAdd == -1)
					targetOn = valRec.length - 1;
				else if (targetOn == valRec.length - 1 && yAdd == 1)
					targetOn = 0;
				else
					targetOn += yAdd;
					
				return false;
			}
			if (Input.pressed(Key.SPACE))
			{
				craft(valRec[targetOn]);
				moveLeft = 0;
			}
			
			return true;
		}
		
		private function pickupControls():Boolean
		{
			var ch:Array = (FP.world as Map).getChestAtXY(x, y);
			
			var yAdd:int = 0;
			if (Input.pressed(Key.UP))
				yAdd -= 1;
			if (Input.pressed(Key.DOWN))
				yAdd += 1;
			if (yAdd != 0)
			{
				if (targetOn == 1 && yAdd == -1)
					targetOn = (ch.length - 1);
				else if (targetOn == ch.length - 1 && yAdd == 1)
					targetOn = 1;
				else
					targetOn += yAdd;
				
				return false;
			}
			if (Input.pressed(Key.SPACE))
			{
				if ((FP.world as Map).chestHasOwnerXY(x, y) && !(FP.world as Map).crime)
					(FP.world as Map).crime = true; //you committed a crime
				
				var picked:Item = ch[targetOn];
				if (ch[0] < Map.ACCESSEDCHEST)
					ch[0] += Map.ACCESSEDCHEST;
				
				var remove:Boolean = true;
				if (picked.category == 2 && !Input.check(Key.SHIFT))
				{
					var st:Stackable = picked as Stackable;
					if (st.number > 1)
					{
						inventoryAdd(st.split);
						remove = false;
					}
				}
					
				if (remove)
				{
					inventoryAdd(picked);
					for (var i:uint = targetOn; i < ch.length - 1; i++)
						ch[i] = ch[i + 1];
					ch.pop();
					
					if (ch.length == 1)
					{
						//auto exit pick up interface
						phase = 0;
						(FP.world as Map).removeChestAt(x, y);
					}
				}
				
				if (targetOn >= ch.length)
					targetOn = ch.length - 1;
				
				return false;
			}
			
			return true;
		}
		
		private function resetVariables():void
		{
			if (transaction && transaction.length > 0)
			{
				//return anything in the transaction to the owner
				for (var i:uint = 0; i < transaction.length; i++)
				{
					if (transaction[i].category == 2)
					{
						var st:Stackable = transaction[i] as Stackable;
						var found:Boolean = false;
						for (var j:uint = 1; j < shopInventory.length; j++)
							if (shopInventory[j].category == 2 && shopInventory[j].id == st.id)
							{
								shopInventory[j].combine(st);
								found = true;
								break;
							}
						if (!found)
							shopInventory.push(transaction[i]);
					}
					else
						shopInventory.push(transaction[i]);
				}
			}
			transaction = null;
			talkingTo = null;
			targets = null;
		}
		
		private function get shopInventory():Array
		{
			return (FP.world as Map).getChestAtI(talkingTo.myChest);
		}
		
		private function merchantControls():Boolean
		{
			var yAdd:int = 0;
			if (Input.pressed(Key.UP))
				yAdd -= 1;
			if (Input.pressed(Key.DOWN))
				yAdd += 1;
				
			if (targetOn == 1 && yAdd == -1)
				targetOn = shopInventory.length + transaction.length;
			else if (targetOn == shopInventory.length + transaction.length && yAdd == 1)
				targetOn = 1;
			else
				targetOn += yAdd;
				
			if (yAdd == 0)
			{
				if (Input.pressed(Key.SPACE))
				{
					if (targetOn > shopInventory.length)
					{
						//drop this
						var savedX:uint = x;
						var savedY:uint = y;
						setPosition((FP.world as Map).getX(talkingTo.myChest), (FP.world as Map).getY(talkingTo.myChest));
						var it:Item = transaction[targetOn - shopInventory.length - 1];
						drop(it, Input.check(Key.SHIFT));
						if (it.category == 2 && !Input.check(Key.SHIFT) && (it as Stackable).number > 1)
							(it as Stackable).split;
						else
						{
							var newT:Array = new Array();
							for (var i:uint = 0; i < transaction.length; i++)
								if (transaction[i] != it)
									newT.push(transaction[i]);
							transaction = newT;
							if (targetOn > transaction.length + shopInventory.length)
								targetOn -= 1;
						}
						setPosition(savedX, savedY);
					}
					else if (targetOn == shopInventory.length)
					{
						var tC:Array = transactionCost;
						if (tC)
						{
							//finish the current transaction
							
							//get EXP
							levelSkill(SKILLTRADE, baseVCost);
							
							//drop the money on the chest
							savedX = x;
							savedY = y;
							setPosition((FP.world as Map).getX(talkingTo.myChest), (FP.world as Map).getY(talkingTo.myChest));
							for (i = 0; i < tC.length; i++)
								for (var j:uint = 0; j < pack.length; j++)
									if (pack[j].category == 2 && pack[j].id == tC[i].id)
										for (var k:uint = 0; k < tC[i].number; k++)
											drop(pack[j], false);
							setPosition(savedX, savedY);
							
							//transfer the stuff in the transaction to your inventory
							for (i = 0; i < transaction.length; i++)
								inventoryAdd(transaction[i]);
							
							//your turn is over
							resetVariables();
							phase = 0;
							moveLeft = 0;
						}
					}
					else
					{
						//add it to the current transaction
						
						it = shopInventory[targetOn];
						
						if (it.category == 2 && !Input.check(Key.SHIFT) && (it as Stackable).number > 1)
						{
							//its a stackable, so split a piece off
							addToTransaction((it as Stackable).split);
						}
						else
						{
							//move the item directly
							addToTransaction(it);
							
							//remove it from the shop
							for (i = targetOn; i < shopInventory.length - 1; i++)
								shopInventory[i] = shopInventory[i + 1];
							shopInventory.pop();
						}
					}
				}
			}
			
			return true;
		}
		
		private function addToTransaction(it:Item):void
		{
			if (it.category == 2)
			{
				var st:Stackable = it as Stackable;
				for (var i:uint = 0; i < transaction.length; i++)
				{
					var it2:Item = transaction[i];
					if (it2.category == 2)
					{
						var st2:Stackable = it2 as Stackable;
						if (st2.id == st.id)
						{
							st2.combine(st);
							return;
						}
					}
				}
			}
			
			transaction.push(it);
		}
		
		public override function update():void
		{
			super.update();
			if (animating)
				return;
			if (moveLeft == 0)
			{
				(FP.world as Map).moveOver();
				return;
			}
			
			var otherInput:Boolean;
			switch(phase)
			{
			case 0:
				otherInput = moveControls();
				break;
			case 1:
				otherInput = targetControls();
				break;
			case 2:
				otherInput = inventoryControls();
				break;
			case 3:
				otherInput = pickupControls();
				break;
			case 4:
				otherInput = craftControls();
				break;
			case 5:
				otherInput = true; //skills screen has no controls
				break;
			case 6:
				otherInput = merchantControls();
				break;
			}
			if (otherInput)
			{
				//handle non-movement buttons
				if (Input.pressed(Key.ESCAPE))
				{
					resetVariables();
					moveLeft = 0;
					phase = 0;
				}
				else if (Input.pressed(Key.T))
					cmdTrace();
				else if (Input.pressed(Key.P))
				{
					//pick-up phase
					if (phase == 3)
						phase = 0;
					else if ((FP.world as Map).getChestAtXY(x, y)) //if there's something to pick up
					{
						phase = 3;
						resetVariables();
						targetOn = 1;
					}
				}
				else if (Input.pressed(Key.C))
				{
					//crafting phase
					if (phase == 4)
						phase = 0;
					else if (validRecipies.length != 0)
					{
						phase = 4;
						resetVariables();
						targetOn = 0;
					}
				}
				else if (Input.pressed(Key.K))
				{
					//skills phase
					if (phase == 5)
						phase = 0;
					else
					{
						phase = 5;
						resetVariables();
					}
				}
				else if (Input.pressed(Key.I))
				{
					//inventory phase
					if (phase == 2)
						phase = 0;
					else
					{
						phase = 2;
						resetVariables();
						targetOn = 0; //more like itemOn but w/e
					}
				}
				else if (Input.pressed(Key.S))
				{
					resetVariables();
					(FP.world as Map).save();
					Main.validShutdown();
				}
				else if (Input.pressed(Key.D))
				{
					(FP.world as Map).useStaircaseAt(x, y);
				}
				else if (Input.pressed(Key.A))
				{
					//attack phase
					if (phase == 1)
					{
						phase = 0;
						resetVariables();
					}
					else if (phase == 0)
					{
						phase = 1;
						targetOn = 0;
						targets = new Array();
						var others:Array = (FP.world as Map).getOthers(this);
						for (var i:uint = 0; i < others.length; i++)
						{
							var t:Creature = others[i];
							if (inRange(t, !hasMoved))
								targets.push(t);
						}
						if (targets.length == 0)
						{
							//nobody is in range
							targets = null;
							phase = 0;
						}
					}
				}
			}
		}
		
		private function get validRecipies():Array
		{
			var efOn:uint = (FP.world as Map).getTileEffectAt(x, y);
			var valRec:Array = new Array();
			for (var i:uint = 0; i < Main.data.recipie.length; i++)
			{
				//are you on the right station?
				if (Main.data.recipie[i][14] == efOn || Main.data.recipie[i][14] == Database.NONE)
				{
					//are your skills high enough?
					var valid:Boolean = true;
					for (var j:uint = 0; j < 2; j++)
					{
						var skillReq:uint = Main.data.recipie[i][3 + 2 * j];
						var skillNum:uint = Main.data.recipie[i][4 + 2 * j];
						if (skillReq != Database.NONE && skills[skillReq] < skillNum)
						{
							valid = false;
							break;
						}
					}
					
					if (valid)
					{
						//do you have the ingredients?
						for (j = 0; j < 3; j++)
						{
							var itemReq:uint = Main.data.recipie[i][8 + j * 2];
							var itemNum:uint = Main.data.recipie[i][9 + j * 2];
							if (itemReq != Database.NONE && !hasEnoughItem(itemReq, itemNum))
							{
								valid = false;
								break;
							}
						}
						
						if (valid)
							valRec.push(i);
					}
				}
			}
			
			return valRec;
		}
		
		private function get encumbrance():uint
		{
			var enc:uint = 0;
			for (var i:uint = 0; i < weapons.length; i++)
			{
				var wep:Weapon = weapons[i];
				if (wep)
					enc += wep.weight;
			}
			for (i = 0; i < pack.length; i++)
				enc += (pack[i] as Item).weight;
			return enc;
		}
		
		private function get maxEncumbrance():uint
		{
			return BASEENCUMBRANCE * strBonus;
		}
		
		private function hasEnoughItem(type:uint, num:uint):Boolean
		{
			return numOfItem(type) >= num;
		}
		
		private function drop(item:Item, dropAll:Boolean):void
		{
			if (item.category == 3 && item == aug)
			{
				if (aug.binds)
					return; //can't drop your eye on the floor
				else
					aug = null; //unequip it first, otherwise
			}
			
			//where is it in your inventory?
			if (weapons.indexOf(item) != -1)
				unequipWeapon(item as Weapon);
			else if (armors.indexOf(item) != -1)
				unequipArmor(item as Armor);
			
			//see if you should remove it from your inventory
			var remove:Boolean = true;
			var give:Item;
			if (item.category == 2 && !dropAll)
			{
				var st:Stackable = item as Stackable;
				if (st.number > 1)
				{
					give = st.split;
					remove = false;
				}
			}
			
			//remove it from your inventory if necessary
			if (remove)
			{
				give = item;
				var newA:Array = new Array();
				for (var i:uint = 0; i < pack.length; i++)
					if (pack[i] != item)
						newA.push(pack[i]);
				pack = newA;
			}
			
			placeItemOnGround(give, 0);
		}
	}

}