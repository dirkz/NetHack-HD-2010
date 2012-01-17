/*
 *  winipad.h
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

#include "hack.h"

#define kNetHackOptions (@"kNetHackOptions")
#define kNetHackTileSet (@"kNetHackTileSet")

extern FILE *ipad_fopen(const char *filename, const char *mode);

void ipad_init_nhwindows(int* argc, char** argv);
void ipad_player_selection();
void ipad_askname();
void ipad_get_nh_event();
void ipad_exit_nhwindows(const char *str);
void ipad_suspend_nhwindows(const char *str);
void ipad_resume_nhwindows();
winid ipad_create_nhwindow(int type);
void ipad_clear_nhwindow(winid wid);
void ipad_display_nhwindow(winid wid, BOOLEAN_P block);
void ipad_destroy_nhwindow(winid wid);
void ipad_curs(winid wid, int x, int y);
void ipad_putstr(winid wid, int attr, const char *text);
void ipad_display_file(const char *filename, BOOLEAN_P must_exist);
void ipad_start_menu(winid wid);
void ipad_add_menu(winid wid, int glyph, const ANY_P *identifier,
					 CHAR_P accelerator, CHAR_P group_accel, int attr, 
					 const char *str, BOOLEAN_P presel);
void ipad_end_menu(winid wid, const char *prompt);
int ipad_select_menu(winid wid, int how, menu_item **menu_list);
void ipad_update_inventory();
void ipad_mark_synch();
void ipad_wait_synch();
void ipad_cliparound(int x, int y);
void ipad_cliparound_window(winid wid, int x, int y);
void ipad_print_glyph(winid wid, XCHAR_P x, XCHAR_P y, int glyph);
void ipad_raw_print(const char *str);
void ipad_raw_print_bold(const char *str);
int ipad_nhgetch();
int ipad_nh_poskey(int *x, int *y, int *mod);
void ipad_nhbell();
int ipad_doprev_message();
char ipad_yn_function(const char *question, const char *choices, CHAR_P def);
void ipad_getlin(const char *prompt, char *line);
int ipad_get_ext_cmd();
void ipad_number_pad(int num);
void ipad_delay_output();
void ipad_start_screen();
void ipad_end_screen();
void ipad_outrip(winid wid, int how);

extern boolean ipad_getpos;

coord CoordMake(xchar i, xchar j);

#ifdef __OBJC__

@interface WinIPad : NSObject {}

+ (const char *)baseFilePath;
+ (void)expandFilename:(const char *)filename intoPath:(char *)path;

@end

#endif