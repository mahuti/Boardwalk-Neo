//
// Boardwalk-NeoGeo
// Theme by Mahuti
// vs. 2.1
// 
// thanks to Yaron for his shaders
//
local order = 0
class UserConfig {
		
    </ label="T-Molding Color", 
		help="Choose a specific t-molding color, or set it to change randomly.", 
		options="random,black,red,white", 
		order=order++ /> 
		tmolding_color="white";
		
    </ label="Bezel Color", 
		help="Choose a specific bezel color, or set it to change randomly.", 
		options="random,red,red stripes,gold stripes", 
		order=order++ /> 
		bezel_color="red";
    
    </ label="Enable lighted marquee effect", 
		help="Show the Marquee lit up", 
		options="Yes,No", 
		order=order++ /> 
		enable_Lmarquee="Yes";

    </ label="Show CRT bloom or lottes shaders", 
        help="Enable bloom or lottes effects for the snap video, if user device supports GLSL shaders", 
        options="No,CRT Bloom,CRT Lottes", 
        per_display="true",
        order=order++  /> 
        enable_snap_shader="No";

    </ label="Show CRT scanlines", 
        help="Show CRT scanline effect", 
        options="No,Light,Medium,Dark", 
        per_display="true",
        order=order++ /> 
        enable_crt_scanline="Light";
    
    </ label="Show Wheel Images", 
		help="Shows wheel images.", 
		options="Yes,No", 
		order=order++ /> 
		show_wheel="No";

    </ label="Instruction Cards", 
		help="Choose what should be shown in the instruction card space", 
		options="none, instructions, boxart, flyer",
		order=order++ /> 
		instruction_cards="instructions";

		
}
 

local config = fe.get_config();

// modules
fe.load_module("file"); 
fe.do_nut(fe.script_dir + "modules/pos.nut" );

// stretched positioning
local stretchData =  {
    base_width = 1440.0,
    base_height = 1080.0,
    layout_width = fe.layout.width,
    layout_height = fe.layout.height,
    scale= "stretch",
    debug = true,
}
local stretch = Pos(stretchData)
    
// stretched positioning
local posData =  {
    base_width = 1440.0,
    base_height = 1080.0,
    layout_width = fe.layout.width,
    layout_height = fe.layout.height,
    scale= "scale",
    debug = true,
}
local scale  = Pos(posData)

function random(minNum, maxNum) {
    return floor(((rand() % 1000 ) / 1000.0) * (maxNum - (minNum - 1)) + minNum);
}
function randomf(minNum, maxNum) {
    return (((rand() % 1000 ) / 1000.0) * (maxNum - minNum) + minNum).tofloat();
}
function random_file(path) {
	
	local dir = DirectoryListing( path );
	local dir_array = []; 
	foreach ( key, value in dir.results )
	{
		try
	    {
	        local name = value.slice( path.len() + 1, value.len() );
 
			// bad mac!
			if (name.find("._") == null)
			{
				dir_array.append(value); 
			}

	    }catch ( e )
	    {
	        // print(  value );
	    }
	}
	return dir_array[random(0, dir_array.len()-1)]; 
}

///////////////////////////////////////////////////////
//					ARCADE BACKGROUNDS 
///////////////////////////////////////////////////////

local bg =  fe.add_image( random_file("backgrounds"), 0,0, stretch.width(1440), stretch.height(1080) )
bg.preserve_aspect_ratio = false
bg.mipmap = true
    
local black_overlay = fe.add_text("",0,0,stretch.width(1440),stretch.height(1080))
black_overlay.set_bg_rgb(1,1,1)
black_overlay.bg_alpha = 200

 
///////////////////////////////////////////////////////
// 					SNAP
///////////////////////////////////////////////////////

// create surface for snap
local snap_underlay = fe.add_text("",0,0,1,1)
snap_underlay.set_bg_rgb(1,1,1)
snap_underlay.bg_alpha = 255
    
local snap = fe.add_surface(scale.width(459), scale.height(379));
local snap_video = snap.add_artwork("snap", 0, 0, scale.width(459), scale.height(379)) 
snap_video.trigger = Transition.EndNavigation;
snap_video.preserve_aspect_ratio = false;
snap_video.mipmap=true

    
// scanlines and shaders
local scanlines_srf, crt_scanlines

// snap shader effects 
if ( config["enable_snap_shader"] != "No" && ShadersAvailable == 1)
{
	if ( config["enable_snap_shader"] == "CRT Bloom")
	{
		local sh = fe.add_shader( Shader.Fragment, "shaders/bloom_shader.frag" );
		sh.set_texture_param("bgl_RenderedTexture"); 
		snap_video.shader = sh;
	}
	
	if ( config["enable_snap_shader"] == "CRT Lottes")
	{
		local shader_lottes = null;
		
		shader_lottes=fe.add_shader(
			Shader.VertexAndFragment,
			"shaders/CRT-geom.vsh",
			"shaders/CRT-geom.fsh");
			
		// APERATURE_TYPE
		// 0 = VGA style shadow mask.
		// 1.0 = Very compressed TV style shadow mask.
		// 2.0 = Aperture-grille.
		shader_lottes.set_param("aperature_type", 1.0);
		shader_lottes.set_param("hardScan", 0.0);   // Hardness of Scanline -8.0 = soft -16.0 = medium
		shader_lottes.set_param("hardPix", -2.0);     // Hardness of pixels in scanline -2.0 = soft, -4.0 = hard
		shader_lottes.set_param("maskDark", 0.9);     // Sets how dark a "dark subpixel" is in the aperture pattern.
		shader_lottes.set_param("maskLight", 0.3);    // Sets how dark a "bright subpixel" is in the aperture pattern
		shader_lottes.set_param("saturation", 1.1);   // 1.0 is normal saturation. Increase as needed.
		shader_lottes.set_param("tint", 0.0);         // 0.0 is 0.0 degrees of Tint. Adjust as needed.
		shader_lottes.set_param("distortion", 0.15);		// 0.0 to 0.2 seems right
		shader_lottes.set_param("cornersize", 0.04);  // 0.0 to 0.1
		shader_lottes.set_param("cornersmooth", 80);  // Reduce jagginess of corners
		shader_lottes.set_texture_param("texture");
		
		snap_video.shader = shader_lottes;
		
		fe.add_transition_callback( "shader_transitions" );
		function shader_transitions( ttype, var, ttime ) {
			switch ( ttype )
			{
			case Transition.ToNewList:	
			case Transition.EndNavigation:
				//snap_video.width = snap_surface.subimg_width;
				//snap_video.height = snap_surface.subimg_height;
				// Play with these settings to get a good final image
				snap_video.shader.set_param("color_texture_sz", snap.width, snap.height);
				snap_video.shader.set_param("color_texture_pow2_sz", snap.width, snap.height);
				break;
			}
			return false;
		}
	}
}

///////////////////////////////////////////////////////
// 					SNAP Overlays
///////////////////////////////////////////////////////

// scanline default
if (config["enable_crt_scanline"] != "No")
{
    local scan_art;

    scanlines_srf = fe.add_surface( scale.width(fe.layout.width), scale.height(fe.layout.height) )
    scanlines_srf.set_pos( 0,0 );
        
    if( ScreenWidth < 1920 )
    {
        scan_art = fe.script_dir + "scanlines_640.png"
    }
    else  // 1920 res or higher
    {
        scan_art = fe.script_dir + "scanlines_1920.png"
    }
    crt_scanlines = scanlines_srf.add_image( scan_art, snap.x, snap.y, snap.width, snap.height )
    crt_scanlines.preserve_aspect_ratio = false
    crt_scanlines.mipmap = true
        
    if( config["enable_crt_scanline"] == "Light" )
    {
        if( ScreenWidth < 1920 )
            crt_scanlines.alpha = 20
        else
            crt_scanlines.alpha = 50
    }
    if( config["enable_crt_scanline"] == "Medium" )
    {
        if( ScreenWidth < 1920 )
            crt_scanlines.alpha = 40
        else
            crt_scanlines.alpha = 100
    }
    if( config["enable_crt_scanline"] == "Dark" )
    {
        crt_scanlines.alpha = 200
    }
}
function set_crt_size()
{
    if (config["enable_crt_scanline"] != "No")
    {
        crt_scanlines.width = snap.width
        crt_scanlines.height =snap.height  
        crt_scanlines.x = snap.x
        crt_scanlines.y = snap.y
    }
}

///////////////////////////////////////////////////////
// 					Cabinet
///////////////////////////////////////////////////////
local cabinet
    
local bezel_array = [
	["cabinet_red_bezel.png","red"],
	["cabinet_red_stripes_bezel.png", "red stripes"],
	["cabinet_gold_bezel.png","gold stripes"]
]; 

if (config["bezel_color"]=="random")
{
	cabinet = random_file("cabinets")
}
else
{
	foreach (index, item in bezel_array) {
	    if (item[1] == config["bezel_color"]) {
            cabinet = "cabinets/" + item[0]
		}
	}
}
    
local arcade_cabinet = fe.add_image( cabinet, scale.x(0),scale.y(0), scale.width(977), scale.height(1080));
arcade_cabinet.x=scale.x(100,"right",arcade_cabinet,null,"center")
arcade_cabinet.smooth = true
arcade_cabinet.mipmap = true
  
// marquee
local marquee_underlay = fe.add_image("marquee.jpg",0,0,scale.width(714), scale.height(262))
marquee_underlay.mipmap=true

///////////////////////////////////////////////////////
//					MARQUEE
///////////////////////////////////////////////////////

local marquee = fe.add_surface(scale.width(715),scale.height(262))
local marquee_img = marquee.add_artwork("marquee", 0,0, scale.width(715), scale.height(262) )
marquee_img.trigger = Transition.EndNavigation;
marquee_img.mipmap = true
    
// light from the marquee
local marquee_shadow = null
if ( config["enable_Lmarquee"] != "Yes" )
{
    marquee_shadow = fe.add_image("marquee_shadow.png",0,0,scale.width(718),scale.height(188))
    marquee_shadow.mipmap = true 
}
   


///////////////////////////////////////////////////////
// 					Instruction Cards
///////////////////////////////////////////////////////

function get_game_playcount(){
    local game_details_text = ""
    
    if (fe.game_info( Info.PlayedCount )!="" )
    {
        game_details_text = "Played: " + fe.game_info( Info.PlayedCount ) + " times"
    }
    
    return game_details_text.toupper()
}
function get_game_title()
{
    local game_details_text = ""
    
    if( fe.game_info( Info.Title )!="" )
    {
        game_details_text = fe.game_info( Info.Title ) 
    }
    
    return game_details_text.toupper() 
}

local instructions_bg = null
local instruction_card_width = 581
local instruction_card_height = 700
local instruction_card
local game_title = null 
local game_playcount = null 

if ( config["instruction_cards"] != "none" )
{
	instructions_bg = fe.add_text("",0,0,scale.width(instruction_card_width), scale.height(instruction_card_height) )
    instructions_bg.set_bg_rgb(255,255,255)
    instructions_bg.bg_alpha=220
        
 	instruction_card = fe.add_artwork(config["instruction_cards"], scale.x(863), scale.y(62), scale.width(instruction_card_width), scale.height(instruction_card_height));
    instruction_card.preserve_aspect_ratio = false;
    instruction_card.mipmap=true
	instruction_card.trigger = Transition.EndNavigation;

    instructions_bg.width = instruction_card.width + scale.x(20)
    instructions_bg.height = instruction_card.height + scale.y(60)
        
    game_title = fe.add_text("[!get_game_title]", 0,0, instruction_card.width/2, scale.height(20))
    scale.set_font_height(18,game_title,"BottomLeft")
    game_title.font = "Hanzel Extended Normal"
    
    game_playcount = fe.add_text("[!get_game_playcount]", 0,0, instruction_card.width/2, scale.height(20))
    scale.set_font_height(18,game_playcount,"BottomRight")
    game_playcount.font = "Hanzel Extended Normal"
}

function artwork_transition( ttype, var, ttime ) 
{ 
    if ( ttype == Transition.EndNavigation || ttype==Transition.ToNewList)
    {
        if (instructions_bg )
        {
            if ( !instruction_card.file_name || instruction_card.file_name=="" )
            {
                instructions_bg.bg_alpha =1       
                game_title.alpha = 1
                game_playcount.alpha = 1
            }
            else
            {
                instructions_bg.bg_alpha = 200
                game_title.alpha = 255
                game_playcount.alpha = 255
            }
        }
    }
    return false
} 
fe.add_transition_callback( "artwork_transition")

        
///////////////////////////////////////////////////////
// 					T-Molding
///////////////////////////////////////////////////////

local tmolding = fe.add_image("tmolding.png" , scale.x(0),scale.y(0), scale.width(1031), scale.height(1080));
    
local color_array = [
	[15,15,15,"black"],
	[213,28,28,"red"],
	[255,255,255,"white"]
]; 
local temp_color = color_array[random(0, color_array.len()-1)]; 

if (config["tmolding_color"]=="random")
{
	
	tmolding.red = temp_color[0]; 
	tmolding.green = temp_color[1]; 
	tmolding.blue = temp_color[2]; 
    instructions_bg.set_bg_rgb(temp_color[0], temp_color[1], temp_color[2])
    
}
else
{
	foreach (index, item in color_array) {
	    if (item[3] == config["tmolding_color"]) {
			tmolding.red = color_array[index][0]; 
			tmolding.green = color_array[index][1]; 
			tmolding.blue = color_array[index][2];
            instructions_bg.set_bg_rgb(color_array[index][0], color_array[index][1], color_array[index][2])

		}
	}
}

///////////////////////////////////////////////////////
// 					WHEEL
///////////////////////////////////////////////////////

local wheel = null 
if ( config["show_wheel"] == "Yes" )
{
	wheel = fe.add_artwork("wheel", 0, 0, scale.width(instruction_card_width), scale.height(229));
	wheel.preserve_aspect_ratio = true;
    wheel.mipmap=true
}

///////////////////////////////////////////////////////
// 					Positioning
///////////////////////////////////////////////////////
if (fe.layout.width < fe.layout.height)
{
    local vertData =  {
        base_width = 960.0,
        base_height = 1280.0,
        layout_width = fe.layout.width,
        layout_height = fe.layout.height,
        scale= config["scale"],
        debug = true,
    }
    local vert = Pos(vertData)
    arcade_cabinet.width = vert.width(1242)
    arcade_cabinet.height = vert.height(1280)
    arcade_cabinet.x = vert.x(0,"center",arcade_cabinet,null,"center")
    arcade_cabinet.y = vert.y(0,"bottom",arcade_cabinet,null,"bottom")
       
    snap.width=vert.width(554)
    snap.height=vert.height(447)
    snap.y= vert.y(-257,"bottom",snap,arcade_cabinet,"bottom")
    snap.x= vert.x(2,"center",snap,arcade_cabinet,"center")
        
    if (instructions_bg !=null)
    {
        instructions_bg.visible = false
        instruction_card.visible = false
        game_title.visible = false
        game_playcount.visible = false
     }
    if (wheel !=null)
    {
        wheel.visible = false
    }
    
    snap_underlay.width =  snap.width + 20 
    snap_underlay.height =  snap.height + 20 
    snap_underlay.x = vert.x(0, "center", snap_underlay, snap,"center")
    snap_underlay.y = vert.y(0, "center", snap_underlay, snap,"center")

    marquee.width = vert.width(900)
    marquee.height = vert.height(307)
    marquee.x=vert.x(0,"center",marquee,arcade_cabinet,"center")
    marquee.y=vert.y(22,"top",marquee,arcade_cabinet,"top")
        
    marquee_underlay.width =  marquee.width
    marquee_underlay.height =  marquee.height
    marquee_underlay.x = marquee.x
    marquee_underlay.y = marquee.y

    if (marquee_shadow !=null)
    {
        marquee_shadow.width= vert.width(905)
        marquee_shadow.height = vert.height(250)
        marquee_shadow.x=vert.x(0,"center",marquee_shadow,arcade_cabinet,"center")
        marquee_shadow.y=vert.y(0,"top",marquee_shadow,arcade_cabinet,"top")    
    }
    tmolding.width = vert.width(1294)
    tmolding.height= vert.height(1280)
    tmolding.x = vert.x(0,"center",tmolding,arcade_cabinet,"center")
    tmolding.y = vert.y(0,"top",tmolding, arcade_cabinet,"top") 

}
else
{
    snap.x = scale.x(0,"center",snap,arcade_cabinet,"center")
    snap.y = scale.y(482,"top",snap,arcade_cabinet,"top")

    snap_underlay.width = snap.width + 20 
    snap_underlay.height =  snap.height + 20

    snap_underlay.x = scale.x(0, "center", snap_underlay, snap,"center")
    snap_underlay.y = scale.y(0, "center", snap_underlay, snap,"center")

    marquee.x=scale.x(0,"center",marquee,arcade_cabinet,"center")
    marquee.y=scale.y(17,"top",marquee,arcade_cabinet,"top")

    marquee_underlay.x = scale.x(0,"center" marquee_underlay, marquee, "center")
    marquee_underlay.y = scale.y(0,"center" marquee_underlay, marquee, "center")

    if (marquee_shadow !=null)
    {
        marquee_shadow.x=scale.x(0,"center",marquee_shadow,arcade_cabinet,"center")
        marquee_shadow.y=scale.y(0,"top",marquee_shadow,arcade_cabinet,"top")    
    }

    if (instructions_bg !=null)
    {
        instruction_card.x = scale.x(60,"left",instruction_card,null,"center")
        instruction_card.y = scale.y(32,"top",instruction_card,null,"top")

        instructions_bg.x = scale.x(0,"center",instructions_bg,instruction_card,"center")
        instructions_bg.y = scale.y(-15,"top",instructions_bg,instruction_card,"top")
            
        game_title.x = scale.x(15,"left", game_title, instructions_bg,"left")
        game_title.y = scale.y(-15,"bottom", game_title, instructions_bg,"bottom")
        game_playcount.x = scale.x(-15,"right", game_playcount, instructions_bg,"right")
        game_playcount.y = scale.y(-15,"bottom", game_playcount, instructions_bg,"bottom")      
     }

    if (wheel !=null)
    {
        local instructions_bottom_x = 0
        if (instructions_bg == null)
        {
            wheel.x = scale.x(40,"center",wheel)
            wheel.y = scale.y(0,"center",wheel)
        }
        else
        {
            wheel.x = scale.x(0,"center",wheel,instructions_bg,"center")
            wheel.y = scale.y(20,"top",wheel, instructions_bg,"bottom")  
            wheel.height = scale.vertical_space_between(instructions_bg,null,10)
        }        
    }

    tmolding.x = scale.x(0,"center",tmolding,arcade_cabinet,"center")
    tmolding.y = scale.y(0,"top",tmolding, arcade_cabinet,"top") 
}


set_crt_size()

