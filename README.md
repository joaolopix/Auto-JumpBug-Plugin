# Auto JumpBug Plugin

A auto jumpbug plugin for sourcemod.

This plugin tries to automate the execution of jumpbugs, currently it doesn't perform all jb's with 100% accuracy, this is a result of the way it was implemented, it doesn't change stamina or any similar value, it ray traces the ground to determine when to crouch and uncrouch.

## Usage
* bind the jumpbug key in game console

  ```sh
  bind "key" +jumpbug
  ```
 While holding down bind key, +jump needs to be executed at the same time with a different key or bind.
 
## Work in Progess (WIP)
This project is a work in progress so it´s subject to changes.

Currently when performing a jumpbug the landing sound still plays, probably cant be fixed.

Ray tracing the ground still needs work, diagonal edges may not be detected.

Delta to crouch also needs work.
