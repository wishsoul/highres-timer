//
//  ViewController.m
//  highres-timer
//
//  Created by Michael Hanna on 2014-11-30.
//  Copyright (c) 2014 maz. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController
{
    MAZHighResolutionTimer *_timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _timer = [MAZHighResolutionTimer startWithInterval:[self secondsToMilliseconds:1.0] delegate:self];
    self.label.text = @"fire";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)highResolutionTimerDidFire
{
    NSLog(@"it fired");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.backgroundColor = (self.label.backgroundColor == [UIColor whiteColor]) ? [UIColor blackColor] : [UIColor whiteColor];
        self.label.textColor = (self.label.textColor == [UIColor blackColor]) ? [UIColor whiteColor] : [UIColor blackColor];
    });
}

- (uint64_t)secondsToMilliseconds:(NSTimeInterval)timeInterval
{
    return (timeInterval * 1000);
}

@end
