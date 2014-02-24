#import "RootViewController.h"

#define MAX_RPM 6500
#define MAX_SPD 240

float calcSpeed(int gear, float rpm);
float calcTacho(int gear, float v);

@interface RootViewController ()
#include "root.property.h"
@property (nonatomic, assign) NSInteger gear;
@end

@implementation RootViewController
#include "root.synthesize.h"
@synthesize gear;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    gear = 0;
    #include "root.view-did-load.h"
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    #include "root.view-will-appear.h"
    [self displayValue];
}

- (void)viewWillLayoutSubviews {
    #include "root.view-will-layout-subviews.h"
}

- (void)segmentedValueChanged:(UISegmentedControl *)sender {
    gear = [sender selectedSegmentIndex];
    [self updateTacho];
    [self displayValue];
}

- (void)sliderValueChanged:(UISlider *)sender {
    if (speedmeter == sender) {
        [self updateTacho];
    } else {
        [self updateSpeed];
    }
    [self displayValue];
}

- (void)updateSpeed {
    CGFloat v = calcSpeed(gear, tachometer.value);
    if (v > MAX_SPD) {
        speedmeter.value = MAX_SPD;
        tachometer.value = calcTacho(gear, MAX_SPD);
    } else {
        speedmeter.value = v;
    }
}

- (void)updateTacho {
    CGFloat r = calcTacho(gear, speedmeter.value);
    if (r > MAX_RPM) {
        tachometer.value = MAX_RPM;
        speedmeter.value = calcSpeed(gear, MAX_RPM);
    } else {
        tachometer.value = r;
    }
}

- (void)displayValue {
    tacholabel.text = [NSString stringWithFormat:@"%0.0f rpm", tachometer.value];
    speedlabel.text = [NSString stringWithFormat:@"%0.2f km/h", speedmeter.value];
}

@end
