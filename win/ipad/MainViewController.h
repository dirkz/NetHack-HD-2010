//
//  MainViewController.h
//  NetHack
//
//  Created by dirk on 2/1/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
//

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

#import <UIKit/UIKit.h>
#import "ZDirection.h"

//#define HARDWARE_KEYBOARD

@class NhYnQuestion;
@class NhWindow;
@class ActionViewController;
@class InventoryViewController;
@class NhMenuWindow;
@class MenuViewController;
@class OptionsViewController;
@class MessageView;
@class MapView;
@class DirectionPad;

@interface MainViewController : UIViewController <UITextFieldDelegate> {

	IBOutlet MessageView *messageView;
	IBOutlet UILabel *statusView1;
	IBOutlet UILabel *statusView2;
	IBOutlet UIScrollView *mapScrollView;
	IBOutlet MapView *mapView;
	IBOutlet DirectionPad *directionPad;
	IBOutlet UIToolbar *bottomToolbar;
	
	NhYnQuestion *currentYnQuestion;
	ActionViewController *actionViewController;
	InventoryViewController *inventoryViewController;
	MenuViewController *menuViewController;
	OptionsViewController *optionsViewController;
	
	BOOL directionQuestion;
	
#ifdef HARDWARE_KEYBOARD
	// for hardware keyboard input
	UITextField *dummyTextField;
#endif
	
	UIPopoverController *actionPopoverController;
	UIPopoverController *inventoryPopoverController;
	UIPopoverController *optionsPopoverController;
	
	int clipX;
	int clipY;
	
	// currently displayed/visible popover controllers
	NSMutableArray *currentVisiblePopovers;
	
}

@property (readonly) ActionViewController *actionViewController;
@property (readonly) UIPopoverController *actionPopoverController;
@property (readonly) InventoryViewController *inventoryViewController;
@property (readonly) UINavigationController *inventoryNavigationController;
@property (readonly) UIPopoverController *inventoryPopoverController;
@property (readonly) MenuViewController *menuViewController;
@property (readonly) OptionsViewController *optionsViewController;
@property (readonly) UIPopoverController *optionsPopoverController;
@property (readonly) UINavigationController *optionsNavigationController;

+ (MainViewController *) instance;

// window API

- (void)handleDirectionQuestion:(NhYnQuestion *)q;
- (void)showYnQuestion:(NhYnQuestion *)q;
- (void)refreshMessages;
- (void)showExtendedCommands;

// gets called when core waits for input
- (void)nhPoskey;

- (void)refreshAllViews;

// text display is always blocking
- (void)displayText:(NSString *)text;

- (void)displayWindow:(NhWindow *)w;
- (void)showMenuWindow:(NhMenuWindow *)w;
- (void)clipAroundAnimated:(BOOL)animated;
- (void)clipAroundX:(int)x y:(int)y;
- (void)updateInventory;
- (void)getLine;

// touch handling

- (void)handleMapTapTileX:(int)x y:(int)y forLocation:(CGPoint)p inView:(UIView *)view;
- (void)handleDirectionTap:(e_direction)direction;
- (void)handleDirectionDoubleTap:(e_direction)direction;

// utility

- (NSInvocation *)dismissPopoverInvocation:(UIPopoverController *)popover;
- (void)resizePopover:(UIPopoverController *)popover;
- (void)dismissIfVisiblePopover:(UIPopoverController *)popover;
- (void)dismissAllVisiblePopovers;
- (void)presentPopover:(UIPopoverController *)popover
	 fromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
			  animated:(BOOL)animated;
- (void)presentPopover:(UIPopoverController *)popover fromRect:(CGRect)rect
				inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
			  animated:(BOOL)animated;

// called by popover controller for size measurements, actually the bounds of the containing scroll view
- (CGRect)mapViewBounds;

@end
