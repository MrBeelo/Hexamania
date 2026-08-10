/*******************************************************************************************
*
*   raygui v5.0 - A simple and easy-to-use immediate-mode gui library
*
*   DESCRIPTION:
*       raygui is a tools-dev-focused immediate-mode-gui library based on raylib but also
*       available as a standalone library, as long as input and drawing functions are provided
*
*   FEATURES:
*       - Immediate-mode gui, minimal retained data
*       - +25 controls provided (basic and advanced)
*       - Styling system for colors, font and metrics
*       - Icons supported, embedded as a 1-bit icons pack
*       - Standalone mode option (custom input/graphics backend)
*       - Multiple support tools provided for raygui development
*
*   POSSIBLE IMPROVEMENTS:
*       - Better standalone mode API for easy plug of custom backends
*       - Externalize required inputs, allow user easier customization
*
*   LIMITATIONS:
*       - No editable multi-line word-wraped text box supported
*       - No auto-layout mechanism, up to the user to define controls position and size
*       - Standalone mode requires library modification and some user work to plug another backend
*
*   NOTES:
*       - WARNING: GuiLoadStyle() and GuiLoadStyle{Custom}() functions, allocate memory for
*         font atlas recs and glyphs, freeing that memory is (usually) up to the user,
*         no unload function is explicitly provided... but note that GuiLoadStyleDefault() unloads
*         by default any previously loaded font (texture, recs, glyphs)
*       - Global UI alpha (guiAlpha) is applied inside GuiDrawRectangle() and GuiDrawText() functions
*
*   CONTROLS PROVIDED:
*     # Container/separators Controls
*       - WindowBox     --> StatusBar, Panel
*       - GroupBox      --> Line
*       - Line
*       - Panel         --> StatusBar
*       - ScrollPanel   --> StatusBar
*       - TabBar        --> Toggle, Button
*
*     # Basic Controls
*       - Label
*       - LabelButton   --> Label
*       - Button
*       - Toggle
*       - ToggleGroup   --> Toggle
*       - ToggleSlider
*       - CheckBox
*       - ComboBox
*       - DropdownBox
*       - TextBox
*       - ValueBox      --> TextBox
*       - Spinner       --> Button, ValueBox
*       - Slider
*       - SliderBar     --> Slider
*       - ProgressBar
*       - StatusBar
*       - DummyRec
*       - Grid
*
*     # Advance Controls
*       - ListView
*       - ColorPicker   --> ColorPanel, ColorBarHue
*       - MessageBox    --> Window, Label, Button
*       - TextInputBox  --> Window, Label, TextBox, Button
*
*     It also provides a set of functions for styling the controls based on its properties (size, color)
*
*
*   RAYGUI STYLE (guiStyle):
*       raygui uses a global data array for all gui style properties (allocated on data segment by default),
*       when a new style is loaded, it is loaded over the global style... but a default gui style could always be
*       recovered with GuiLoadStyleDefault() function, that overwrites the current style to the default one
*
*       The global style array size is fixed and depends on the number of controls and properties:
*
*           static unsigned int guiStyle[RAYGUI_MAX_CONTROLS*(RAYGUI_MAX_PROPS_BASE + RAYGUI_MAX_PROPS_EXTENDED)];
*
*       guiStyle size is by default: 16*(16 + 8) = 384 int = 384*4 bytes = 1536 bytes = 1.5 KB
*
*       Note that the first set of BASE properties (by default guiStyle[0..15]) belong to the generic style
*       used for all controls, when any of those base values is set, it is automatically populated to all
*       controls, so, specific control values overwriting generic style should be set after base values
*
*       After the first BASE properties set, the EXTENDED properties set is defined (by default guiStyle[16..23]),
*       those properties are actually common to all controls and can not be overwritten individually (like BASE ones)
*       Some of those properties are: TEXT_SIZE, TEXT_SPACING, LINE_COLOR, BACKGROUND_COLOR
*
*       Custom control properties can be defined using the EXTENDED properties for each independent control.
*
*       TOOL: rGuiStyler is a visual tool to customize raygui style: github.com/raysan5/rguistyler
*
*
*   RAYGUI ICONS (guiIcons):
*       raygui could use a global array containing icons data (allocated on data segment by default),
*       a custom icons set could be loaded over this array using GuiLoadIcons(), but loaded icons set
*       must be same RAYGUI_ICON_SIZE and no more than RAYGUI_ICON_MAX_ICONS will be loaded
*
*       Every icon is codified in binary form, using 1 bit per pixel, so, every 16x16 icon
*       requires 8 integers (16*16/32) to be stored in memory.
*
*       When the icon is draw, actually one quad per pixel is drawn if the bit for that pixel is set
*
*       The global icons array size is fixed and depends on the number of icons and size:
*
*           static unsigned int guiIcons[RAYGUI_ICON_MAX_ICONS*RAYGUI_ICON_DATA_ELEMENTS];
*
*       guiIcons size is by default: 256*(16*16/32) = 2048*4 = 8192 bytes = 8 KB
*
*       TOOL: rGuiIcons is a visual tool to customize/create raygui icons: github.com/raysan5/rguiicons
*
*   RAYGUI LAYOUT:
*       raygui currently does not provide an auto-layout mechanism like other libraries,
*       layouts must be defined manually on controls drawing, providing the right bounds Rectangle for it
*
*       TOOL: rGuiLayout is a visual tool to create raygui layouts: github.com/raysan5/rguilayout
*
*   CONFIGURATION:
*       #define RAYGUI_IMPLEMENTATION
*           Generates the implementation of the library into the included file
*           If not defined, the library is in header only mode and can be included in other headers
*           or source files without problems. But only ONE file should hold the implementation
*
*       #define RAYGUI_STANDALONE
*           Avoid raylib.h header inclusion in this file. Data types defined on raylib are defined
*           internally in the library and input management and drawing functions must be provided by
*           the user (check library implementation for further details)
*
*       #define RAYGUI_NO_ICONS
*           Avoid including embedded ricons data (256 icons, 16x16 pixels, 1-bit per pixel, 2KB)
*
*       #define RAYGUI_CUSTOM_ICONS
*           Includes custom ricons.h header defining a set of custom icons,
*           this file can be generated using rGuiIcons tool
*
*       #define RAYGUI_FONT_ICONS_BAKING
*           On gui font loading from style file, append the icons to font atlas image, so,
*           icons can be drawn along the text as a texture, instead of using shapes to draw them
*
*       #define RAYGUI_DEBUG_RECS_BOUNDS
*           Draw control bounds rectangles for debug
*
*       #define RAYGUI_DEBUG_TEXT_BOUNDS
*           Draw text bounds rectangles for debug
*
*   VERSIONS HISTORY:
*       5.0 (20-Jul-2026) ADDED: NEW control: GuiTabBar()
*                         ADDED: Support up to 512 icons (v500)
*                         ADDED: Support icons baking into font atlas image
*                         ADDED: guiControlExclusiveMode and guiControlExclusiveRec for exclusive modes
*                         ADDED: GuiValueBoxFloat(), with floats support
*                         ADDED: GuiDropdonwBox() properties: DROPDOWN_ARROW_HIDDEN, DROPDOWN_ROLL_UP
*                         ADDED: GuiListView() property: LIST_ITEMS_BORDER_WIDTH
*                         ADDED: GuiLoadIconsFromMemory(), used by GuiLoadIcons()
*                         ADDED: Macros for inputs customization, raylib decoupling
*                         ADDED: Control result return values: 1-RESULT_PRESSED, 2-RESULT_CHANGED, >2-Control_custom
*                         REMOVED: GuiSpinner() from controls list, using BUTTON + VALUEBOX properties
*                         REMOVED: GuiSliderPro(), functionality was redundant
*                         REMOVED: TextSplit() raylib function requirement on RAYGUI_STANDALONE
*                         REDESIGNED: WARNING: GuiLoadStyleFromMemory() to support icons baking into font atlas
*                         REDESIGNED: GuiToggleGroup() to process rows/cols with no need for GuiTextSplit()
*                         REDESIGNED: GuiColorPanel(), improved HSV <-> RGBA convertion
*                         REDESIGNED: WARNING: TEXT_LINE_SPACING does not consider text height, only lines spacing
*                         REDESIGNED: WARNING: GuiMessageBox(), added parameter for btn return, unify result
*                         REDESIGNED: WARNING: GuiTextInputBox(), added parameter for btn return, unify result
*                         REVIEWED: GuiLoadIconsFromMemory(), fixed memory issues
*                         REVIEWED: Controls using text labels to use LABEL properties
*                         REVIEWED: Replaced sprintf() by snprintf() for more safety
*                         REVIEWED: GuiTabBar(), close tab with mouse middle button
*                         REVIEWED: GuiScrollPanel(), scroll speed proportional to content
*                         REVIEWED: GuiDropdownBox(), support roll up and hidden arrow
*                         REVIEWED: GuiTextBox(), cursor position initialization
*                         REVIEWED: GuiSliderPro(), control value change check
*                         REVIEWED: GuiGrid(), simplified implementation
*                         REVIEWED: GuiIconText(), increase buffer size and reviewed padding
*                         REVIEWED: GuiDrawText(), improved wrap mode drawing
*                         REVIEWED: GuiScrollBar(), minor tweaks
*                         REVIEWED: GuiProgressBar(), improved borders computing
*                         REVIEWED: GuiTextBox(), multiple improvements: autocursor and more
*                         REVIEWED: Functions descriptions, removed wrong return value reference
*
*       4.0 (12-Sep-2023) ADDED: GuiToggleSlider()
*                         ADDED: GuiColorPickerHSV() and GuiColorPanelHSV()
*                         ADDED: Multiple new icons, mostly compiler related
*                         ADDED: New DEFAULT properties: TEXT_LINE_SPACING, TEXT_ALIGNMENT_VERTICAL, TEXT_WRAP_MODE
*                         ADDED: New enum values: GuiTextAlignment, GuiTextAlignmentVertical, GuiTextWrapMode
*                         ADDED: Support loading styles with custom font charset from external file
*                         REDESIGNED: GuiTextBox(), support mouse cursor positioning
*                         REDESIGNED: GuiDrawText(), support multiline and word-wrap modes (read only)
*                         REDESIGNED: GuiProgressBar() to be more visual, progress affects border color
*                         REDESIGNED: Global alpha consideration moved to GuiDrawRectangle() and GuiDrawText()
*                         REDESIGNED: GuiScrollPanel(), get parameters by reference and return result value
*                         REDESIGNED: GuiToggleGroup(), get parameters by reference and return result value
*                         REDESIGNED: GuiComboBox(), get parameters by reference and return result value
*                         REDESIGNED: GuiCheckBox(), get parameters by reference and return result value
*                         REDESIGNED: GuiSlider(), get parameters by reference and return result value
*                         REDESIGNED: GuiSliderBar(), get parameters by reference and return result value
*                         REDESIGNED: GuiProgressBar(), get parameters by reference and return result value
*                         REDESIGNED: GuiListView(), get parameters by reference and return result value
*                         REDESIGNED: GuiColorPicker(), get parameters by reference and return result value
*                         REDESIGNED: GuiColorPanel(), get parameters by reference and return result value
*                         REDESIGNED: GuiColorBarAlpha(), get parameters by reference and return result value
*                         REDESIGNED: GuiColorBarHue(), get parameters by reference and return result value
*                         REDESIGNED: GuiGrid(), get parameters by reference and return result value
*                         REDESIGNED: GuiGrid(), added extra parameter
*                         REDESIGNED: GuiListViewEx(), change parameters order
*                         REDESIGNED: All controls return result as int value
*                         REVIEWED: GuiScrollPanel() to avoid smallish scroll-bars
*                         REVIEWED: All examples and specially controls_test_suite
*                         RENAMED: gui_file_dialog module to gui_window_file_dialog
*                         UPDATED: All styles to include ISO-8859-15 charset (as much as possible)
*
*       3.6 (10-May-2023) ADDED: New icon: SAND_TIMER
*                         ADDED: GuiLoadStyleFromMemory() (binary only)
*                         REVIEWED: GuiScrollBar() horizontal movement key
*                         REVIEWED: GuiTextBox() crash on cursor movement
*                         REVIEWED: GuiTextBox(), additional inputs support
*                         REVIEWED: GuiLabelButton(), avoid text cut
*                         REVIEWED: GuiTextInputBox(), password input
*                         REVIEWED: Local GetCodepointNext(), aligned with raylib
*                         REDESIGNED: GuiSlider*()/GuiScrollBar() to support out-of-bounds
*
*       3.5 (20-Apr-2023) ADDED: GuiTabBar(), based on GuiToggle()
*                         ADDED: Helper functions to split text in separate lines
*                         ADDED: Multiple new icons, useful for code editing tools
*                         REMOVED: Unneeded icon editing functions
*                         REMOVED: GuiTextBoxMulti(), very limited and broken
*                         REMOVED: MeasureTextEx() dependency, logic directly implemented
*                         REMOVED: DrawTextEx() dependency, logic directly implemented
*                         REVIEWED: GuiScrollBar(), improve mouse-click behaviour
*                         REVIEWED: Library header info, more info, better organized
*                         REDESIGNED: GuiTextBox() to support cursor movement
*                         REDESIGNED: GuiDrawText() to divide drawing by lines
*
*       3.2 (22-May-2022) RENAMED: Some enum values, for unification, avoiding prefixes
*                         REMOVED: GuiScrollBar(), only internal
*                         REDESIGNED: GuiPanel() to support text parameter
*                         REDESIGNED: GuiScrollPanel() to support text parameter
*                         REDESIGNED: GuiColorPicker() to support text parameter
*                         REDESIGNED: GuiColorPanel() to support text parameter
*                         REDESIGNED: GuiColorBarAlpha() to support text parameter
*                         REDESIGNED: GuiColorBarHue() to support text parameter
*                         REDESIGNED: GuiTextInputBox() to support password
*
*       3.1 (12-Jan-2022) REVIEWED: Default style for consistency (aligned with rGuiLayout v2.5 tool)
*                         REVIEWED: GuiLoadStyle() to support compressed font atlas image data and unload previous textures
*                         REVIEWED: External icons usage logic
*                         REVIEWED: GuiLine() for centered alignment when including text
*                         RENAMED: Multiple controls properties definitions to prepend RAYGUI_
*                         RENAMED: RICON_ references to RAYGUI_ICON_ for library consistency
*                         Projects updated and multiple tweaks
*
*       3.0 (04-Nov-2021) Integrated ricons data to avoid external file
*                         REDESIGNED: GuiTextBoxMulti()
*                         REMOVED: GuiImageButton*()
*                         Multiple minor tweaks and bugs corrected
*
*       2.9 (17-Mar-2021) REMOVED: Tooltip API
*       2.8 (03-May-2020) Centralized rectangles drawing to GuiDrawRectangle()
*       2.7 (20-Feb-2020) ADDED: Possible tooltips API
*       2.6 (09-Sep-2019) ADDED: GuiTextInputBox()
*                         REDESIGNED: GuiListView*(), GuiDropdownBox(), GuiSlider*(), GuiProgressBar(), GuiMessageBox()
*                         REVIEWED: GuiTextBox(), GuiSpinner(), GuiValueBox(), GuiLoadStyle()
*                         Replaced property INNER_PADDING by TEXT_PADDING, renamed some properties
*                         ADDED: 8 new custom styles ready to use
*                         Multiple minor tweaks and bugs corrected
*
*       2.5 (28-May-2019) Implemented extended GuiTextBox(), GuiValueBox(), GuiSpinner()
*       2.3 (29-Apr-2019) ADDED: rIcons auxiliar library and support for it, multiple controls reviewed
*                         Refactor all controls drawing mechanism to use control state
*       2.2 (05-Feb-2019) ADDED: GuiScrollBar(), GuiScrollPanel(), reviewed GuiListView(), removed Gui*Ex() controls
*       2.1 (26-Dec-2018) REDESIGNED: GuiCheckBox(), GuiComboBox(), GuiDropdownBox(), GuiToggleGroup() > Use combined text string
*                         REDESIGNED: Style system (breaking change)
*       2.0 (08-Nov-2018) ADDED: Support controls guiLock and custom fonts
*                         REVIEWED: GuiComboBox(), GuiListView()...
*       1.9 (09-Oct-2018) REVIEWED: GuiGrid(), GuiTextBox(), GuiTextBoxMulti(), GuiValueBox()...
*       1.8 (01-May-2018) Lot of rework and redesign to align with rGuiStyler and rGuiLayout
*       1.5 (21-Jun-2017) Working in an improved styles system
*       1.4 (15-Jun-2017) Rewritten all GUI functions (removed useless ones)
*       1.3 (12-Jun-2017) Complete redesign of style system
*       1.1 (01-Jun-2017) Complete review of the library
*       1.0 (07-Jun-2016) Converted to header-only by Ramon Santamaria
*       0.9 (07-Mar-2016) Reviewed and tested by Albert Martos, Ian Eito, Sergio Martinez and Ramon Santamaria
*       0.8 (27-Aug-2015) Initial release. Implemented by Kevin Gato, Daniel Nicolás and Ramon Santamaria
*
*   DEPENDENCIES:
*       raylib 6.1-dev  - Inputs reading (keyboard/mouse), shapes drawing, font loading and text drawing
*
*   STANDALONE MODE:
*       By default raygui depends on raylib mostly for the inputs and the drawing functionality but that dependency can be disabled
*       with the config flag RAYGUI_STANDALONE. In that case is up to the user to provide another backend to cover library needs
*
*       The following functions should be redefined for a custom backend:
*
*           - Vector2 GetMousePosition(void);
*           - float GetMouseWheelMove(void);
*           - bool IsMouseButtonDown(int button);
*           - bool IsMouseButtonPressed(int button);
*           - bool IsMouseButtonReleased(int button);
*           - bool IsKeyDown(int key);
*           - bool IsKeyPressed(int key);
*           - int GetCharPressed(void);         // -- GuiTextBox(), GuiValueBox()
*
*           - void DrawRectangle(int x, int y, int width, int height, Color color); // -- GuiDrawRectangle()
*           - void DrawRectangleGradientEx(Rectangle rec, Color col1, Color col2, Color col3, Color col4); // -- GuiColorPicker()
*
*           - Font GetFontDefault(void);                            // -- GuiLoadStyleDefault()
*           - Font LoadFontEx(const char *fileName, int fontSize, int *codepoints, int codepointCount); // -- GuiLoadStyle()
*           - Texture2D LoadTextureFromImage(Image image);          // -- GuiLoadStyle(), required to load texture from embedded font atlas image
*           - void SetShapesTexture(Texture2D tex, Rectangle rec);  // -- GuiLoadStyle(), required to set shapes rec to font white rec (optimization)
*           - char *LoadFileText(const char *fileName);             // -- GuiLoadStyle(), required to load charset data
*           - void UnloadFileText(char *text);                      // -- GuiLoadStyle(), required to unload charset data
*           - const char *GetDirectoryPath(const char *filePath);   // -- GuiLoadStyle(), required to find charset/font file from text .rgs
*           - int *LoadCodepoints(const char *text, int *count);    // -- GuiLoadStyle(), required to load required font codepoints list
*           - void UnloadCodepoints(int *codepoints);               // -- GuiLoadStyle(), required to unload codepoints list
*           - unsigned char *DecompressData(const unsigned char *compData, int compDataSize, int *dataSize); // -- GuiLoadStyle()
*
*   CONTRIBUTORS:
*       Ramon Santamaria:   Supervision, review, redesign, update and maintenance
*       Vlad Adrian:        Complete rewrite of GuiTextBox() to support extended features (2019)
*       Sergio Martinez:    Review, testing (2015) and redesign of multiple controls (2018)
*       Adria Arranz:       Testing and implementation of additional controls (2018)
*       Jordi Jorba:        Testing and implementation of additional controls (2018)
*       Albert Martos:      Review and testing of the library (2015)
*       Ian Eito:           Review and testing of the library (2015)
*       Kevin Gato:         Initial implementation of basic components (2014)
*       Daniel Nicolas:     Initial implementation of basic components (2014)
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2014-2026 Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/
package raylib

import "core:c"

RAYGUI_SHARED :: #config(RAYGUI_SHARED, false)
RAYGUI_WASM_LIB :: #config(RAYGUI_WASM_LIB, "lib/webassembly/libraygui.web.a")

when ODIN_OS == .Windows {
	foreign import lib {
		(
			"lib/win64_msvc16/rayguidll.lib" when RAYGUI_SHARED && ODIN_ARCH == .amd64 else 
			"lib/win64_msvc16/raygui.lib" when ODIN_ARCH == .amd64 else 
			"lib/win32_msvc16/rayguidll.lib" when RAYGUI_SHARED && ODIN_ARCH == .i386 else 
			"lib/win32_msvc16/raygui.lib" when ODIN_ARCH == .i386 else 
			"lib/winarm64_msvc16/rayguidll.lib" when RAYGUI_SHARED && ODIN_ARCH == .arm64 else 
			"lib/winarm64_msvc16/raygui.lib" when ODIN_ARCH == .arm64 else
			"system:raygui"
		),
	}
} else when ODIN_OS == .Linux {
	// Note(bumbread): I'm not sure why in `linux/` folder there are
	// multiple copies of raygui.so, but since these bindings are for
	// particular version of the library, I better specify it. Ideally,
	// though, it's best specified in terms of major (.so.4)
	foreign import lib {
		(
			"lib/linux_amd64/libraygui.so.5.0.0" when RAYGUI_SHARED && ODIN_ARCH == .amd64 else 
			"lib/linux_amd64/libraygui.a" when ODIN_ARCH == .amd64 else 
			"lib/linux_i386/libraygui.a" when ODIN_ARCH == .i386 else 
			"lib/linux_arm64/libraygui.so.5.0.0" when RAYGUI_SHARED && ODIN_ARCH == .arm64 else 
			"lib/linux_arm64/libraygui.a" when ODIN_ARCH == .arm64 else
			"system:raygui"
		),
	}
} else when ODIN_OS == .Darwin {
	foreign import lib {
		"lib/macos/libraygui.5.0.0.dylib" when RAYGUI_SHARED else "lib/macos/libraygui.a",
	}
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import lib {
		RAYGUI_WASM_LIB,
	}
} else {
	foreign import lib "system:raygui"
}

RAYGUI_VERSION_MAJOR :: 5
RAYGUI_VERSION_MINOR :: 0
RAYGUI_VERSION_PATCH :: 0
RAYGUI_VERSION       :: "5.0"

// Style property
// NOTE: Used when exporting style as code for convenience
GuiStyleProp :: struct {
	controlId:     GuiControl, // Control identifier
	propertyId:    u16,        // Property identifier
	propertyValue: c.int,      // Property value
}

// Gui control result
GuiResult :: enum u32 {
	NONE      = 0,
	PRESSED   = 1,
	CHANGED   = 2,
	TAB_CLOSE = 4, // GuiTabBar(), tab close request
}

// Gui control state
GuiState :: enum u32 {
	NORMAL   = 0,
	FOCUSED  = 1,
	PRESSED  = 2,
	DISABLED = 3,
}

// Gui control text alignment
GuiTextAlignment :: enum u32 {
	LEFT   = 0,
	CENTER = 1,
	RIGHT  = 2,
}

// Gui control text alignment vertical
// NOTE: Text vertical position inside the text bounds
GuiTextAlignmentVertical :: enum u32 {
	TOP    = 0,
	MIDDLE = 1,
	BOTTOM = 2,
}

// Gui control text wrap mode
// NOTE: Useful for multiline text
GuiTextWrapMode :: enum u32 {
	NONE = 0,
	CHAR = 1,
	WORD = 2,
}

// Gui controls
// NOTE: Up to 16 controls supported or 32 controls (v500)
GuiControl :: enum u32 {
	// Default -> populates to all controls when set
	DEFAULT     = 0,

	// Basic controls
	LABEL       = 1, // Used also for: LABELBUTTON
	BUTTON      = 2,
	TOGGLE      = 3, // Used also for: TOGGLEGROUP
	SLIDER      = 4, // Used also for: SLIDERBAR, TOGGLESLIDER
	PROGRESSBAR = 5,
	CHECKBOX    = 6,
	COMBOBOX    = 7,
	DROPDOWNBOX = 8,
	TEXTBOX     = 9, // Used also for: TEXTBOXMULTI
	VALUEBOX    = 10,
	TABBAR      = 11,
	LISTVIEW    = 12,
	COLORPICKER = 13,
	SCROLLBAR   = 14,
	STATUSBAR   = 15,
}

// Controls BASE properties for every control (RAYGUI_MAX_PROPS_BASE = 16)
// NOTE: Properties required for all controls, DEFAULT control sets
// default values for them but they can be overriden per control
GuiControlProperty :: enum u32 {
	BORDER_COLOR_NORMAL   = 0,  // Control border color in STATE_NORMAL
	BASE_COLOR_NORMAL     = 1,  // Control base color in STATE_NORMAL
	TEXT_COLOR_NORMAL     = 2,  // Control text color in STATE_NORMAL
	BORDER_COLOR_FOCUSED  = 3,  // Control border color in STATE_FOCUSED
	BASE_COLOR_FOCUSED    = 4,  // Control base color in STATE_FOCUSED
	TEXT_COLOR_FOCUSED    = 5,  // Control text color in STATE_FOCUSED
	BORDER_COLOR_PRESSED  = 6,  // Control border color in STATE_PRESSED
	BASE_COLOR_PRESSED    = 7,  // Control base color in STATE_PRESSED
	TEXT_COLOR_PRESSED    = 8,  // Control text color in STATE_PRESSED
	BORDER_COLOR_DISABLED = 9,  // Control border color in STATE_DISABLED
	BASE_COLOR_DISABLED   = 10, // Control base color in STATE_DISABLED
	TEXT_COLOR_DISABLED   = 11, // Control text color in STATE_DISABLED
	BORDER_WIDTH          = 12, // Control border size, 0 for no border
	TEXT_PADDING          = 13, // Control text padding, not considering border
	TEXT_ALIGNMENT        = 14, // Control text horizontal alignment inside control text bound (after border and padding): 0-Left, 1-Center, 2-Right
	BASEPROP16            = 15, // Not used yet...
}

// Controls EXTENDED properties (RAYGUI_MAX_PROPS_EXTENDED = 8)
// WARNING: Only 8 slots vailable for those properties per control, including DEFAULT
//----------------------------------------------------------------------------------
// DEFAULT control, extended properties
// NOTE: Those properties are global for all controls, they can not be setup per control
GuiDefaultProperty :: enum u32 {
	TEXT_SIZE               = 16, // Text size (glyphs max height)
	TEXT_SPACING            = 17, // Text spacing between glyphs
	LINE_COLOR              = 18, // Line control color
	BACKGROUND_COLOR        = 19, // Background color
	TEXT_LINE_SPACING       = 20, // Text spacing between lines
	TEXT_ALIGNMENT_VERTICAL = 21, // Text vertical alignment inside text bounds (after border and padding): 0-Top, 1-Middle, 2-Bottom
	TEXT_WRAP_MODE          = 22, // Text wrap-mode inside text bounds
	EXTPROP08               = 23, // Not used yet...
}

// Toggle/ToggleGroup
GuiToggleProperty :: enum u32 {
	PADDING    = 16, // ToggleGroup separation between toggles
	WIDTH_FULL = 17, // ToggleGroup bounds width considers all items: 0-Width per item, 1-Full width
}

// Slider/SliderBar
GuiSliderProperty :: enum u32 {
	WIDTH   = 16, // Slider size of internal bar
	PADDING = 17, // Slider/SliderBar internal bar padding
}

// ProgressBar
GuiProgressBarProperty :: enum u32 {
	PADDING = 16, // ProgressBar internal padding
	SIDE    = 17, // ProgressBar increment side: 0-Left->Right, 1-Right->Left
}

// ScrollBar
GuiScrollBarProperty :: enum u32 {
	ARROWS_SIZE           = 16, // ScrollBar arrows size
	ARROWS_VISIBLE        = 17, // ScrollBar arrows visible
	SCROLL_SLIDER_PADDING = 18, // ScrollBar slider internal padding
	SCROLL_SLIDER_SIZE    = 19, // ScrollBar slider size
	SCROLL_PADDING        = 20, // ScrollBar scroll padding from arrows
	SCROLL_SPEED          = 21, // ScrollBar scrolling speed
}

// CheckBox
GuiCheckBoxProperty :: enum u32 {
	CHECK_PADDING = 16, // CheckBox internal check padding
}

// ComboBox
GuiComboBoxProperty :: enum u32 {
	WIDTH   = 16, // ComboBox right button width
	SPACING = 17, // ComboBox button separation
}

// DropdownBox
GuiDropdownBoxProperty :: enum u32 {
	ARROW_PADDING          = 16, // DropdownBox arrow separation from border and items
	DROPDOWN_ITEMS_SPACING = 17, // DropdownBox items separation
	DROPDOWN_ARROW_HIDDEN  = 18, // DropdownBox arrow hidden
	DROPDOWN_ROLL_UP       = 19, // DropdownBox roll up flag: 0-Roll down, 1-Roll up
}

// TextBox/TextBoxMulti/ValueBox/Spinner
GuiTextBoxProperty :: enum u32 {
	TEXT_READONLY = 16, // TextBox in read-only mode: 0-Text editable, 1-Text read-only
}

// ValueBox/Spinner
GuiValueBoxProperty :: enum u32 {
	WIDTH   = 16, // Spinner left/right buttons width
	SPACING = 17, // Spinner buttons separation
}

// TabBar
GuiTabBarProperty :: enum u32 {
	ITEMS_WIDTH  = 16, // TabBar tab items width
	CLOSE_BUTTON = 17, // TabBar tab close button: 0-Not shown, 1-Shown
	LINE_SIDE    = 18, // TabBar tabs side: 0-Bottom, 1-Top
}

// ListView
SCROLLBAR_LEFT_SIDE     :: 0
SCROLLBAR_RIGHT_SIDE    :: 1

GuiListViewProperty :: enum u32 {
	LIST_ITEMS_HEIGHT        = 16, // ListView items height
	LIST_ITEMS_SPACING       = 17, // ListView items separation
	SCROLLBAR_WIDTH          = 18, // ListView scrollbar size (usually width)
	SCROLLBAR_SIDE           = 19, // ListView scrollbar side: 0-Left side, 1-Right Side
	LIST_ITEMS_BORDER_NORMAL = 20, // ListView items border enabled in normal state
	LIST_ITEMS_BORDER_WIDTH  = 21, // ListView items border width
}

// ColorPicker
GuiColorPickerProperty :: enum u32 {
	COLOR_SELECTOR_SIZE      = 16, // ColorPicker selector square size
	HUEBAR_WIDTH             = 17, // ColorPicker right hue bar width
	HUEBAR_PADDING           = 18, // ColorPicker right hue bar separation from panel
	HUEBAR_SELECTOR_HEIGHT   = 19, // ColorPicker right hue bar selector height
	HUEBAR_SELECTOR_OVERFLOW = 20, // ColorPicker right hue bar selector overflow
}

@(default_calling_convention="c")
foreign lib {
	// Global gui state control functions
	GuiEnable   :: proc() ---             // Enable gui controls (global state)
	GuiDisable  :: proc() ---             // Disable gui controls (global state)
	GuiLock     :: proc() ---             // Lock gui controls (global state)
	GuiUnlock   :: proc() ---             // Unlock gui controls (global state)
	GuiIsLocked :: proc() -> bool ---     // Check if gui is locked (global state)
	GuiSetAlpha :: proc(alpha: f32) ---   // Set gui controls alpha (global state), alpha goes from 0.0f to 1.0f
	GuiSetState :: proc(state: c.int) --- // Set gui state (global state)
	GuiGetState :: proc() -> c.int ---    // Get gui state (global state)

	// Font set/get functions
	GuiSetFont :: proc(font: Font) --- // Set gui custom font (global state)
	GuiGetFont :: proc() -> Font ---   // Get gui custom font (global state)

	// Style set/get functions
	GuiSetStyle :: proc(control: GuiControl, property: c.int, value: c.int) --- // Set one style property
	GuiGetStyle :: proc(control: GuiControl, property: c.int) -> c.int ---      // Get one style property

	// Styles loading functions
	GuiLoadStyle           :: proc(fileName: cstring) ---                 // Load style file over global style variable (.rgs)
	GuiLoadStyleFromMemory :: proc(fileData: rawptr, dataSize: c.int) --- // Load style from memory (binary only)
	GuiLoadStyleDefault    :: proc() ---                                  // Load style default over global style

	// Tooltips management functions
	GuiEnableTooltip  :: proc() ---                 // Enable gui tooltips (global state)
	GuiDisableTooltip :: proc() ---                 // Disable gui tooltips (global state)
	GuiSetTooltip     :: proc(tooltip: cstring) --- // Set tooltip string

	// Icons functionality
	GuiIconText            :: proc(iconId: GuiIconName, text: cstring) -> cstring ---        // Get text with icon id prepended (if supported)
	GuiSetIconScale        :: proc(scale: c.int) ---                                         // Set default icon drawing size
	GuiGetIcons            :: proc() -> [^]c.uint ---                                        // Get raygui icons data pointer
	GuiLoadIcons           :: proc(fileName: cstring, loadIconsName: bool) -> [^]cstring --- // Load raygui icons file (.rgi) into internal icons data
	GuiLoadIconsFromMemory :: proc(fileData: rawptr, dataSize: c.int, loadIconsName: bool) -> [^]cstring --- // Load raygui icons file (.rgi) from memory into internal icons data
	GuiDrawIcon            :: proc(iconId: GuiIconName, posX: c.int, posY: c.int, pixelSize: c.int, color: Color) --- // Draw icon using pixel size at specified position

	// Utility functions
	GuiGetTextWidth :: proc(text: cstring) -> c.int --- // Get text width considering gui style and icon size (if required)

	// Controls
	//----------------------------------------------------------------------------------------------------------
	// Container/separator controls, useful for controls organization
	GuiWindowBox   :: proc(bounds: Rectangle, title: cstring) -> c.int --- // Window Box control, shows a window that can be closed
	GuiGroupBox    :: proc(bounds: Rectangle, text: cstring) -> c.int ---  // Group Box control with text name
	GuiLine        :: proc(bounds: Rectangle, text: cstring) -> c.int ---  // Line separator control, could contain text
	GuiPanel       :: proc(bounds: Rectangle, text: cstring) -> c.int ---  // Panel control, useful to group controls
	GuiScrollPanel :: proc(bounds: Rectangle, text: cstring, content: Rectangle, scroll: ^Vector2, view: ^Rectangle) -> c.int --- // Scroll Panel control

	// Basic controls set
	GuiLabel         :: proc(bounds: Rectangle, text: cstring) -> c.int ---                 // Label control
	GuiButton        :: proc(bounds: Rectangle, text: cstring) -> c.int ---                 // Button control, returns true when clicked
	GuiLabelButton   :: proc(bounds: Rectangle, text: cstring) -> c.int ---                 // Label button control, returns true when clicked
	GuiToggle        :: proc(bounds: Rectangle, text: cstring, active: ^bool) -> c.int ---  // Toggle Button control
	GuiToggleGroup   :: proc(bounds: Rectangle, text: cstring, active: ^c.int) -> c.int --- // Toggle Group control
	GuiToggleSlider  :: proc(bounds: Rectangle, text: cstring, active: ^c.int) -> c.int --- // Toggle Slider control
	GuiCheckBox      :: proc(bounds: Rectangle, text: cstring, checked: ^bool) -> c.int --- // Check Box control, returns true when active
	GuiComboBox      :: proc(bounds: Rectangle, text: cstring, active: ^c.int) -> c.int --- // Combo Box control
	GuiDropdownBox   :: proc(bounds: Rectangle, text: cstring, active: ^c.int, editMode: bool) -> c.int --- // Dropdown Box control
	GuiSpinner       :: proc(bounds: Rectangle, text: cstring, value: ^c.int, minValue: c.int, maxValue: c.int, editMode: bool) -> c.int --- // Spinner control
	GuiValueBox      :: proc(bounds: Rectangle, text: cstring, value: ^c.int, minValue: c.int, maxValue: c.int, editMode: bool) -> c.int --- // Value Box control, updates input text with numbers
	GuiValueBoxFloat :: proc(bounds: Rectangle, text: cstring, textValue: cstring, value: ^f32, editMode: bool) -> c.int --- // Value box control for float values
	GuiTextBox       :: proc(bounds: Rectangle, text: cstring, textSize: c.int, editMode: bool) -> c.int --- // Text Box control, updates input text
	GuiSlider        :: proc(bounds: Rectangle, textLeft: cstring, textRight: cstring, value: ^f32, minValue: f32, maxValue: f32) -> c.int --- // Slider control
	GuiSliderBar     :: proc(bounds: Rectangle, textLeft: cstring, textRight: cstring, value: ^f32, minValue: f32, maxValue: f32) -> c.int --- // Slider Bar control
	GuiProgressBar   :: proc(bounds: Rectangle, textLeft: cstring, textRight: cstring, value: ^f32, minValue: f32, maxValue: f32) -> c.int --- // Progress Bar control
	GuiStatusBar     :: proc(bounds: Rectangle, text: cstring) -> c.int ---                 // Status Bar control, shows info text
	GuiDummyRec      :: proc(bounds: Rectangle, text: cstring) -> c.int ---                 // Dummy control for placeholders
	GuiGrid          :: proc(bounds: Rectangle, text: cstring, spacing: f32, subdivs: c.int, mouseCell: ^Vector2) -> c.int --- // Grid control

	// Advance controls set
	GuiListView       :: proc(bounds: Rectangle, text: cstring, scrollIndex: ^c.int, active: ^c.int) -> c.int --- // List View control
	GuiListViewEx     :: proc(bounds: Rectangle, text: [^]cstring, count: c.int, scrollIndex: ^c.int, active: ^c.int, focus: ^c.int) -> c.int --- // List View control, using text entries list and returning focus entry
	GuiTabBar         :: proc(bounds: Rectangle, text: cstring, hscroll: ^c.int, active: ^c.int) -> c.int --- // Tab Bar control
	GuiTabBarEx       :: proc(bounds: Rectangle, text: [^]cstring, count: c.int, hscroll: ^c.int, active: ^c.int, focus: ^c.int) -> c.int --- // Tab Bar control, using text entries list and returning focus entry
	GuiMessageBox     :: proc(bounds: Rectangle, title: cstring, message: cstring, btnText: cstring, btnActive: ^c.int) -> c.int --- // Message Box control, displays a message
	GuiTextInputBox   :: proc(bounds: Rectangle, title: cstring, message: cstring, text: cstring, textSize: c.int, btnText: cstring, btnActive: ^c.int, secretViewActive: ^bool) -> c.int --- // Text Input Box control, ask for text, supports secret
	GuiColorPicker    :: proc(bounds: Rectangle, text: cstring, color: ^Color) -> c.int --- // Color Picker control, includes Color bar controls
	GuiColorPanel     :: proc(bounds: Rectangle, text: cstring, color: ^Color) -> c.int --- // Color Panel control
	GuiColorBarAlpha  :: proc(bounds: Rectangle, text: cstring, alpha: ^f32) -> c.int ---   // Color Bar Alpha control
	GuiColorBarHue    :: proc(bounds: Rectangle, text: cstring, value: ^f32) -> c.int ---   // Color Bar Hue control
	GuiColorPickerHSV :: proc(bounds: Rectangle, text: cstring, colorHsv: ^Vector3) -> c.int --- // Color Picker control, using Hue-Saturation-Value color data, includes Color bar controls
	GuiColorPanelHSV  :: proc(bounds: Rectangle, text: cstring, colorHsv: ^Vector3) -> c.int --- // Color Panel control, using Hue-Saturation-Value color data
}

//----------------------------------------------------------------------------------
// Icons enumeration
//----------------------------------------------------------------------------------
GuiIconName :: enum u32 {
	NONE                    = 0,
	FOLDER_FILE_OPEN        = 1,
	FILE_SAVE_CLASSIC       = 2,
	FOLDER_OPEN             = 3,
	FOLDER_SAVE             = 4,
	FILE_OPEN               = 5,
	FILE_SAVE               = 6,
	FILE_EXPORT             = 7,
	FILE_ADD                = 8,
	FILE_DELETE             = 9,
	FILETYPE_TEXT           = 10,
	FILETYPE_AUDIO          = 11,
	FILETYPE_IMAGE          = 12,
	FILETYPE_PLAY           = 13,
	FILETYPE_VIDEO          = 14,
	FILETYPE_INFO           = 15,
	FILE_COPY               = 16,
	FILE_CUT                = 17,
	FILE_PASTE              = 18,
	CURSOR_HAND             = 19,
	CURSOR_POINTER          = 20,
	CURSOR_CLASSIC          = 21,
	PENCIL                  = 22,
	PENCIL_BIG              = 23,
	BRUSH_CLASSIC           = 24,
	BRUSH_PAINTER           = 25,
	WATER_DROP              = 26,
	COLOR_PICKER            = 27,
	RUBBER                  = 28,
	COLOR_BUCKET            = 29,
	TEXT_T                  = 30,
	TEXT_A                  = 31,
	SCALE                   = 32,
	RESIZE                  = 33,
	FILTER_POINT            = 34,
	FILTER_BILINEAR         = 35,
	CROP                    = 36,
	CROP_ALPHA              = 37,
	SQUARE_TOGGLE           = 38,
	SYMMETRY                = 39,
	SYMMETRY_HORIZONTAL     = 40,
	SYMMETRY_VERTICAL       = 41,
	LENS                    = 42,
	LENS_BIG                = 43,
	EYE_ON                  = 44,
	EYE_OFF                 = 45,
	FILTER_TOP              = 46,
	FILTER                  = 47,
	TARGET_POINT            = 48,
	TARGET_SMALL            = 49,
	TARGET_BIG              = 50,
	TARGET_MOVE             = 51,
	CURSOR_MOVE             = 52,
	CURSOR_SCALE            = 53,
	CURSOR_SCALE_RIGHT      = 54,
	CURSOR_SCALE_LEFT       = 55,
	UNDO                    = 56,
	REDO                    = 57,
	REREDO                  = 58,
	MUTATE                  = 59,
	ROTATE                  = 60,
	REPEAT                  = 61,
	SHUFFLE                 = 62,
	EMPTYBOX                = 63,
	TARGET                  = 64,
	TARGET_SMALL_FILL       = 65,
	TARGET_BIG_FILL         = 66,
	TARGET_MOVE_FILL        = 67,
	CURSOR_MOVE_FILL        = 68,
	CURSOR_SCALE_FILL       = 69,
	CURSOR_SCALE_RIGHT_FILL = 70,
	CURSOR_SCALE_LEFT_FILL  = 71,
	UNDO_FILL               = 72,
	REDO_FILL               = 73,
	REREDO_FILL             = 74,
	MUTATE_FILL             = 75,
	ROTATE_FILL             = 76,
	REPEAT_FILL             = 77,
	SHUFFLE_FILL            = 78,
	EMPTYBOX_SMALL          = 79,
	BOX                     = 80,
	BOX_TOP                 = 81,
	BOX_TOP_RIGHT           = 82,
	BOX_RIGHT               = 83,
	BOX_BOTTOM_RIGHT        = 84,
	BOX_BOTTOM              = 85,
	BOX_BOTTOM_LEFT         = 86,
	BOX_LEFT                = 87,
	BOX_TOP_LEFT            = 88,
	BOX_CENTER              = 89,
	BOX_CIRCLE_MASK         = 90,
	POT                     = 91,
	ALPHA_MULTIPLY          = 92,
	ALPHA_CLEAR             = 93,
	DITHERING               = 94,
	MIPMAPS                 = 95,
	BOX_GRID                = 96,
	GRID                    = 97,
	BOX_CORNERS_SMALL       = 98,
	BOX_CORNERS_BIG         = 99,
	FOUR_BOXES              = 100,
	GRID_FILL               = 101,
	BOX_MULTISIZE           = 102,
	ZOOM_SMALL              = 103,
	ZOOM_MEDIUM             = 104,
	ZOOM_BIG                = 105,
	ZOOM_ALL                = 106,
	ZOOM_CENTER             = 107,
	BOX_DOTS_SMALL          = 108,
	BOX_DOTS_BIG            = 109,
	BOX_CONCENTRIC          = 110,
	BOX_GRID_BIG            = 111,
	OK_TICK                 = 112,
	CROSS                   = 113,
	ARROW_LEFT              = 114,
	ARROW_RIGHT             = 115,
	ARROW_DOWN              = 116,
	ARROW_UP                = 117,
	ARROW_LEFT_FILL         = 118,
	ARROW_RIGHT_FILL        = 119,
	ARROW_DOWN_FILL         = 120,
	ARROW_UP_FILL           = 121,
	AUDIO                   = 122,
	FX                      = 123,
	WAVE                    = 124,
	WAVE_SINUS              = 125,
	WAVE_SQUARE             = 126,
	WAVE_TRIANGULAR         = 127,
	CROSS_SMALL             = 128,
	PLAYER_PREVIOUS         = 129,
	PLAYER_PLAY_BACK        = 130,
	PLAYER_PLAY             = 131,
	PLAYER_PAUSE            = 132,
	PLAYER_STOP             = 133,
	PLAYER_NEXT             = 134,
	PLAYER_RECORD           = 135,
	MAGNET                  = 136,
	LOCK_CLOSE              = 137,
	LOCK_OPEN               = 138,
	CLOCK                   = 139,
	TOOLS                   = 140,
	GEAR                    = 141,
	GEAR_BIG                = 142,
	BIN                     = 143,
	HAND_POINTER            = 144,
	LASER                   = 145,
	COIN                    = 146,
	EXPLOSION               = 147,
	_1UP                    = 148,
	PLAYER                  = 149,
	PLAYER_JUMP             = 150,
	KEY                     = 151,
	DEMON                   = 152,
	TEXT_POPUP              = 153,
	GEAR_EX                 = 154,
	CRACK                   = 155,
	CRACK_POINTS            = 156,
	STAR                    = 157,
	DOOR                    = 158,
	EXIT                    = 159,
	MODE_2D                 = 160,
	MODE_3D                 = 161,
	CUBE                    = 162,
	CUBE_FACE_TOP           = 163,
	CUBE_FACE_LEFT          = 164,
	CUBE_FACE_FRONT         = 165,
	CUBE_FACE_BOTTOM        = 166,
	CUBE_FACE_RIGHT         = 167,
	CUBE_FACE_BACK          = 168,
	CAMERA                  = 169,
	SPECIAL                 = 170,
	LINK_NET                = 171,
	LINK_BOXES              = 172,
	LINK_MULTI              = 173,
	LINK                    = 174,
	LINK_BROKE              = 175,
	TEXT_NOTES              = 176,
	NOTEBOOK                = 177,
	SUITCASE                = 178,
	SUITCASE_ZIP            = 179,
	MAILBOX                 = 180,
	MONITOR                 = 181,
	PRINTER                 = 182,
	PHOTO_CAMERA            = 183,
	PHOTO_CAMERA_FLASH      = 184,
	HOUSE                   = 185,
	HEART                   = 186,
	CORNER                  = 187,
	VERTICAL_BARS           = 188,
	VERTICAL_BARS_FILL      = 189,
	LIFE_BARS               = 190,
	INFO                    = 191,
	CROSSLINE               = 192,
	HELP                    = 193,
	FILETYPE_ALPHA          = 194,
	FILETYPE_HOME           = 195,
	LAYERS_VISIBLE          = 196,
	LAYERS                  = 197,
	WINDOW                  = 198,
	HIDPI                   = 199,
	FILETYPE_BINARY         = 200,
	HEX                     = 201,
	SHIELD                  = 202,
	FILE_NEW                = 203,
	FOLDER_ADD              = 204,
	ALARM                   = 205,
	CPU                     = 206,
	ROM                     = 207,
	STEP_OVER               = 208,
	STEP_INTO               = 209,
	STEP_OUT                = 210,
	RESTART                 = 211,
	BREAKPOINT_ON           = 212,
	BREAKPOINT_OFF          = 213,
	BURGER_MENU             = 214,
	CASE_SENSITIVE          = 215,
	REG_EXP                 = 216,
	FOLDER                  = 217,
	FILE                    = 218,
	SAND_TIMER              = 219,
	WARNING                 = 220,
	HELP_BOX                = 221,
	INFO_BOX                = 222,
	PRIORITY                = 223,
	LAYERS_ISO              = 224,
	LAYERS2                 = 225,
	MLAYERS                 = 226,
	MAPS                    = 227,
	HOT                     = 228,
	LABEL                   = 229,
	NAME_ID                 = 230,
	SLICING                 = 231,
	MANUAL_CONTROL          = 232,
	COLLISION               = 233,
	CIRCLE_ADD              = 234,
	CIRCLE_ADD_FILL         = 235,
	CIRCLE_WARNING          = 236,
	CIRCLE_WARNING_FILL     = 237,
	BOX_MORE                = 238,
	BOX_MORE_FILL           = 239,
	BOX_MINUS               = 240,
	BOX_MINUS_FILL          = 241,
	UNION                   = 242,
	INTERSECTION            = 243,
	DIFFERENCE              = 244,
	SPHERE                  = 245,
	CYLINDER                = 246,
	CONE                    = 247,
	ELLIPSOID               = 248,
	CAPSULE                 = 249,
	FILETYPE_FONT           = 250,
	FILETYPE_3D             = 251,
	FILETYPE_CODE_XML       = 252,
	FILETYPE_CODE_C         = 253,
	FILETYPE_CODE_PYTHON    = 254,
	FILETYPE_CODE_JS        = 255,
	FILETYPE_ICON           = 256,
}

