//
//  TouchInfoStore.h
//  SlashEM
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
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

#import <Foundation/Foundation.h>

@class ZTouchInfo;

@interface ZTouchInfoStore : NSObject {
	
	NSMutableDictionary *currentTouchInfos;
	NSTimeInterval singleTapTimestamp;

}

@property (nonatomic, readonly) int count;
@property (nonatomic, assign) NSTimeInterval singleTapTimestamp;
@property (nonatomic, readonly) NSTimeInterval doubleTapDuration;

+ (NSTimeInterval)doubleTapDuration;

- (void)storeTouches:(NSSet *)touches;
- (ZTouchInfo *)touchInfoForTouch:(UITouch *)t;
- (void)removeTouches:(NSSet *)touches;

@end
