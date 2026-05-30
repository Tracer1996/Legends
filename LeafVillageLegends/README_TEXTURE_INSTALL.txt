Ashen Banner texture integration fix

Install:
1. Put the Textures folder in your addon root:
   Interface\AddOns\LeafVillageLegends\Textures\

2. Replace your addon UI/FrameSkins.lua with the included UI/FrameSkins.lua.

3. Full restart the game client. /reload is not enough if WoW cached failed texture paths.

Important:
- The Lua texture paths intentionally do NOT include .tga.
- The big textures were padded to power-of-two sizes for Vanilla / 1.12 compatibility.
- FrameSkins.lua now auto-skins the large visible addon window, because the main UI code was not actually calling the new texture helpers everywhere.

If your addon folder is NOT LeafVillageLegends, open UI/FrameSkins.lua and change:
LeafVE_FrameSkins.ADDON_FOLDER = LeafVE_FrameSkins.ADDON_FOLDER or "LeafVillageLegends"

to your exact addon folder name.
