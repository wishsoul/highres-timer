//
//  MAZHighResolutionTimer.h
//  mach_wait_until
//
//  Created by Michael Hanna on 2014-11-30.
//  Copyright (c) 2014 maz.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MAZHighResolutionTimerDelegate <NSObject>

@required
- (void)highResolutionTimerDidFire;

@end
@interface MAZHighResolutionTimer : NSObject
@property (nonatomic) uint64_t interval;
@property (nonatomic) BOOL running;
@property (strong, nonatomic) id <MAZHighResolutionTimerDelegate> delegate;
- (instancetype)initWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate error:(NSError **)error NS_DESIGNATED_INITIALIZER;
+ (instancetype)startWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate error:(NSError **)error;
- (void)start;
- (void)stop;

@end
