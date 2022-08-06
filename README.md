# Auto JumpBug Plugin

An auto jumpbug plugin for sourcemod.

This plugin tries to automate the execution of jumpbugs, currently it doesn't perform all jb's with 100% accuracy but its close, this is a result of the way it was implemented, it doesn't change stamina or any similar value, it ray traces the ground to determine when to crouch and uncrouch.

## Usage
* bind the jumpbug key in game console

  ```sh
  bind "key" +jumpbug
  ```
 While holding down bind key, +jump needs to be executed at the same time with a different key or bind.
 
## Work in Progess (WIP)
This project is a work in progress so it´s subject to changes.

* Known bugs:
  
  When hitting a jumpbug the walking sound is still played ( not going to fix )
  
  When holding jumpbug bind and +duck, the plugin might not hit the the jb but no sound will be played ( not going to fix )
