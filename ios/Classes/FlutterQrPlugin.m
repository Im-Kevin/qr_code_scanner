#import "FlutterQrPlugin.h"
#import "qr_code_scanner/qr_code_scanner-Swift.h"
@implementation FlutterQrPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    QRCaptureViewFactory *factory = [[QRCaptureViewFactory alloc] initWithRegistrar:registrar];
    [registrar registerViewFactory:factory withId:@"net.touchcapture.qr.flutterqr/qrview"];
}
@end
