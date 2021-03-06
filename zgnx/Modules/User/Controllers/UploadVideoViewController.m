//
//  UploadVideoViewController.m
//  zgnx
//
//  Created by tomwey on 5/29/16.
//  Copyright © 2016 tangwei1. All rights reserved.
//

#import "UploadVideoViewController.h"
#import "CustomNavBar.h"
#import "LoadDataService.h"
#import "Defines.h"
#import <QiniuSDK.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UploadVideoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) LoadDataService *uploadInfoService;

@property (nonatomic, strong) UIButton *captureVideoButton;
@property (nonatomic, strong) UIButton *selectVideoButton;

@property (nonatomic, strong) UIImagePickerController *videoPicker;

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

@property (nonatomic, copy) NSDictionary *uploadInfo;

@property (nonatomic, strong) QNUploadManager *uploadManager;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UILabel        *videoNameLabel;

@property (nonatomic, strong) UIButton       *nextButton;

@property (nonatomic, strong) UIImage *coverImage;

@property (nonatomic, assign) BOOL uploadingVideo;

@property (nonatomic, strong) UIWebView *uploadIntroView;

@end

@implementation UploadVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.uploadingVideo = NO;
    
    self.navBar.title = @"上传视频";
    
    self.uploadInfoService = [[LoadDataService alloc] init];
    
    __weak typeof(self) me = self;
    NSString *token = [[UserService sharedInstance] currentUser].authToken ?: @"";
    
    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    
    [self.uploadInfoService GET:@"/videos/upload_info" params:@{ @"token" : token }
                     completion:^(id result, NSError *error)
    {
                         
        [MBProgressHUD hideAllHUDsForView:self.contentView animated:YES];
        if ( !error ) {
            me.captureVideoButton.enabled = YES;
            me.selectVideoButton.enabled = YES;
            
            // 加载视频简介
            [me.uploadIntroView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kUploadIntroURL]]];
            
            me.uploadInfo = result;
        } else {
            [[Toast showText:@"获取上传信息失败！"] setBackgroundColor:NAV_BAR_BG_COLOR];
            
            [me.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)back
{
    if ( self.uploadingVideo ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"您确定吗？"
                                                        message:@"上传还未完成，退出将不会保存数据"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"确定", @"取消", nil];
        [alert show];
    } else {
        [self backToLastPage];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 ) {
        [self backToLastPage];
    }
}

- (void)backToLastPage
{
    NSUInteger count = [self.navigationController.viewControllers count];
    NSInteger index = count - 2;
    UIViewController *vc = self.navigationController.viewControllers[index];
    if ( [NSStringFromClass([vc class]) isEqualToString:@"LoginViewController"] ) {
        vc = self.navigationController.viewControllers[index - 1];
    }
    
    [self.navigationController popToViewController:vc animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"info: %@", info);
    //    UIImagePickerControllerMediaType = "public.movie";
    //    UIImagePickerControllerMediaURL = "file:///private/var/mobile/Applications/CDBCF96C-D0BC-4FF1-A5A7-E72317156F38/tmp/trim.535F682C-B779-482A-A7C9-C1E3CD458CD7.MOV";
    //    UIImagePickerControllerReferenceURL = "assets-library://asset/asset.mp4?id=4D31FDA0-AEED-44DF-AA4C-241F7D8E5CD9&ext=mp4";
    
    self.uploadingVideo = YES;
    
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    
    __weak typeof(self) me = self;
    
    // 生成视频封面图
    [self generateThumbnailFromVideoAtURL:videoURL completion:^(UIImage *image, NSError *error) {
        if ( !error ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                me.coverImage = image;
            });
        }
    }];
    
     //开始处理视频，并上传
//    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
//    [self handleVideo:videoURL completion:^(NSURL *outputURL, NSError *error) {
//        [MBProgressHUD hideHUDForView:me.contentView animated:YES];
//        if ( error ) {
//            [SimpleToast showText:error.domain];
//        } else {
//            [me uploadVideo:outputURL];
//        }
//    }];
    // 此处不用处理，上传七牛后台编码会自动帮我们纠正方向
    [self uploadVideo:videoURL];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadVideo:(NSURL *)outputURL
{
    self.uploadIntroView.hidden = YES;
    
    self.progressView.hidden = NO;
    self.progressView.progress = 0.0;
    
    NSData *data = [NSData dataWithContentsOfURL:outputURL];
    
    QNUploadOption *option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
        NSLog(@"percent: %f", percent);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.nextButton.hidden = YES;
            
            self.progressView.hidden = NO;
            self.progressView.progress = percent;
            
            self.videoNameLabel.hidden = YES;
        });
        
    }];
    
    NSString *token = self.uploadInfo[@"token"];
    
    __weak typeof(self) me = self;
    [self.uploadManager putData:data
                            key:self.uploadInfo[@"key"]
                          token:token
                       complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp)
     {
         
         NSLog(@"info: %@, key: %@, resp: %@", info, key, resp);
         //        [me.progressView removeFromSuperview];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             me.nextButton.hidden = NO;
             
             me.progressView.hidden = YES;
             
             me.videoNameLabel.hidden = NO;
             me.videoNameLabel.text = @"上传完成，请点击下一步！";//me.uploadInfo[@"filename"];
         });
     }
                         option:option];
}

- (void)handleVideo:(NSURL *)videoURL completion:(void (^)(NSURL *outputURL, NSError *error))completion
{
    NSError *error = nil;
    AVURLAsset *videoAssetURL = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoTrack = [[videoAssetURL tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    AVAssetTrack *audioTrack = [[videoAssetURL tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetURL.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetURL.duration) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    CGAffineTransform transformToApply = videoTrack.preferredTransform;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    [layerInstruction setTransform:transformToApply atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:videoAssetURL.duration];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake( kCMTimeZero, videoAssetURL.duration);
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, 30); //select the frames per second
    videoComposition.renderScale = 1.0;
    
    NSLog(@"transform: %@", NSStringFromCGAffineTransform(videoTrack.preferredTransform));
    // [0, 1, -1, 0, 360, 0] home 朝下
    // [0, -1, 1, 0, 0, 480] home 朝上
    // [1, 0, 0, 1, 0, 0]    home 朝右
    // [-1, 0, 0, -1, 480, 360] home 朝左
    BOOL isLandscape = ( videoTrack.preferredTransform.a == 1 && videoTrack.preferredTransform.b == 0 ) ||
    ( videoTrack.preferredTransform.a == -1 && videoTrack.preferredTransform.b == 0 );
    
    if ( !isLandscape ) {
        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
    } else {
        videoComposition.renderSize = videoTrack.naturalSize;
    }
//    videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width); //select you video size
    // (a = 1, b = 0, c = 0, d = 1, tx = 0, ty = 0)
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMddHHmmss";
    NSString *fileName = [NSString stringWithFormat:@"%@.MOV", [df stringFromDate:[NSDate date]]];
    exportSession.outputURL =
    [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie; //very important select you video format (AVFileTypeQuickTimeMovie, AVFileTypeMPEG4, etc...)
    exportSession.videoComposition = videoComposition;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetURL.duration);
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"progress: %f", exportSession.progress);
        switch ([exportSession status]) {
                
            case AVAssetExportSessionStatusCompleted: {
                
                NSLog(@"Triming Completed");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( completion ) {
                        completion(exportSession.outputURL, nil);
                    }
                });
                //generate video thumbnail
//                self.videoUrl = exportSession.outputURL;
//                AVURLAsset *videoAssetURL = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
//                AVAssetImageGenerator *genrateAsset = [[AVAssetImageGenerator alloc] initWithAsset:videoAssetURL];
//                genrateAsset.appliesPreferredTrackTransform = YES;
//                CMTime time = CMTimeMakeWithSeconds(0.0,600);
//                NSError *error = nil;
//                CMTime actualTime;
//                
//                CGImageRef cgImage = [genrateAsset copyCGImageAtTime:time actualTime:&actualTime error:&error];
//                self.videoImage = [[UIImage alloc] initWithCGImage:cgImage];
//                CGImageRelease(cgImage);
                
                break;
            }
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"Triming Completed");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ( completion ) {
                        completion(nil, exportSession.error);
                    }
                });
                break;
            }
            default: {
                break;
            }
        }
    }];
}

- (void)generateThumbnailFromVideoAtURL:(NSURL *)contentURL completion:(void (^)(UIImage *image, NSError *error))completion
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:nil];
    
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMake(1, 60);
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:time]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        UIImage *newImage = [[UIImage alloc] initWithCGImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( completion ) {
                completion(newImage, error);
            }
        });
    }];
    
    //    CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:NULL error:&err];
    
    //    theImage = [[UIImage alloc] initWithCGImage:imgRef];
    
    //    CGImageRelease(imgRef);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)showAlert:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:@""
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles: @"确定", nil] show];
}

- (void)captureVideo
{
    if ( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
        [self showAlert:@"设备不支持！"];
        return;
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted
        || authStatus == AVAuthorizationStatusDenied) {
        NSLog(@"摄像头已被禁用，您可在设置应用程序中进行开启");
        [SimpleToast showText:@"摄像头已被禁用，您可在设置应用程序中进行开启"];
        return;
    }
    
    self.videoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.videoPicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    
    [self presentViewController:self.videoPicker animated:YES completion:nil];
}

- (void)selectVideo
{
    if ( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] ) {
        [self showAlert:@"设备不支持！"];
        return;
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted
        || authStatus == AVAuthorizationStatusDenied) {
        NSLog(@"摄像头已被禁用，您可在设置应用程序中进行开启");
        [SimpleToast showText:@"摄像头已被禁用，您可在设置应用程序中进行开启"];
        return;
    }
    
    self.videoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    [self presentViewController:self.videoPicker animated:YES completion:nil];
}

- (void)gotoNext
{
    UIViewController *vc = [[CTMediator sharedInstance] CTMediator_openUploadFinalVCWithImage:self.coverImage
                                                                                     filename:self.uploadInfo[@"filename"]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIButton *)captureVideoButton
{
    if ( !_captureVideoButton ) {
        _captureVideoButton = AWCreateTextButton(CGRectZero,
                                                 @"拍摄一段视频",
                                                 [UIColor whiteColor],
                                                 self, @selector(captureVideo));
        _captureVideoButton.backgroundColor = NAV_BAR_BG_COLOR;
        
        CGFloat width = self.contentView.width * 0.618;
        _captureVideoButton.frame = CGRectMake( self.contentView.width / 2.0 - width / 2.0 ,
                                               30,
                                               width, 40);
        [self.contentView addSubview:_captureVideoButton];
    }
    return _captureVideoButton;
}

- (UIButton *)selectVideoButton
{
    if ( !_selectVideoButton ) {
        _selectVideoButton = AWCreateTextButton(CGRectZero,
                                                 @"选取本地",
                                                 [UIColor whiteColor],
                                                 self, @selector(selectVideo));
        _selectVideoButton.backgroundColor = NAV_BAR_BG_COLOR;
        
        _selectVideoButton.frame = self.captureVideoButton.frame;
        _selectVideoButton.top = self.captureVideoButton.bottom + 20;
        
        [self.contentView addSubview:_selectVideoButton];
    }
    return _selectVideoButton;
}

- (UIImagePickerController *)videoPicker
{
    if ( !_videoPicker ) {
        _videoPicker = [[UIImagePickerController alloc] init];
        _videoPicker.delegate = self;
        _videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        _videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
        _videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }
    
    return _videoPicker;
}

- (QNUploadManager *)uploadManager
{
    if ( !_uploadManager ) {
        _uploadManager = [[QNUploadManager alloc] init];
    }
    return _uploadManager;
}

- (UIProgressView *)progressView
{
    if ( !_progressView ) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.contentView addSubview:_progressView];
        
        _progressView.frame = self.selectVideoButton.frame;
        _progressView.height = 20;
        _progressView.top = self.selectVideoButton.bottom + 20;
    }
    return _progressView;
}

- (UILabel *)videoNameLabel
{
    if ( !_videoNameLabel ) {
        _videoNameLabel = AWCreateLabel(self.progressView.frame,
                                        nil,
                                        NSTextAlignmentCenter,
                                        nil,
                                        [UIColor blackColor]);
        _videoNameLabel.height = 34;
//        _videoNameLabel.width = self.contentView.width;
        _videoNameLabel.width  = self.contentView.width;
        _videoNameLabel.left   = 0;
        
        [self.contentView addSubview:_videoNameLabel];
    }
    return _videoNameLabel;
}

- (UIButton *)nextButton
{
    if ( !_nextButton ) {
        _nextButton = AWCreateTextButton(self.selectVideoButton.frame,
                                         @"下一步",
                                         NAV_BAR_BG_COLOR,
                                         self,
                                         @selector(gotoNext));
        
        [self.contentView addSubview:_nextButton];
        _nextButton.top = self.videoNameLabel.bottom + 30;
        
        _nextButton.backgroundColor = [UIColor whiteColor];
        
        _nextButton.layer.borderColor = [NAV_BAR_BG_COLOR CGColor];
        _nextButton.layer.borderWidth = 1;
    }
    return _nextButton;
}

- (UIWebView *)uploadIntroView
{
    if ( !_uploadIntroView ) {
        _uploadIntroView = [[UIWebView alloc] init];
        [self.contentView addSubview:_uploadIntroView];
        _uploadIntroView.scalesPageToFit = YES;
        _uploadIntroView.backgroundColor = BG_COLOR_GRAY;
        _uploadIntroView.frame = CGRectMake(0, self.selectVideoButton.bottom + 20,
                                            self.contentView.width,
                                            self.contentView.height - self.selectVideoButton.bottom - 20);
    }
    return _uploadIntroView;
}

@end
