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

bool bind_pressed = false;
float prev_origin_z = -9999.0;
bool tick_counter = false;
int cont = 3;
float height = 4.0;

public Plugin myinfo = 
{
	name = "auto jumpbug",
	author = "bolo",
	description = "makes jumpbugs :)",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("+jumpbug", JumpBug_ON);
	RegConsoleCmd("-jumpbug", JumpBug_OFF);
	
}


public Action JumpBug_ON(int client, int args){
	bind_pressed = true;
	tick_counter = false;
	prev_origin_z = -9999.0;
	cont = 3;
}

public Action JumpBug_OFF(int client, int args){
	bind_pressed = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]){	
	
	if (IsPlayerAlive(client) && bind_pressed){
		
		float pos[3]; // store position where ray hits
		float origin[3]; // store origin position
		Get_Origin_And_Ground(client,origin,pos); // trace rays to find closest ground height
		
		float distance = origin[2] - pos[2]; // ground distance
		
		// if player is falling and is not on floor or ladder (falling can be misunderstood as walking down) and duck ticker is not running
		if(prev_origin_z - origin[2] > 0 && !(GetEntityFlags(client) & FL_ONGROUND || GetEntityMoveType(client) & MOVETYPE_LADDER) && !tick_counter ){

			// if distance is less then x + delta (has velo increases jumpbug delta must increase) and its above 0 (only for caution)
			if(distance <= height+(prev_origin_z - origin[2])*3 && distance >= 0.0){
				tick_counter = true;
			}
		}
		
		// hold duck for x ticks
		if(tick_counter && cont > 0){
			buttons |= IN_DUCK;
			cont -= 1;
		}
		
		// cont finished reset values
		if(cont <= 0 && prev_origin_z - origin[2] < 0){
			tick_counter = false;
			cont = 3;
		}
			
		prev_origin_z = origin[2]; // update previous z
	}
	
	return Plugin_Continue;
}

public void Get_Origin_And_Ground(int client,float origin[3], float hit_pos[3]){

	float end[3]; // end trace
	float temp[3];
	
	GetClientAbsOrigin(client, origin);
	GetClientAbsOrigin(client, end);
	
	end[2] += -50.0; // sub 50 to origin z so vector has 0,0,-1 direction
	origin[2] += -5; // make starting point bellow player clip brush or else it will hit it self very sad :(
	
	TR_TraceRay(origin, end, MASK_ALL, RayType_EndPoint);
	TR_GetEndPosition(hit_pos, INVALID_HANDLE);
	
	for (int i = 0; i <= 1; i++){
		
		origin[i] += 16;
		end[i] += 16;
		TR_TraceRay(origin, end, MASK_ALL, RayType_EndPoint);
		TR_GetEndPosition(temp, INVALID_HANDLE);
		if(temp[2]>hit_pos[2]){
			hit_pos[2] = temp[2];
		}
		origin[i] -= 32;
		end[i] -= 32;
		TR_TraceRay(origin, end, MASK_ALL, RayType_EndPoint);
		TR_GetEndPosition(temp, INVALID_HANDLE);
		if(temp[2]>hit_pos[2]){
			hit_pos[2] = temp[2];
		}
		origin[i] += 16;
		end[i] += 16;	
		
	}
	
	origin[2] += 5; // original z

}
