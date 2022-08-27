// *************************************************************************
//  
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//
// *************************************************************************

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// flags
bool JB_bind_pressed[MAXPLAYERS + 1]; // is bind pressed or not
bool tick_counter[MAXPLAYERS + 1]; // is tick counting running
bool touched_ground[MAXPLAYERS + 1];
bool ducking[MAXPLAYERS + 1];
// prediction 
float prev_origin_z[MAXPLAYERS + 1]; // previous z postion
float vel_z[MAXPLAYERS + 1];
float prev_vel_z[MAXPLAYERS + 1];
int cont[MAXPLAYERS + 1]; // couting how many ticks player will be crouched
// hud
int hit_color[MAXPLAYERS + 1][4];
Handle jb_hud[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "auto jumpbug",
	author = "bolo",
	description = "makes jumpbugs :)",
	version = "1.0",
	url = ""
};

public void OnPluginStart(){
	
	init_global_vars();
	
	RegConsoleCmd("+jumpbug", JumpBug_ON);
	RegConsoleCmd("-jumpbug", JumpBug_OFF);
}


public void init_global_vars(){
	
	for (int i = 0; i < MAXPLAYERS+1; i++){	
		// flags
		JB_bind_pressed[i] = false;
		tick_counter[i] = false;
		touched_ground[i] = false;
		ducking[i] = false;
		// prediction 
		prev_origin_z[i] = -9999.0;
		vel_z[i] = 0.0;
		prev_vel_z[i] = 0.0;
		cont[i] = 3;
		// hud
		hit_color[i] = { 255, 255, 255, 0 };
		jb_hud[i] = CreateHudSynchronizer();
	}	
}

public Action JumpBug_ON(int client, int args){	
	JB_bind_pressed[client] = true;
	tick_counter[client] = false;
	touched_ground[client] = false;
	ducking[client] = false;
	prev_origin_z[client] = -9999.0;
	vel_z[client] = 0.0;
	prev_vel_z[client] = 0.0;
	cont[client] = 3;
	hit_color[client] =  { 255, 255, 255, 0 };
}

public Action JumpBug_OFF(int client, int args){
	JB_bind_pressed[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]){	
	
	if (IsPlayerAlive(client)){
		if(JB_bind_pressed[client]){
			JB_HUD(client,true);
			Jumpbug(client, buttons);
		}
		else{
			JB_HUD(client,false);
		}
	}
	return Plugin_Continue;
}

public void Jumpbug(int client, int &buttons){
	
	float pos[3]; // store position where ray hits
	float origin[3]; // store origin position
	Get_Origin_And_Ground(client,origin,pos); // trace rays to find closest ground height

	vel_z[client] = prev_origin_z[client] - origin[2];
	
	// if player is falling and is not on floor or ladder (falling can be misunderstood as walking down) and duck ticker is not running
	if(prev_vel_z[client] > 0 && !(GetEntityFlags(client) & FL_ONGROUND || GetEntityMoveType(client) & MOVETYPE_LADDER) && !tick_counter[client] ){

		int t = cont[client] + 1;
		ducking[client] = false;
		
		if(buttons & IN_DUCK){ // player is crouching
			t = 1;
			ducking[client] = true;
		}
		
		float next_origin_z = origin[2] - vel_z[client] * t + 0.5 * (prev_vel_z[client] - vel_z[client]) * t * t;
		
		if (next_origin_z <= pos[2] || (ducking[client] && next_origin_z-pos[2] <= 9)){
			tick_counter[client] = true;
			if(ducking[client]){ 
				cont[client] = 0; // skip ducking ticks
			}
		}
	}
	
	// hold duck for x ticks
	if(tick_counter[client] && cont[client] > 0){
		buttons |= IN_DUCK;
		cont[client] -= 1;
	}
	
	// cont finished reset values
	if(cont[client] <= 0){
		JumpBug_Detection(client, origin[2]);
		
		if(ducking[client]){ // player was ducked lets unduck for x ticks
			buttons &= ~IN_DUCK;
		}
		
		if(prev_origin_z[client] - origin[2] < 0 || touched_ground[client]){
			cont[client] -= 1;
		}
		// wait a few tick before restarting ( bad fix for double jb ) or hold unduck for x ticks before restarting
		if(cont[client] == -5){
			tick_counter[client] = false;
			cont[client] = 3;
			touched_ground[client] = false;
			ducking[client] = false;
		}
	}
		
	prev_origin_z[client] = origin[2]; // update previous z
	prev_vel_z[client] = vel_z[client];
}

public void JumpBug_Detection(int client,float z){
	
	// touched the ground
	if(GetEntityFlags(client) & FL_ONGROUND || touched_ground[client]){
		touched_ground[client] = true;
		hit_color[client] =  { 255, 255, 255, 0 };
		JB_HUD(client,true);
	}
	
	// going up and didnt touch the ground ( after uncrouch )
	if(prev_origin_z[client] - z < 0 && !touched_ground[client]){
		hit_color[client] = { 0, 255, 0, 0 };
		JB_HUD(client,true);	
	}
}

public void JB_HUD(int client, bool draw){
	
	SetHudTextParamsEx(-1.0, 0.6, 1.0, hit_color[client], _, 0, 1.0, 0.0, 0.0);
	
	if(draw){
		ShowSyncHudText(client, jb_hud[client], "%s", "JB");
	}
	else{
		ShowSyncHudText(client, jb_hud[client], "%s", "");
	}
	
}

public void Get_Origin_And_Ground(int client,float origin[3], float hit_pos[3]){

	float end[3]; // end trace
	float temp[3];
	float aux[3];
	
	GetClientAbsOrigin(client, origin);
	GetClientAbsOrigin(client, end);
	
	end[2] += -50.0; // sub 50 to origin z so vector has 0,0,-1 direction
	origin[2] -= 2; // make starting point bellow player clip brush or else it will hit it self very sad :(
	aux[2] = origin[2];
	
	TR_TraceRay(origin, end, MASK_ALL, RayType_EndPoint);
	TR_GetEndPosition(hit_pos, INVALID_HANDLE);
	
	int traces; // number of traces around the player ( a total of 128 trace rays, the full player ground area is a total 1024 units)
	float pi = 3.1416;
	float increment; 
	float angle; 

	for (int radius = 2; radius <= 16; radius += 2){
		
		angle = pi / 2; // start at (0,1)
		traces = radius*4; // number of traces around the player
		increment = (2 * pi) / traces;
		for (int i = 0; i <= traces; i++){
			
			float x = Cosine(angle)*radius;
			float y = Sine(angle) * radius;
			angle += increment;
			
			aux[0] = origin[0] + x;
			aux[1] = origin[1] + y;
			end[0] = origin[0] + x;
			end[1] = origin[1] + y;
	
			TR_TraceRay(aux, end, MASK_ALL, RayType_EndPoint);
			TR_GetEndPosition(temp, INVALID_HANDLE);
			
			if(temp[2]>hit_pos[2]){
				hit_pos[2] = temp[2];
			}
		
		}
	}
	
	origin[2] += 2; // original z

}
