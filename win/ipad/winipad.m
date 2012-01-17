/*
 *  winipad.c
 *  SlashEM
 *
 *  Created by dirk on 6/26/09.
 *  Copyright 2009 Dirk Zimmermann. All rights reserved.
 *
 */

/*
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation, version 2
 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <stdio.h>
#include <fcntl.h>
#include "dlb.h"
#include "hack.h"

#import "winipad.h"
#import "NhWindow.h"
#import "NhMapWindow.h"
#import "MainViewController.h"
#import "NhYnQuestion.h"
#import "NhEvent.h"
#import "NhEventQueue.h"
#import "NhItem.h"
#import "NhItemGroup.h"
#import "NhMenuWindow.h"
#import "NhStatusWindow.h"
#import "NSString+Z.h"
#import "NhTextInputEvent.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

// mainly for tty port implementation
#define BASE_WINDOW ((winid) [NhWindow messageWindow])

struct window_procs ipad_procs = {
"ipad",
WC_COLOR|WC_HILITE_PET|
WC_ASCII_MAP|WC_TILED_MAP|
WC_FONT_MAP|WC_TILE_FILE|WC_TILE_WIDTH|WC_TILE_HEIGHT|
WC_PLAYER_SELECTION|WC_SPLASH_SCREEN,
0L,
ipad_init_nhwindows,
ipad_player_selection,
ipad_askname,
ipad_get_nh_event,
ipad_exit_nhwindows,
ipad_suspend_nhwindows,
ipad_resume_nhwindows,
ipad_create_nhwindow,
ipad_clear_nhwindow,
ipad_display_nhwindow,
ipad_destroy_nhwindow,
ipad_curs,
ipad_putstr,
ipad_display_file,
ipad_start_menu,
ipad_add_menu,
ipad_end_menu,
ipad_select_menu,
genl_message_menu,	  /* no need for X-specific handling */
ipad_update_inventory,
ipad_mark_synch,
ipad_wait_synch,
#ifdef CLIPPING
ipad_cliparound,
#endif
#ifdef POSITIONBAR
donull,
#endif
ipad_print_glyph,
ipad_raw_print,
ipad_raw_print_bold,
ipad_nhgetch,
ipad_nh_poskey,
ipad_nhbell,
ipad_doprev_message,
ipad_yn_function,
ipad_getlin,
ipad_get_ext_cmd,
ipad_number_pad,
ipad_delay_output,
#ifdef CHANGE_COLOR	 /* only a Mac option currently */
donull,
donull,
#endif
/* other defs that really should go away (they're tty specific) */
ipad_start_screen,
ipad_end_screen,
ipad_outrip,
genl_preference_update,
};

boolean ipad_getpos = 0;

static char s_baseFilePath[FQN_MAX_FILENAME];

coord CoordMake(xchar i, xchar j) {
	coord c = {i,j};
	return c;
}

@implementation WinIPad

+ (void)load {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	strcpy(s_baseFilePath, [[[NSBundle mainBundle] resourcePath] cStringUsingEncoding:NSASCIIStringEncoding]);

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								@"time,autopickup,autodig,showexp,pickup_types:$!?\"=/,norest_on_space,runmode:walk",
								kNetHackOptions,
								@"absurd32.png",
								kNetHackTileSet,
								nil]];

	NSString *netHackOptions = [defaults stringForKey:kNetHackOptions];
	setenv("NETHACKOPTIONS", [netHackOptions cStringUsingEncoding:NSASCIIStringEncoding], 1);
	
	[pool release];
}

+ (const char *)baseFilePath {
	return s_baseFilePath;
}

+ (void)expandFilename:(const char *)filename intoPath:(char *)path {
	sprintf(path, "%s/%s", [self baseFilePath], filename);
}

@end

FILE *ipad_dlb_fopen(const char *filename, const char *mode) {
	char path[FQN_MAX_FILENAME];
	[WinIPad expandFilename:filename intoPath:path];
	FILE *file = fopen(path, mode);
	return file;
}

// These must be defined but are not used (they handle keyboard interrupts).
void intron() {}
void introff() {}

int dosuspend() {
	NSLog(@"dosuspend");
	return 0;
}

void error(const char *s, ...) {
	//NSLog(@"error: %s");
	char message[512];
	va_list ap;
	va_start(ap, s);
	vsprintf(message, s, ap);
	va_end(ap);
	ipad_raw_print(message);
	// todo (button to wait for user?)
	exit(0);
}

#pragma mark nethack window API

void ipad_init_nhwindows(int* argc, char** argv) {
	//NSLog(@"init_nhwindows");
	iflags.runmode = RUN_STEP;
	iflags.window_inited = TRUE;

#if TARGET_OS_IPHONE && TARGET_IPHONE_SIMULATOR
	wizard = TRUE; /* debugging */
#endif
}

void ipad_askname() {
	//NSLog(@"askname");
	ipad_getlin("Enter your name", plname);
}

void ipad_get_nh_event() {
	//NSLog(@"get_nh_event");
}

void ipad_exit_nhwindows(const char *str) {
	//NSLog(@"exit_nhwindows %s", str);
}

void ipad_suspend_nhwindows(const char *str) {
	//NSLog(@"suspend_nhwindows %s", str);
}

void ipad_resume_nhwindows() {
	//NSLog(@"resume_nhwindows");
}

winid ipad_create_nhwindow(int type) {
	NhWindow *w = nil;
	switch (type) {
		case NHW_MAP:
			w = [[NhMapWindow alloc] initWithType:type];
			break;
		case NHW_MENU:
			w = [[NhMenuWindow alloc] initWithType:type];
			break;
		case NHW_STATUS:
			w = [[NhStatusWindow alloc] initWithType:type];
			break;
		default:
			w = [[NhWindow alloc] initWithType:type];
			break;
	}
	//NSLog(@"create_nhwindow(%x) %x", type, w);
	return (winid) w;
}

void ipad_clear_nhwindow(winid wid) {
	//NSLog(@"clear_nhwindow %x", wid);
	[(NhWindow *) wid clear];
}

void ipad_display_nhwindow(winid wid, BOOLEAN_P block) {
	//NSLog(@"display_nhwindow %x, %i, %i", wid, ((NhWindow *) wid).type, block);
	((NhWindow *) wid).blocking = block;
	[[MainViewController instance] displayWindow:(NhWindow *) wid];
	((NhWindow *) wid).blocking = NO;
}

void ipad_destroy_nhwindow(winid wid) {
	//NSLog(@"destroy_nhwindow %x", wid);
	NhWindow *w = (NhWindow *) wid;
	if (w != [NhWindow messageWindow] && w != [NhWindow statusWindow] && w != [NhWindow mapWindow]) {
		[w release];
	}
}

void ipad_curs(winid wid, int x, int y) {
	//NSLog(@"curs %x %d,%d", wid, x, y);
}

void ipad_putstr(winid wid, int attr, const char *text) {
	//NSLog(@"putstr %x %s", wid, text);
	if (wid == WIN_ERR || !wid) {
		wid = BASE_WINDOW;
	}
	[(NhWindow *) wid print:text];
	if (wid == WIN_MESSAGE || wid == BASE_WINDOW) {
		[[MainViewController instance] refreshMessages];
	}
}

void ipad_display_file(const char *filename, BOOLEAN_P must_exist) {
	//NSLog(@"display_file %s", filename);
	char path[FQN_MAX_FILENAME];
	[WinIPad expandFilename:filename intoPath:path];
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:
						  [NSString stringWithCString:path encoding:NSASCIIStringEncoding]
												   encoding:NSASCIIStringEncoding error:&error];
	if (must_exist && error) {
		char msg[512];
		sprintf(msg, "Could not display file %s", filename);
		ipad_raw_print(msg);
	} else if (!error) {
		[[MainViewController instance] displayText:contents];
		// read and discard next event
		[[NhEventQueue instance] nextEvent];
	}
}

void ipad_start_menu(winid wid) {
	//NSLog(@"start_menu %x", wid);
	[(NhMenuWindow *) wid startMenu];
}

void ipad_add_menu(winid wid, int glyph, const ANY_P *identifier,
					 CHAR_P accelerator, CHAR_P group_accel, int attr, 
					 const char *str, BOOLEAN_P presel) {
	NhMenuWindow *w = (NhMenuWindow *) wid;
	//NSLog(@"add_menu %x %i %c %s", wid, w.type, identifier->a_void, str);
	NSString *title = [[NSString stringWithFormat:@"%s", str] stringWithTrimmedWhitespaces];
	if (identifier->a_void != 0) {
		NhItem *i = [[NhItem alloc] initWithTitle:title
									   identifier:*identifier inventoryLetter:accelerator glyph:glyph selected:presel];
		[w.currentItemGroup addItem:i];
		[i release];
	} else {
		// don't allow NhItemGroups after each other to sort out inactive ones
		NhItemGroup *g = [[NhItemGroup alloc] initWithTitle:title];
		[w addItemGroup:g];
		[g release];
	}
}

void ipad_end_menu(winid wid, const char *prompt) {
	//NSLog(@"end_menu %x, %s", wid, prompt);
	if (prompt) {
		((NhMenuWindow *) wid).prompt = [NSString stringWithFormat:@"%s", prompt];
		ipad_putstr(WIN_MESSAGE, 0, prompt);
	} else {
		((NhMenuWindow *) wid).prompt = nil;
	}
}

int ipad_select_menu(winid wid, int how, menu_item **selected) {
	//NSLog(@"select_menu %x", wid);
	NhMenuWindow *w = (NhMenuWindow *) wid;
	w.how = how;
	*selected = NULL;
	[[MainViewController instance] showMenuWindow:w];
	NhEvent *e = [[NhEventQueue instance] nextEvent];
	if (e.key > 0) {
		menu_item *pMenu = *selected = calloc(sizeof(menu_item), w.selected.count);
		for (NhItem *item in w.selected) {
			pMenu->count = item.amount;
			pMenu->item = item.identifier;
			pMenu++;
		}
	}
	return e.key;
}

void ipad_update_inventory() {
	//NSLog(@"update_inventory");
	[[MainViewController instance] updateInventory];
}

void ipad_mark_synch() {
	//NSLog(@"mark_synch");
}

void ipad_wait_synch() {
	//NSLog(@"wait_synch");
//	[[MainViewController instance] refreshAllViews];
}

void ipad_cliparound(int x, int y) {
	//NSLog(@"cliparound %d,%d", x, y);
	[[MainViewController instance] clipAroundX:x y:y];
}

void ipad_cliparound_window(winid wid, int x, int y) {
	NSLog(@"cliparound_window %x %d,%d", wid, x, y);
}

void ipad_print_glyph(winid wid, XCHAR_P x, XCHAR_P y, int glyph) {
	//NSLog(@"print_glyph %x %d,%d", wid, x, y);
	[(NhMapWindow *) wid printGlyph:glyph atX:x y:y];
}

void ipad_raw_print(const char *str) {
	NSLog(@"raw_print %s", str);
	ipad_putstr((winid) [NhWindow messageWindow], 0, str);
}

void ipad_raw_print_bold(const char *str) {
	//NSLog(@"raw_print_bold %s", str);
	ipad_raw_print(str);
}

int ipad_nhgetch() {
	NSLog(@"nhgetch");
	return 0;
}

int ipad_nh_poskey(int *x, int *y, int *mod) {
	//NSLog(@"nh_poskey");
	[[MainViewController instance] nhPoskey];
	NhEvent *e = [[NhEventQueue instance] nextEvent];
	if (!e.isKeyEvent) {
		*x = e.x;
		*y = e.y;
		*mod = e.mod;
	}
	return e.key;
}

void ipad_nhbell() {
	NSLog(@"nhbell");
}

int ipad_doprev_message() {
	//NSLog(@"doprev_message");
	return 0;
}

char ipad_yn_function(const char *question, const char *choices, CHAR_P def) {
	//NSLog(@"yn_function %s", question);
	if (!strcmp("Really save?", question) || !strcmp("Overwrite the old file?", question)) {
		return 'y';
	}
	ipad_putstr(WIN_MESSAGE, 0, question);
	NhEvent *e = nil;
	if ([[NhEventQueue instance] peek]) {
		e = [[NhEventQueue instance] nextEvent];
	} else {
		NhYnQuestion *q = [[NhYnQuestion alloc] initWithQuestion:question choices:choices default:def];
		[[MainViewController instance] showYnQuestion:q];
		e = [[NhEventQueue instance] nextEvent];
		[q release];
	}
	return e.key;
}

void ipad_getlin(const char *prompt, char *line) {
	//NSLog(@"getlin %s", prompt);
	ipad_putstr(WIN_MESSAGE, 0, prompt);
	[[MainViewController instance] refreshAllViews];
	char keys[80];
	char *pStr = keys;
	while ([[NhEventQueue instance] peek]) {
		NhEvent *e = [[NhEventQueue instance] nextEvent];
		if (e.isKeyEvent) {
			*pStr++ = e.key;
		} else {
			break;
		}
	}
	*pStr = '\0';
	if (strlen(keys)) {
		strcpy(line, keys);
	} else {
		[[MainViewController instance] getLine];
		NhTextInputEvent *e = (NhTextInputEvent *) [[NhEventQueue instance] nextEvent];
		if (e.text && e.text.length > 0) {
			[e.text getCString:line maxLength:BUFSZ encoding:NSASCIIStringEncoding];
		} else {
			// cancel
			strcpy(line, "\033\000");
		}
	}
}

int ipad_get_ext_cmd() {
	//NSLog(@"get_ext_cmd");
	[[MainViewController instance] showExtendedCommands];
	NhEvent *e = [[NhEventQueue instance] nextEvent];
	return e.key;
}

void ipad_number_pad(int num) {
	NSLog(@"number_pad %d", num);
}

void ipad_delay_output() {
	//NSLog(@"delay_output");
#if TARGET_IPHONE_SIMULATOR
	//usleep(500000);
#endif	
}

void ipad_start_screen() {
	NSLog(@"start_screen");
}

void ipad_end_screen() {
	NSLog(@"end_screen");
}

void ipad_outrip(winid wid, int how) {
	NSLog(@"outrip %x", wid);
}

#pragma mark window API player_selection()
// from tty port
/* clean up and quit */
static void bail(const char *mesg) {
    ipad_exit_nhwindows(mesg);
    terminate(EXIT_SUCCESS);
}

// from tty port
static int ipad_role_select(char *pbuf, char *plbuf) {
	int i, n;
	char thisch, lastch = 0;
    char rolenamebuf[QBUFSZ];
	winid win;
	anything any;
	menu_item *selected = 0;
	
   	ipad_clear_nhwindow(BASE_WINDOW);
	ipad_putstr(BASE_WINDOW, 0, "Choosing Character's Role");
	
	/* Prompt for a role */
	win = create_nhwindow(NHW_MENU);
	start_menu(win);
	any.a_void = 0;         /* zero out all bits */
	for (i = 0; roles[i].name.m; i++) {
	    if (ok_role(i, flags.initrace, flags.initgend,
					flags.initalign)) {
			any.a_int = i+1;	/* must be non-zero */
			thisch = lowc(roles[i].name.m[0]);
			if (thisch == lastch) thisch = highc(thisch);
			if (flags.initgend != ROLE_NONE && flags.initgend != ROLE_RANDOM) {
				if (flags.initgend == 1  && roles[i].name.f)
					Strcpy(rolenamebuf, roles[i].name.f);
				else
					Strcpy(rolenamebuf, roles[i].name.m);
			} else {
				if (roles[i].name.f) {
					Strcpy(rolenamebuf, roles[i].name.m);
					Strcat(rolenamebuf, "/");
					Strcat(rolenamebuf, roles[i].name.f);
				} else 
					Strcpy(rolenamebuf, roles[i].name.m);
			}	
			add_menu(win, NO_GLYPH, &any, thisch,
					 0, ATR_NONE, an(rolenamebuf), MENU_UNSELECTED);
			lastch = thisch;
	    }
	}
	any.a_int = pick_role(flags.initrace, flags.initgend,
						  flags.initalign, PICK_RANDOM)+1;
	if (any.a_int == 0)	/* must be non-zero */
	    any.a_int = randrole()+1;
		add_menu(win, NO_GLYPH, &any , '*', 0, ATR_NONE,
				 "Random", MENU_UNSELECTED);
		any.a_int = i+1;	/* must be non-zero */
		add_menu(win, NO_GLYPH, &any , 'q', 0, ATR_NONE,
				 "Quit", MENU_UNSELECTED);
		Sprintf(pbuf, "Pick a role for your %s", plbuf);
		end_menu(win, pbuf);
		n = select_menu(win, PICK_ONE, &selected);
		ipad_destroy_nhwindow(win);
		
	/* Process the choice */
		if (n != 1 || selected[0].item.a_int == any.a_int) {
			free((genericptr_t) selected),	selected = 0;	
			return (-1);		/* Selected quit */
		}
	
	flags.initrole = selected[0].item.a_int - 1;
	free((genericptr_t) selected),	selected = 0;
	return (flags.initrole);
}

// from tty port
static int ipad_race_select(char * pbuf, char * plbuf) {
	int i, k, n;
	char thisch, lastch;
	winid win;
	anything any;
	menu_item *selected = 0;
	
	/* Count the number of valid races */
	n = 0;	/* number valid */
	k = 0;	/* valid race */
	for (i = 0; races[i].noun; i++) {
	    if (ok_race(flags.initrole, i, flags.initgend,
					flags.initalign)) {
			n++;
			k = i;
	    }
	}
	if (n == 0) {
	    for (i = 0; races[i].noun; i++) {
			if (validrace(flags.initrole, i)) {
				n++;
				k = i;
			}
	    }
	}
	
	/* Permit the user to pick, if there is more than one */
	if (n > 1) {
	    ipad_clear_nhwindow(BASE_WINDOW);
	    ipad_putstr(BASE_WINDOW, 0, "Choosing Race");
	    win = create_nhwindow(NHW_MENU);
	    start_menu(win);
	    any.a_void = 0;         /* zero out all bits */
	    for (i = 0; races[i].noun; i++)
			if (ok_race(flags.initrole, i, flags.initgend,
						flags.initalign)) {
				any.a_int = i+1;	/* must be non-zero */
				thisch = lowc(races[i].noun[0]);
				if (thisch == lastch) thisch = highc(thisch);
				add_menu(win, NO_GLYPH, &any, thisch,
						 0, ATR_NONE, races[i].noun, MENU_UNSELECTED);
				lastch = thisch;
			}
	    any.a_int = pick_race(flags.initrole, flags.initgend,
							  flags.initalign, PICK_RANDOM)+1;
	    if (any.a_int == 0)	/* must be non-zero */
			any.a_int = randrace(flags.initrole)+1;
	    add_menu(win, NO_GLYPH, &any , '*', 0, ATR_NONE,
				 "Random", MENU_UNSELECTED);
	    any.a_int = i+1;	/* must be non-zero */
	    add_menu(win, NO_GLYPH, &any , 'q', 0, ATR_NONE,
				 "Quit", MENU_UNSELECTED);
	    Sprintf(pbuf, "Pick the race of your %s", plbuf);
	    end_menu(win, pbuf);
	    n = select_menu(win, PICK_ONE, &selected);
	    destroy_nhwindow(win);
	    if (n != 1 || selected[0].item.a_int == any.a_int)
			return(-1);		/* Selected quit */
		
	    k = selected[0].item.a_int - 1;
	    free((genericptr_t) selected),	selected = 0;
	}
	
	flags.initrace = k;
	return (k);
}

// from tty port
void ipad_player_selection() {
	int i, k, n;
	char pick4u = 'n';
	char pbuf[QBUFSZ], plbuf[QBUFSZ];
	winid win;
	anything any;
	menu_item *selected = 0;
	
	/* prevent an unnecessary prompt */
	rigid_role_checks();
	
	/* Should we randomly pick for the player? */
	if (!flags.randomall &&
	    (flags.initrole == ROLE_NONE || flags.initrace == ROLE_NONE ||
	     flags.initgend == ROLE_NONE || flags.initalign == ROLE_NONE)) {
			char *prompt = build_plselection_prompt(pbuf, QBUFSZ, flags.initrole,
													flags.initrace, flags.initgend, flags.initalign);
			
			pick4u = ipad_yn_function(prompt, "ynq", pick4u);
			ipad_clear_nhwindow(BASE_WINDOW);
			
			if (pick4u != 'y' && pick4u != 'n') {
			give_up:	/* Quit */
				if (selected) free((genericptr_t) selected);
				bail((char *)0);
				/*NOTREACHED*/
				return;
			}
		}
	
	(void)  root_plselection_prompt(plbuf, QBUFSZ - 1,
									flags.initrole, flags.initrace, flags.initgend, flags.initalign);
	
	/* Select a role, if necessary */
	/* we'll try to be compatible with pre-selected race/gender/alignment,
	 * but may not succeed */
	if (flags.initrole < 0) {
	    /* Process the choice */
	    if (pick4u == 'y' || flags.initrole == ROLE_RANDOM || flags.randomall) {
			/* Pick a random role */
			flags.initrole = pick_role(flags.initrace, flags.initgend,
									   flags.initalign, PICK_RANDOM);
			if (flags.initrole < 0) {
				ipad_putstr(BASE_WINDOW, 0, "Incompatible role!");
				flags.initrole = randrole();
			}
	    } else {
	    	if (ipad_role_select(pbuf, plbuf) < 0) goto give_up;
	    }
	    (void)  root_plselection_prompt(plbuf, QBUFSZ - 1,
										flags.initrole, flags.initrace, flags.initgend, flags.initalign);
	}
	
	/* Select a race, if necessary */
	/* force compatibility with role, try for compatibility with
	 * pre-selected gender/alignment */
	if (flags.initrace < 0 || !validrace(flags.initrole, flags.initrace)) {
	    /* pre-selected race not valid */
	    if (pick4u == 'y' || flags.initrace == ROLE_RANDOM || flags.randomall) {
			flags.initrace = pick_race(flags.initrole, flags.initgend,
									   flags.initalign, PICK_RANDOM);
			if (flags.initrace < 0) {
				ipad_putstr(BASE_WINDOW, 0, "Incompatible race!");
				flags.initrace = randrace(flags.initrole);
			}
	    } else {	/* pick4u == 'n' */
	    	if (ipad_race_select(pbuf, plbuf) < 0) goto give_up;
	    }
	    (void)  root_plselection_prompt(plbuf, QBUFSZ - 1,
										flags.initrole, flags.initrace, flags.initgend, flags.initalign);
	}
	
	/* Select a gender, if necessary */
	/* force compatibility with role/race, try for compatibility with
	 * pre-selected alignment */
	if (flags.initgend < 0 || !validgend(flags.initrole, flags.initrace,
										 flags.initgend)) {
		/* pre-selected gender not valid */
		if (pick4u == 'y' || flags.initgend == ROLE_RANDOM || flags.randomall) {
			flags.initgend = pick_gend(flags.initrole, flags.initrace,
									   flags.initalign, PICK_RANDOM);
			if (flags.initgend < 0) {
				ipad_putstr(BASE_WINDOW, 0, "Incompatible gender!");
				flags.initgend = randgend(flags.initrole, flags.initrace);
			}
		} else {	/* pick4u == 'n' */
			/* Count the number of valid genders */
			n = 0;	/* number valid */
			k = 0;	/* valid gender */
			for (i = 0; i < ROLE_GENDERS; i++) {
				if (ok_gend(flags.initrole, flags.initrace, i,
							flags.initalign)) {
					n++;
					k = i;
				}
			}
			if (n == 0) {
				for (i = 0; i < ROLE_GENDERS; i++) {
					if (validgend(flags.initrole, flags.initrace, i)) {
						n++;
						k = i;
					}
				}
			}
			
			/* Permit the user to pick, if there is more than one */
			if (n > 1) {
				ipad_clear_nhwindow(BASE_WINDOW);
				ipad_putstr(BASE_WINDOW, 0, "Choosing Gender");
				win = create_nhwindow(NHW_MENU);
				start_menu(win);
				any.a_void = 0;         /* zero out all bits */
				for (i = 0; i < ROLE_GENDERS; i++)
					if (ok_gend(flags.initrole, flags.initrace, i,
								flags.initalign)) {
						any.a_int = i+1;
						add_menu(win, NO_GLYPH, &any, genders[i].adj[0],
								 0, ATR_NONE, genders[i].adj, MENU_UNSELECTED);
					}
				any.a_int = pick_gend(flags.initrole, flags.initrace,
									  flags.initalign, PICK_RANDOM)+1;
				if (any.a_int == 0)	/* must be non-zero */
					any.a_int = randgend(flags.initrole, flags.initrace)+1;
				add_menu(win, NO_GLYPH, &any , '*', 0, ATR_NONE,
						 "Random", MENU_UNSELECTED);
				any.a_int = i+1;	/* must be non-zero */
				add_menu(win, NO_GLYPH, &any , 'q', 0, ATR_NONE,
						 "Quit", MENU_UNSELECTED);
				Sprintf(pbuf, "Pick the gender of your %s", plbuf);
				end_menu(win, pbuf);
				n = select_menu(win, PICK_ONE, &selected);
				destroy_nhwindow(win);
				if (n != 1 || selected[0].item.a_int == any.a_int)
					goto give_up;		/* Selected quit */
				
				k = selected[0].item.a_int - 1;
				free((genericptr_t) selected),	selected = 0;
			}
			flags.initgend = k;
		}
	    (void)  root_plselection_prompt(plbuf, QBUFSZ - 1,
										flags.initrole, flags.initrace, flags.initgend, flags.initalign);
	}
	
	/* Select an alignment, if necessary */
	/* force compatibility with role/race/gender */
	if (flags.initalign < 0 || !validalign(flags.initrole, flags.initrace,
										   flags.initalign)) {
	    /* pre-selected alignment not valid */
	    if (pick4u == 'y' || flags.initalign == ROLE_RANDOM || flags.randomall) {
			flags.initalign = pick_align(flags.initrole, flags.initrace,
										 flags.initgend, PICK_RANDOM);
			if (flags.initalign < 0) {
				ipad_putstr(BASE_WINDOW, 0, "Incompatible alignment!");
				flags.initalign = randalign(flags.initrole, flags.initrace);
			}
	    } else {	/* pick4u == 'n' */
			/* Count the number of valid alignments */
			n = 0;	/* number valid */
			k = 0;	/* valid alignment */
			for (i = 0; i < ROLE_ALIGNS; i++) {
				if (ok_align(flags.initrole, flags.initrace, flags.initgend,
							 i)) {
					n++;
					k = i;
				}
			}
			if (n == 0) {
				for (i = 0; i < ROLE_ALIGNS; i++) {
					if (validalign(flags.initrole, flags.initrace, i)) {
						n++;
						k = i;
					}
				}
			}
			
			/* Permit the user to pick, if there is more than one */
			if (n > 1) {
				ipad_clear_nhwindow(BASE_WINDOW);
				ipad_putstr(BASE_WINDOW, 0, "Choosing Alignment");
				win = create_nhwindow(NHW_MENU);
				start_menu(win);
				any.a_void = 0;         /* zero out all bits */
				for (i = 0; i < ROLE_ALIGNS; i++)
					if (ok_align(flags.initrole, flags.initrace,
								 flags.initgend, i)) {
						any.a_int = i+1;
						add_menu(win, NO_GLYPH, &any, aligns[i].adj[0],
								 0, ATR_NONE, aligns[i].adj, MENU_UNSELECTED);
					}
				any.a_int = pick_align(flags.initrole, flags.initrace,
									   flags.initgend, PICK_RANDOM)+1;
				if (any.a_int == 0)	/* must be non-zero */
					any.a_int = randalign(flags.initrole, flags.initrace)+1;
				add_menu(win, NO_GLYPH, &any , '*', 0, ATR_NONE,
						 "Random", MENU_UNSELECTED);
				any.a_int = i+1;	/* must be non-zero */
				add_menu(win, NO_GLYPH, &any , 'q', 0, ATR_NONE,
						 "Quit", MENU_UNSELECTED);
				Sprintf(pbuf, "Pick the alignment of your %s", plbuf);
				end_menu(win, pbuf);
				n = select_menu(win, PICK_ONE, &selected);
				destroy_nhwindow(win);
				if (n != 1 || selected[0].item.a_int == any.a_int)
					goto give_up;		/* Selected quit */
				
				k = selected[0].item.a_int - 1;
				free((genericptr_t) selected),	selected = 0;
			}
			flags.initalign = k;
	    }
	}
	/* Success! */
	ipad_display_nhwindow(BASE_WINDOW, FALSE);
}
