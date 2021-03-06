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

@interface MAZHighResolutionTimer()
@property (nonatomic) uint64_t abs_start_date;
- (void)run;
@end

@implementation MAZHighResolutionTimer

- (instancetype)initWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate error:(NSError **)error
{
    if (self = [super init])
    {
        if (milliseconds <= 0)
        {
            *error = [NSError errorWithDomain:@"me.maz.highres-timer.nonzero.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Interval must be greater than zero"}];
            return nil;
        }
        
        uint64_t time_to_wait = nanos_to_abs(milliseconds * NANOS_PER_MILLISEC);
        uint64_t first_fire_date = mach_absolute_time() + (time_to_wait);
        
        if (first_fire_date < mach_absolute_time())
        {
            *error = [NSError errorWithDomain:@"me.maz.highres-timer.overflow.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Integer overflow"}];
            return nil;
        }
        self.delegate = delegate;
        self.interval = milliseconds;
        self.running = NO;
    }
    return self;
}

+ (instancetype)startWithInterval:(uint64_t)milliseconds delegate:(id<MAZHighResolutionTimerDelegate>)delegate error:(NSError **)error
{
    MAZHighResolutionTimer *timer = [[MAZHighResolutionTimer alloc] initWithInterval:milliseconds delegate:delegate error:error];
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
    
    NSLog(@"next_fire_date: %llu", next_fire_date);
    
    while (self.running)
    {
        if (mach_absolute_time() >= next_fire_date)
        {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(highResolutionTimerDidFire)])
            {
                [self.delegate highResolutionTimerDidFire];
                i++;
                next_fire_date = self.abs_start_date + (time_to_wait * i);
                uint64_t mat = mach_absolute_time();
                NSLog(@"next_fire_date - mach_absolute_time = %llu - %llu = %llu | drift: %llu", next_fire_date, mat, next_fire_date - mat, time_to_wait - (next_fire_date - mat));
                mach_wait_until(next_fire_date);
            }
        }
    }
}

@end
