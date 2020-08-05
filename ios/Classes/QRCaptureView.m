//
//  QRCaptureView.m
//  Pods-Runner
//
//  Created by cdx on 2019/10/28.
//

#import "QRCaptureView.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCaptureView () <AVCaptureMetadataOutputObjectsDelegate, FlutterPlugin>

@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, weak) AVCaptureVideoPreviewLayer *captureLayer;

@end

@implementation QRCaptureView

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (self = [super initWithFrame:frame]) {
        NSString *name = [NSString stringWithFormat:@"net.touchcapture.qr.flutterqr/qrview_%lld", viewId];
        FlutterMethodChannel *channel = [FlutterMethodChannel
                                         methodChannelWithName:name
                                         binaryMessenger:registrar.messenger];
        self.channel = channel;
        [registrar addMethodCallDelegate:self channel:channel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captureLayer.frame = self.bounds;
    
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"pauseCamera"]) {
        [self pause];
    } else if ([call.method isEqualToString:@"resumeCamera"]) {
        [self resume];
    } else if ([call.method isEqualToString:@"toggleFlash"]) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (!device.hasTorch) {
            return;
        }
        
        [device lockForConfiguration:nil];
        if(device.torchMode != AVCaptureTorchModeOff){
            [device setTorchMode:AVCaptureTorchModeOff];
        }else{
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        [device unlockForConfiguration];
    } else if([call.method isEqualToString:@"init"]){
        NSDictionary* args = call.arguments;
        NSNumber* width = args[@"width"];
        NSNumber* height = args[@"height"];
        CGRect rect = CGRectMake(0, 0, width.floatValue, height.floatValue);
        
        NSDictionary* scanArgs = args[@"scannerRect"];
        NSNumber* scanTop = scanArgs[@"top"];
        NSNumber* scanLeft = scanArgs[@"left"];
        NSNumber* scanWidth = scanArgs[@"width"];
        NSNumber* scanHeight = scanArgs[@"height"];
        
        CGRect scanRect = CGRectMake(scanLeft.floatValue, scanTop.floatValue, scanWidth.floatValue, scanHeight.floatValue);
        
        [self initWithView:rect scannerRect:scanRect];
        
        
    }
}

- (void)initWithView:(CGRect)view scannerRect:(CGRect)scannerRect {

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized || status == AVAuthorizationStatusNotDetermined) {
        
        AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.captureLayer = layer;
        self.captureLayer.frame = view;
        
        layer.backgroundColor = [UIColor blackColor].CGColor;
        [self.layer addSublayer:layer];
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        [self.session addInput:input];
        [self.session addOutput:output];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        
        output.metadataObjectTypes = output.availableMetadataObjectTypes;
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [output setMetadataObjectTypes:@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                                         AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                                         AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            output.rectOfInterest = [self.captureLayer metadataOutputRectOfInterestForRect:scannerRect];
            [self.session startRunning];
        });
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"Authorization is required to use the camera, please check your permission settings: Settings> Privacy> Camera" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
    }
    
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {}


- (void)resume {
    [self.session startRunning];
}

- (void)pause {
    [self.session stopRunning];
}

- (void)removeFromSuperview{
    [super removeFromSuperview];
    
    [self.captureLayer removeFromSuperlayer];
    
    self.captureLayer.session = nil;
    self.captureLayer = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        for (AVCaptureInput *input in self.session.inputs) {
            [self.session removeInput:input];
        }
        for (AVCaptureOutput *output in self.session.outputs) {
            [self.session removeOutput:output];
        }
        [self.session stopRunning];
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *value = metadataObject.stringValue;
        if (value.length && self.channel) {
            [self.channel invokeMethod:@"onRecognizeQR" arguments:value];
        }
    }
}

- (void)dealloc {
    [self.session stopRunning];
}

@end
