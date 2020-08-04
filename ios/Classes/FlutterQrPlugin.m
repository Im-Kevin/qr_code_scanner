#import "FlutterQrPlugin.h"
#import "QRCaptureViewFactory.h"
@implementation FlutterQrPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    QRCaptureViewFactory *factory = [[QRCaptureViewFactory alloc] initWithRegistrar:registrar];
    [registrar registerViewFactory:factory withId:@"net.touchcapture.qr.flutterqr/qrview"];
}
@end
