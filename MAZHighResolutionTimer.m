//
//  MAZHighResolutionTimer.m
//  mach_wait_until
//
//  Created by Michael Hanna on 2014-11-30.
//  Copyright (c) 2014 maz.me. All rights reserved.
//

#import "MAZHighResolutionTimer.h"

#include <mach/mach.h>
#include <mach/mach_time.h>

static const uint64_t NANOS_PER_USEC = 1000ULL;
static const uint64_t NANOS_PER_MILLISEC = 1000ULL * NANOS_PER_USEC;
static const uint64_t NANOS_PER_SEC = 1000ULL * NANOS_PER_MILLISEC;
static mach_timebase_info_data_t timebase_info;

static uint64_t abs_to_nanos(uint64_t abs)
{
    if ( timebase_info.denom == 0 )
    {
        (void) mach_timebase_info(&timebase_info);
    }
    return abs * timebase_info.numer  / timebase_info.denom;
}

static uint64_t nanos_to_abs(uint64_t nanos)
{
    if ( timebase_info.denom == 0 )
    {
        (void) mach_timebase_info(&timebase_info);
    }
    return nanos * timebase_info.denom / timebase_info.numer;
}

void example_mach_wait_until()
{
    mach_timebase_info(&timebase_info);
    uint64_t time_to_wait = nanos_to_abs(10ULL * NANOS_PER_SEC);
    uint64_t now = mach_absolute_time();
    mach_wait_until(now + time_to_wait);
}

@interface MAZHighResolutionTimer()
@property (nonatomic) BOOL running;
@property (nonatomic) uint64_t abs_start_date;
- (void)run;
@end

@implementation MAZHighResolutionTimer
{
    uint64_t _now;
}

- (instancetype)initWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate
{
    if (self = [super init])
    {
        if (milliseconds < 10)
        {
            milliseconds = 10;
        }
        self.delegate = delegate;
        self.interval = milliseconds;
    }
    return self;
}

+ (instancetype)startWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate
{
    MAZHighResolutionTimer *timer = [[MAZHighResolutionTimer alloc] initWithInterval:milliseconds delegate:delegate];
    [timer start];
    return timer;
}

- (void)start
{
    if (!self.running)
    {
        [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
    }

}

- (void)stop
{
    self.running = NO;
    [[NSThread currentThread] cancel];
}

- (void)run
{
    [[NSThread currentThread] setThreadPriority:1.0];
    
    self.running = YES;
    self.abs_start_date = mach_absolute_time();
    uint64_t time_to_wait = nanos_to_abs(self.interval * NANOS_PER_MILLISEC);
    uint64_t i = 1;
    uint64_t next_fire_date = self.abs_start_date + (time_to_wait * i);
    mach_wait_until(next_fire_date);
    
    while (self.running)
    {
        if (mach_absolute_time() >= next_fire_date)
        {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(highResolutionTimerDidFire)])
            {
                [self.delegate highResolutionTimerDidFire];
                i++;
                next_fire_date = self.abs_start_date + (time_to_wait * i);
                mach_wait_until(next_fire_date);
            }
        }
    }
}

@end
