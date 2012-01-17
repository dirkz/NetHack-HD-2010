//
//  PopoverNhCommand.m
//  NetHack
//
//  Created by dirk on 2/4/10.
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

#import "PopoverNhCommand.h"

@implementation PopoverNhCommand

+ (id)commandWithTitle:(const char *)t keys:(const char *)c popover:(UIPopoverController *)popover {
	return [[[self alloc] initWithTitle:t keys:c popover:popover] autorelease];
}

+ (id)commandWithTitle:(const char *)t key:(char)c popover:(UIPopoverController *)popover {
	return [[[self alloc] initWithTitle:t key:c popover:popover] autorelease];
}

- (id)initWithTitle:(const char *)t keys:(const char *)c popover:(UIPopoverController *)popover {
	if (self = [super initWithTitle:t keys:c]) {
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:
							 [popover methodSignatureForSelector:@selector(dismissPopoverAnimated:)]];
		[inv setTarget:popover];
		[inv setSelector:@selector(dismissPopoverAnimated:)];
		BOOL arg = YES;
		[inv setArgument:&arg atIndex:2];
		[inv retainArguments];
		[self addInvocation:inv];
	}
	return self;
}

- (id)initWithTitle:(const char *)t key:(char)c popover:(UIPopoverController *)popover {
	char cmd[] = { c, '\0' };
	return [self initWithTitle:t keys:cmd popover:popover];
}

@end
