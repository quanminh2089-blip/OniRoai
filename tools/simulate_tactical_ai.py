#!/usr/bin/env python3
"""OniRoai 100-round TACTICAL proxy simulation (NOT running Godot).

Replicates key inputs of scripts/enemy.gd and arena.gd: five 500-HP NPCs;
10 damage per NPC hit; 500-HP player; 10 body / 250 headshot damage;
0.5s reaction; 0.7 nominal NPC accuracy; player 0.09s fire cooldown,
Aim Head selecting a visible target and ESP granting position knowledge.

Spatial/ballistic approximations are EXPLICITLY NOT the Godot physics engine.
Used to compare tactics under identical random seeds; NOT an APK win rate.
"""
from __future__ import annotations
from dataclasses import dataclass, field
import argparse
import collections
import json
import math
import heapq
import random
from typing import Optional
from functools import lru_cache

TICK = 0.10
MAX_T = 90.0
SPAWNS = [(-13., -20.), (-5., -22.), (5., -22.), (13., -20.), (0., -24.)]
PLAYER_START = (-12., 18.)
# Static obstacle footprints: approximations of fences, rock chunks, stone building,
# concrete road barriers, and other cover defined in scripts/round_map.gd.
# (center x, center z, half-width x, half-width z)
OBSTACLES = [
    (10,0,3.5,3.0),(-10,-1,1.3,.48),(0,11,1.8,.48),(-4,-16,.48,1.7),
    (15,-14,1.8,.48),(0,0,2.2,1.5),(-3,-2,1.3,1.9),
    (3,3,1.1,.8),(-16,5,1.7,1.9),(18,-11,1.5,1.8),
    (17,8,.65,.7),(-18,15,.65,.7),(-4,5,.8,.7),
    (15,14,2,.4),(18,-1,.45,2.5)
]


def clamp(v, a, b): return max(a, min(b, v))
def dist(a, b): return math.hypot(a[0]-b[0], a[1]-b[1])
def normalize(v):
    size=math.hypot(*v)
    return (v[0]/size, v[1]/size) if size>1e-7 else (0.,0.)
def add(a,b): return (a[0]+b[0],a[1]+b[1])
def scale(a,s): return (a[0]*s,a[1]*s)
def perpendicular(a): return (-a[1],a[0])

def segment_box(p, q, box):
    cx,cz,hx,hz=box
    # Slab segment intersection.
    lo,hi=0.,1.
    for axis,center,half in ((0,cx,hx),(1,cz,hz)):
        delta=q[axis]-p[axis]
        if abs(delta)<1e-9:
            if abs(p[axis]-center)<half: continue
            return False
        t1=(center-half-p[axis])/delta
        t2=(center+half-p[axis])/delta
        lo=max(lo,min(t1,t2));hi=min(hi,max(t1,t2))
        if hi<lo: return False
    return hi>0.002 and lo<0.998

def visible(p, q):
    return not any(segment_box(p,q,b) for b in OBSTACLES)

def clear(p):
    if not (-21<=p[0]<=21 and -25<=p[1]<=25): return False
    return all(not (abs(p[0]-x)<hx+.5 and abs(p[1]-z)<hz+.5)
               for x,z,hx,hz in OBSTACLES)

@lru_cache(maxsize=50000)
def route(source, target):
    # Small 4-neighbor A*: model approximates Godot's AStarGrid2D.
    source=(int(round(source[0])),int(round(source[1])))
    target=(int(round(target[0])),int(round(target[1])))
    if not clear(source):
        options=[(source[0]+x,source[1]+z) for x in range(-2,3) for z in range(-2,3)]
        options=[v for v in options if clear(v)]
        if options: source=min(options,key=lambda q:dist(q,source))
    if not clear(target):
        options=[(target[0]+x,target[1]+z) for x in range(-2,3) for z in range(-2,3)]
        options=[v for v in options if clear(v)]
        if options:target=min(options,key=lambda q:dist(q,target))
    frontier=[(dist(source,target),0,source)]
    cost={source:0};parents={}
    while frontier:
        _,length,current=heapq.heappop(frontier)
        if current==target:break
        if length>cost.get(current,math.inf):continue
        for ox,oz in ((1,0),(-1,0),(0,1),(0,-1)):
            following=(current[0]+ox,current[1]+oz)
            if not clear(following):continue
            nc=length+1
            if nc<cost.get(following,math.inf):
                cost[following]=nc
                parents[following]=current
                heapq.heappush(frontier,(nc+dist(following,target),nc,following))
    if target not in cost:return ()
    result=[]
    current=target
    while current!=source:
        result.append(current)
        current=parents[current]
    result.reverse()
    return tuple(result)


def move_toward(start,target,speed,dt):
    if dist(start,target)<.12:return start
    if visible(start,target):
        dest=target
    else:
        waypoints=route((round(start[0]),round(start[1])),(round(target[0]),round(target[1])))
        dest=next((pt for pt in waypoints if dist(start,pt)>.38),target)
    d=dist(start,dest)
    if d<.001:return start
    move=min(speed*dt,d)
    pos=(start[0]+(dest[0]-start[0])*move/d,start[1]+(dest[1]-start[1])*move/d)
    if clear(pos):return pos
    v=normalize((dest[0]-start[0],dest[1]-start[1]))
    for candidate in (add(start,scale(perpendicular(v),speed*dt)),
                      add(start,scale(perpendicular(v),-speed*dt))):
        if clear(candidate):return candidate
    return start


def find_cover(pos, player, bot_id, mates):
    desired=[12.,7.,18.,10.,13.][bot_id]
    candidates=[]
    for x,z,hx,hz in OBSTACLES:
        if dist(pos,(x,z))>15.: continue
        for at in ((x-hx-1.25,z),(x+hx+1.25,z),
                   (x,z-hz-1.25),(x,z+hz+1.25)):
            if not clear(at) or visible(at,player): continue
            if dist(at,player)<3 or dist(at,player)>32 or dist(at,pos)>15:continue
            if any(m.bot_id!=bot_id and m.hp>0 and
                   ((m.cover is not None and dist(at,m.cover)<1.8) or dist(at,m.pos)<1.8)
                   for m in mates): continue
            score=16-dist(at,pos)*.85-abs(dist(at,player)-desired)*.45
            candidates.append((score,at))
    if not candidates:return None
    return max(candidates,key=lambda item:item[0])[1]


def peek_at(cover, player, side):
    direction=normalize((player[0]-cover[0],player[1]-cover[1]));perp=perpendicular(direction)
    for sign in (side,-side):
        for amount in (1.7,2.7,3.8):
            candidate=add(add(cover,scale(perp,sign*amount)),scale(direction,.4))
            if clear(candidate) and visible(candidate,player): return candidate
    return None

@dataclass
class NPC:
    bot_id:int
    pos:tuple
    hp:int=500
    ready:float=.5
    fire_clock:float=.0
    shots_in_burst:int=0
    ammo:int=30
    reload_clock:float=0.
    under_fire:float=0.
    cover:Optional[tuple]=None
    cover_timer:float=0.
    peek:Optional[tuple]=None
    is_crouched:bool=False
    is_moving:bool=False
    recent_exposure:float=0.
    hits:int=0
    shots:int=0
    dodges:int=0
    cover_entries:int=0


def role_goal(bot_id, player, plan, player_start=PLAYER_START):
    forward=normalize((0-player[0],-19-player[1])); side=perpendicular(forward)
    depth=[13.,6.5,17.,-1.5,11.][bot_id]
    lateral=[-2.,3.5,-9.,12.5,8.][bot_id]
    if plan=='pinch': lateral*=1.3
    if plan=='pressure':depth-=3
    if plan=='reposition':lateral=-lateral
    target=add(add(player,scale(forward,depth)),scale(side,lateral))
    return (clamp(target[0],-20,20),clamp(target[1],-24,24))


def peek_window(bot_id,t):
    offset=[0.,1.1,2.1,3.,4.][bot_id]
    return (t+offset)%5.3 < (2.7 if bot_id in (2,4) else 2.1)


def run_round(seed:int, improved:bool):
    rng=random.Random(seed)
    player_pos=PLAYER_START
    player_hp=500.
    player_shot_clock=0.
    player_reload=0.
    player_ammo=30
    npc=[NPC(i,SPAWNS[i]) for i in range(5)]
    squad_last_known=None
    squad_memory=0.
    confirmed_kills=0
    progress_age=0.0
    player_search_age=0.0
    stat=collections.Counter()
    # Note: player has ESP information but Aim Head can only hit line-of-sight targets.
    # Both sides engage with actual obstruction LOS and hitpoint damage.
    for step in range(int(MAX_T/TICK)):
        t=step*TICK
        progress_age+=TICK
        alive=[n for n in npc if n.hp>0]
        if player_hp<=0 or not alive:break
        squad_memory=max(0.,squad_memory-TICK)
        if squad_memory<=0: squad_last_known=None
        plan='pressure' if progress_age>13 else ('crossfire','pinch','pressure','reposition')[(int(t/8.)+seed%4)%4]
        for bot in alive:
            bot.under_fire=max(0,bot.under_fire-TICK)
            bot.fire_clock=max(0,bot.fire_clock-TICK)
            bot.cover_timer-=TICK
            if bot.reload_clock>0:
                bot.reload_clock-=TICK
                if bot.reload_clock<=0: bot.ammo=30
            detection=(40 if improved else 30)+(6 if improved and bot.bot_id==2 else 0)
            sees=dist(bot.pos,player_pos)<=detection and visible(bot.pos,player_pos)
            if sees:
                if bot.ready<0: bot.ready=.5
                squad_last_known=player_pos
                squad_memory=7.
            if improved:
                force_push=progress_age>13 and bot.under_fire<=0
                prefer_cover=(bot.bot_id in (0,2,4) and not force_push) or bot.under_fire>0 or bot.hp<220
                known=squad_last_known if squad_memory>0 else None
                if prefer_cover:
                    if known is not None and bot.cover_timer<=0:
                        best=find_cover(bot.pos,known,bot.bot_id,npc)
                        if best and (not bot.cover or dist(bot.cover,best)>.6):
                            bot.cover=best;bot.peek=None
                        bot.cover_timer=rng.uniform(1.5,2.4)
                target=role_goal(bot.bot_id,known,plan) if known is not None else (-15+bot.bot_id*7,0.)
                in_cover=False
                if prefer_cover and known is not None and bot.cover is not None:
                    if dist(bot.pos,bot.cover)>1.2:
                        target=bot.cover
                    elif not peek_window(bot.bot_id,t) and not visible(bot.pos,player_pos):
                        in_cover=True
                    else:
                        if bot.peek is None or not visible(bot.peek,player_pos):
                            bot.peek=peek_at(bot.cover,known,1 if bot.bot_id%2==0 else -1)
                        if bot.peek:target=bot.peek
                if not in_cover:
                    old=bot.pos
                    bot.pos=move_toward(bot.pos,target,4.0 if bot.bot_id in (1,3) else 3.2,TICK)
                    bot.is_moving=dist(old,bot.pos)>.03
                else:
                    bot.is_moving=False
                    bot.cover_entries+=1
                bot.is_crouched=in_cover or bot.under_fire>0.5
            else:
                target=player_pos
                if bot.ready>.0 and sees:
                    old=bot.pos
                    bot.pos=move_toward(bot.pos,target,2.6,TICK)
                    bot.is_moving=dist(old,bot.pos)>.03
                else:
                    # Old script runs the patrol until a contact, with limited group action.
                    old=bot.pos
                    bot.pos=move_toward(bot.pos,(-14.+bot.bot_id*6,9.),2.7,TICK)
                    bot.is_moving=dist(old,bot.pos)>.03
            sees=dist(bot.pos,player_pos)<=detection and visible(bot.pos,player_pos)
            if sees and bot.ready>=0:bot.ready=max(0,bot.ready-TICK)
            if not sees:bot.ready=-1.0
            if sees and bot.ready==0 and bot.fire_clock<=0 and bot.reload_clock<=0:
                if bot.ammo<=0:
                    bot.reload_clock=2.45
                    stat['npc_reloads']+=1
                else:
                    bot.ammo-=1; bot.shots+=1
                    stat['npc_shots']+=1
                    bot.shots_in_burst=(bot.shots_in_burst+1)%3
                    bot.fire_clock=.13 if bot.shots_in_burst else .58
                    chance=.70
                    if bot.is_moving:chance*=.90
                    if rng.random()<chance:
                        player_hp-=10
                        progress_age=0.0
                        bot.hits+=1; stat['npc_hits']+=1
        # ESP-aware human pursues the nearest hidden NPC when all firing lanes are blocked.
        # Without this, a static player + defensive team creates artificial timeouts.
        seen_enemies=[b for b in npc if b.hp>0 and dist(player_pos,b.pos)<=65 and visible(player_pos,b.pos)]
        if not seen_enemies:
            player_search_age+=TICK
            if player_search_age>2.5:
                nearest=min((b for b in npc if b.hp>0),key=lambda b:dist(player_pos,b.pos),default=None)
                if nearest is not None:
                    player_pos=move_toward(player_pos,nearest.pos,3.3,TICK)
        else:
            player_search_age=0.0
        # Player with ESP can pick any visible threat; Aim Head automatically tracks
        # one exposed enemy (optimistic instant weapon orientation, 28°/65m cap).
        player_shot_clock-=TICK
        if player_reload>0:
            player_reload-=TICK
            if player_reload<=0:player_ammo=30
        if player_shot_clock<=0 and player_reload<=0:
            candidates=[b for b in npc if b.hp>0 and dist(player_pos,b.pos)<=65 and visible(player_pos,b.pos)]
            if candidates:
                bot=min(candidates,key=lambda b:dist(player_pos,b.pos))
                player_shot_clock=.09
                player_ammo-=1
                stat['player_shots']+=1
                hit_chance=.92 if not bot.is_moving else .78
                if bot.is_crouched:hit_chance*=.33
                if rng.random()<hit_chance:
                    headshot=(not bot.is_crouched) and rng.random()<.94
                    damage=250 if headshot else 10
                    bot.hp=max(0,bot.hp-damage)
                    progress_age=0.0
                    stat['player_hits']+=1
                    stat['player_headshots']+=int(headshot)
                    if bot.hp<=0:confirmed_kills+=1
                    elif improved:
                        bot.under_fire=3.5
                        bot.cover_timer=0.
                        bot.dodges+=1
                        squad_last_known=player_pos
                        squad_memory=7.
                if player_ammo<=0:
                    player_reload=2.45
        if player_hp<=0:stat['npc_victory']+=1
    outcome='player' if confirmed_kills==5 else ('npc' if player_hp<=0 else 'timeout')
    return {"winner":outcome,"seconds":round(min(MAX_T,step*TICK),2),
            "player_remaining_hp":int(max(0,player_hp)),"bots_killed":confirmed_kills,
            "cover_entries":sum(b.cover_entries>0 for b in npc),
            "bots_dodged":sum(b.dodges>0 for b in npc),"stat":stat}


def aggregate(rounds=100, start_seed=4900):
    report={"kind":"2D simplified controlled proxy, not Godot gameplay",
            "rounds_each":rounds,"seed_start":start_seed,
            "rules":{"npc_count":5,"npc_hp":500,"player_hp":500,"player_headshot_damage":250,
                     "player_body_damage":10,"npc_bullet_damage":10,"reaction_ms":500,
                     "npc_accuracy_nominal":0.70,"player_esp":True,"player_aim_head":True,
                     "ticks_per_second":10,"round_timeout_s":MAX_T},"variants":{}}
    for improved,name in [(False,'baseline_v1.5'),(True,'tactical_v1.6')]:
        results=[run_round(start_seed+i,improved) for i in range(rounds)]
        combined=collections.Counter()
        for r in results: combined.update(r['stat'])
        wins=collections.Counter(r['winner'] for r in results)
        report['variants'][name]={
            "player_wins":wins['player'],"npc_wins":wins['npc'],"timeouts":wins['timeout'],
            "mean_round_seconds":round(sum(r['seconds'] for r in results)/rounds,2),
            "mean_bots_killed":round(sum(r['bots_killed'] for r in results)/rounds,2),
            "mean_player_remaining_hp":round(sum(r['player_remaining_hp'] for r in results)/rounds,1),
            "rounds_using_cover":sum(r['cover_entries']>0 for r in results),
            "rounds_with_dodge_response":sum(r['bots_dodged']>0 for r in results),
            "shots_player":combined['player_shots'],
            "headshots_player":combined['player_headshots'],
            "shots_npc":combined['npc_shots'],
            "hits_npc":combined['npc_hits']}
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rounds',type=int,default=100)
    parser.add_argument('--seed',type=int,default=4900)
    parser.add_argument('--output',default='')
    args=parser.parse_args()
    result=aggregate(args.rounds,args.seed)
    rendered=json.dumps(result,ensure_ascii=False,indent=2)
    print(rendered)
    if args.output:
        from pathlib import Path
        Path(args.output).write_text(rendered+'\n',encoding='utf8')
