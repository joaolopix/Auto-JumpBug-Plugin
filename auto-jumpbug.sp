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
bool JB_bind_pressed = false; // is bind pressed or not
bool tick_counter = false; // is tick counting running
bool touched_ground = false;
bool ducking = false;

// prediction 
float prev_origin_z = -9999.0; // previous z postion
float vel_z = 0.0;
float prev_vel_z = 0.0;
int cont = 3; // counting how many ticks player will be crouched

// hud
int hit_color[4] =  { 255, 255, 255, 0 };
Handle jb_hud = null;

public Plugin myinfo = {
	name = "auto jumpbug",
	author = "bolo",
	description = "makes jumpbugs :)",
	version = "1.0",
	url = ""
};

public void OnPluginStart(){
	
	RegConsoleCmd("+jumpbug", JumpBug_ON);
	RegConsoleCmd("-jumpbug", JumpBug_OFF);
	
	jb_hud = CreateHudSynchronizer();
}

public Action JumpBug_ON(int client, int args){
	JB_bind_pressed = true;
	tick_counter = false;
	touched_ground = false;
	ducking = false;
	prev_origin_z = -9999.0;
	vel_z = 0.0;
	prev_vel_z = 0.0;
	cont = 3;
	hit_color =  { 255, 255, 255, 0 };
}

public Action JumpBug_OFF(int client, int args){
	JB_bind_pressed = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]){	
	
	if (IsPlayerAlive(client)){
	
		if(JB_bind_pressed){
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

	vel_z = prev_origin_z - origin[2];
	
	// if player is falling and is not on floor or ladder (falling can be misunderstood as walking down) and duck ticker is not running
	if(prev_vel_z > 0 && !(GetEntityFlags(client) & FL_ONGROUND || GetEntityMoveType(client) & MOVETYPE_LADDER) && !tick_counter ){

		int t = cont + 1;
		ducking = false;
		if(buttons & IN_DUCK){ // player is crouching
			t = 1;
			ducking = true;
		}
		float next_origin_z = origin[2] - vel_z * t + 0.5 * (prev_vel_z - vel_z) * t * t;
		
		if (next_origin_z <= pos[2] || (ducking && next_origin_z-pos[2] <= 9)){
			tick_counter = true;
			if(ducking){ 
				cont = 0; // skip ducking ticks
			}
		}
	}
	
	// hold duck for x ticks
	if(tick_counter && cont > 0){
		buttons |= IN_DUCK;
		cont -= 1;
	}
	
	// cont finished reset values
	if(cont <= 0){
		JumpBug_Detection(client, origin[2]);
		
		if(ducking){ // player was ducking lets unduck for x ticks
			buttons &= ~IN_DUCK;
		}
		
		if(prev_origin_z - origin[2] < 0 || touched_ground){
			cont -= 1;
		}
		// wait a few tick before restarting ( bad fix for double jb ) or hold unduck for x ticks before restarting
		if(cont == -5){
			tick_counter = false;
			cont = 3;
			touched_ground = false;
			ducking = false;
		}
	}
		
	prev_origin_z = origin[2]; // update previous z
	prev_vel_z = vel_z; // update previous velocity
}

public void JumpBug_Detection(int client,float z){
	
	// touched the ground
	if(GetEntityFlags(client) & FL_ONGROUND || touched_ground){
		touched_ground = true;
		hit_color =  { 255, 255, 255, 0 };
		JB_HUD(client,true);
	}
	
	// going up and didnt touch the ground ( after uncrouch )
	if(prev_origin_z - z < 0 && !touched_ground){
		hit_color = { 0, 255, 0, 0 };
		JB_HUD(client,true);	
	}
}

public void JB_HUD(int client, bool draw){
	
	SetHudTextParamsEx(-1.0, 0.6, 1.0, hit_color, _, 0, 1.0, 0.0, 0.0);
	
	if(draw){
		ShowSyncHudText(client, jb_hud, "%s", "JB");
	}
	else{
		ShowSyncHudText(client, jb_hud, "%s", "");
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

