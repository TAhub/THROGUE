package game 
{
	import flash.events.TransformGestureEvent;
	import net.flashpunk.FP;
	
	public class AI extends Creature
	{
		private var path:Array;
		private var pMap:PathMap;
		private var target:Creature;
		private var moveDelay:Number;
		private var moveLeft:uint;
		private var done:Boolean;
		private var hasMoved:Boolean;
		private var immobile:Boolean;
		private static const MAXMOVEDELAY:Number = 0.15;
		public var myChest:uint;
		
		public function AI(_x:uint, _y:uint, cclass:uint, faction:uint, difficulty:uint, generate:Boolean) 
		{
			super(_x, _y, cclass, faction, difficulty, generate);
			
			path = null;
			pMap = null;
			target = null;
			moveDelay = 0;
			moveLeft = 0;
			myChest = 0;
		}
		
		public function switchTarget(attacker:Creature):void
		{
			target = attacker;
		}
		
		public override function skipTurn():Boolean
		{
			//skip your turn if you are offscreen and targetless
			//to speed up the process
			if (!target && (!onscreen || 
				(!(FP.world as Map).squareIsVisible(x, y) && !(FP.world as Map).player.xray)))
			{
				resetStun();
				return true;
			}
			else
				return super.skipTurn();
		}
		
		public override function turnStart(applyEffects:Boolean):void
		{
			super.turnStart(applyEffects);
			moveLeft = movespeed;
			done = false;
			hasMoved = false;
			if (moveLeft == 0)
			{
				//so the turn doesnt end immediately
				moveLeft = 1;
				immobile = true;
			}
			else
				immobile = false;
		}
		
		private function hostileTo(to:Creature):Boolean
		{
			/**
			if (faction != 0)
				return false;
			/**/
			if (faction == 0 && to.isPlayer)
				return (FP.world as Map).crime; //friendlies wont attack you unless you have done something bad on this map
			if (faction == 0 || (to.faction == 0 && !to.isPlayer))
				return false; //enemies and NPCs ignore each other
			return to.faction != faction;
		}
		
		public function isTargetingPlayer():Boolean
		{
			if (!target)
				return false;
			return target.isPlayer;
		}
		
		public override function update():void
		{
			super.update();
			
			if (animating)
				return;
			
			if (moveDelay > 0 && onscreen)
			{
				moveDelay -= FP.elapsed;
				return;
			}
			
			if (done)
			{
				//finish up!
				path = null;
				pMap = null;
				moveDelay = 0;
				(FP.world as Map).moveOver();
				return;
			}
			
			if (target && target.dead)
				target = null;
			if (!target)
			{
				if (onscreen)
				{
					//get a target
					var oth:Array = (FP.world as Map).getOthers(this);
					var valid:Array = new Array();
					for (var i:uint = 0; i < oth.length; i++)
						if (inSightRange(oth[i]) && hostileTo(oth[i]) &&
							(!(oth[i] as Creature).isPlayer || //when trying to spot the player, YOU need to be visible
							(aug && aug.xray) || //if you have an xray eye you can see them through the wall
							(FP.world as Map).squareIsVisible(x, y))) //IE no seeing them through walls
							valid.push(oth[i]);
					if (valid.length > 0)
					{
						var picked:uint = Math.random() * valid.length;
						target = valid[picked];
						trace("HAS A TARGET! " + target);
					}
				}
			}
			if (!target)
			{
				//couldn't find a target
				//so just stop here, don't use the done mechanic
				(FP.world as Map).moveOver();
			}
			else if (moveLeft == 0)
				done = true; //you can't move anymore
							//this might be because you have moved too far, or because
							//you just attacked
							//either way just stop here
			else
			{
				if ((!hasMoved && (allInRange(target, true) || hasSlowWeapon()))
					|| moveLeft == 1 || (path && path.length == 0))
				{
					//you either haven't started moving, or are almost done
					//so try to attack, if you're in range
					
					var canSpecial:Boolean = inSpecialRange(target);
					var canAttack:Boolean = inRange(target, !hasMoved);
					if (canSpecial && (!canAttack || specialChance))
					{
						useSpecial(target);
						moveLeft = 0;
						return;
					}
					else if (canAttack)
					{
						attack(target, !hasMoved);
						moveLeft = 0;
						return;
					}
				}
				
				if (!pMap && !path && !immobile)
				{
					//get a pathing map
					pMap = (FP.world as Map).getPathMap(x, y);
				}
				if (!pMap && !path)
					done = true; //getting a pathing map failed somehow; perhaps its because you are immobile?
				else
				{
					if (!path)
					{
						//get a destination location
						//and a pathing map to there
						valid = pMap.getValidSpaces();
						picked = Math.random() * valid.length;
						var iClosest:uint;
						var closestDis:uint;
						var iBest:uint;
						var bestRating:uint;
						for (i = 0; i < valid.length; i++)
						{
							var iPos:uint = valid[i];
							
							//is it closer than the closest?
							var dis:uint = Math.abs((FP.world as Map).getX(iPos) - target.x) +
											Math.abs((FP.world as Map).getY(iPos) - target.y);
							if (i == 0 || dis < closestDis)
							{
								iClosest = iPos;
								closestDis = dis;
							}
							
							//is it better than the best?
							var rating:uint = ratePosition(iPos, target);
							if (i == 0 || rating > bestRating)
							{
								iBest = iPos;
								bestRating = rating;
							}
						}
						if (bestRating == 0) //you can't get in range of the enemy, so go to the closest
							path = pMap.getPathTo(iClosest);
						else
							path = pMap.getPathTo(iBest);
						
						pMap = null; //you no longer need it
					}
					if (!path)
						done = true; //couldn't find anywhere to go
					else
					{
						//follow the next step of the path
						if (path.length == 0)
							done = true; //youre there!
						else
						{
							var iTo:uint = path.pop();
							if (move((FP.world as Map).getX(iTo), (FP.world as Map).getY(iTo)))
								moveLeft = 0;
							else
								moveLeft -= 1;
							moveDelay = MAXMOVEDELAY;
							hasMoved = true;
						}
					}
				}
			}
		}
	}

}