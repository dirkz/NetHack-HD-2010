//
//  TextInputController.m
//  NetHack
//
//  Created by dirk on 2/9/10.
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

#import "TextInputController.h"
#import "NhTextInputEvent.h"
#import "NhEventQueue.h"
#import "NhWindow.h"

@implementation TextInputController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[textField becomeFirstResponder];
	[messageTextView setText:[[NhWindow messageWindow] text]];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)tf {
	if (tf == textField) {
		[[NhEventQueue instance] addEvent:[NhTextInputEvent eventWithText:tf.text]];
		[self dismissModalViewControllerAnimated:NO];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
	if (tf == textField) {
		[tf resignFirstResponder];
		return YES;
	} else {
		return NO;
	}
}

@end
