Ashen Banner Texture Debug Build

Commands added:
/lvtexdebug or /abtexdebug
  Opens an in-game swatch window showing every TGA texture path the addon is trying to load.
  Also prints the texture root and whether the main frame exists.

/lvskin or /abskin
  Forces the skin pass on the currently built/visible addon window.

Expected texture root:
Interface\\AddOns\\LeafVillageLegends\\Textures\\

Important install note:
The folder must be exactly:
World of Warcraft\\Interface\\AddOns\\LeafVillageLegends\\

Inside it, these files must exist:
Textures\\ashen_bg_solid.tga
Textures\\ashen_bg_smoke.tga
Textures\\ashen_header_banner.tga
Textures\\ashen_panel_border.tga
Textures\\ashen_button_red.tga
Textures\\ashen_button_red_hover.tga
Textures\\ashen_button_red_down.tga
Textures\\ashen_scroll_track.tga
Textures\\ashen_scroll_thumb.tga
Textures\\ashen_scroll_arrow_up.tga
Textures\\ashen_scroll_arrow_down.tga
Textures\\ashen_rank_plate.tga
Textures\\ashen_icon_locked_overlay.tga

If /lvtexdebug shows empty/green/white boxes, WoW is not loading the files from that path. That usually means the addon folder name is different, the Textures folder is not inside the addon folder, or the game needs a full restart.
