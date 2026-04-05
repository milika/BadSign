//
//  MoonPhase.h
//  Bad Sign
//
//  Created by admin on 12/14/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

@interface Signs : NSObject {
@private
	NSDate *now;
}
- (id) initWithDate:(NSDate*) date;

- (float) phase;
- (float) moonSign;
- (int) chineseSign;
- (int) westernSign;
- (int) aztecSign;
- (int) mayanSign;
- (int) egyptianSign;
- (int) zoroastoSign;
- (int) celticSign;
- (int) norseSign;
- (int) slavicSign;
- (int) numerologySign;
- (int) geekSign;

@end