#import "AppDelegate.h"
#import "HsFFI.h"

int main(int argc, char **argv) {
    @autoreleasepool{
        hs_init(&argc, &argv);
        int ret = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        hs_exit();
        return ret;
    }
}
