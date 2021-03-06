//
//  AMPhotoAsset.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAsset.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>

#define AMPhotoAssetThumbnailSize CGSizeMake(160, 160)

@implementation AMPhotoAsset {
    @private
    
    PHAsset *_phAsset;
    
    AMAssetMediaType _mediaType;
    unsigned long long _fileSize;
    
    BOOL _hasGotInfo;
    BOOL _hasGotFullMetaData;
    NSMutableDictionary *_metaData;
    NSURL *_assetURL;
    NSString *_UTI;
    NSString *_mimeType;
    NSString *_localIdentifier;
    
    UIImageOrientation _orientation;
    
    NSTimeInterval _duration;
}


+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset
{
    return [[AMPhotoAsset alloc] initWithPHAsset: asset];
}

- (AMPhotoAsset *)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        _phAsset = asset;
        [self commonInit];
    }
    return self;
}

- (PHAsset *)asPHAsset
{
    return _phAsset;
}


- (void)commonInit
{
    _hasGotInfo = NO;
    _hasGotFullMetaData = NO;
    _duration = 0.f;
    _orientation = UIImageOrientationUp;
    
    switch (_phAsset.mediaType) {
        case PHAssetMediaTypeImage:
            _mediaType = AMAssetMediaTypeImage;
            break;
        case PHAssetMediaTypeVideo:
            _mediaType = AMAssetMediaTypeVideo;
            _duration = _phAsset.duration;
            break;
        case PHAssetMediaTypeAudio:
            _mediaType = AMAssetMediaTypeAudio;
            break;
        default:
            _mediaType = AMAssetMediaTypeUnknown;
            break;
    }
}

- (AMAssetMediaType)mediaType
{
    return _mediaType;
}

- (CGSize)dimensions
{
    return CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
}

enum {
    kAMASSETMETADATA_PENDINGREADS = 1,
    kAMASSETMETADATA_ALLFINISHED = 0
};

- (NSDictionary *)metadata
{
    if (!_hasGotFullMetaData) {
        _hasGotFullMetaData = YES;
        
        if (PHAssetMediaTypeImage == _mediaType) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.version = PHImageRequestOptionsVersionCurrent;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.synchronous = YES;
            
            [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                if (NULL != source) {
                    _metaData = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
                    CFRelease(source);
                }
            }];
        }
        else if (PHAssetMediaTypeVideo == _mediaType) {
            PHVideoRequestOptions *request = [PHVideoRequestOptions new];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            request.networkAccessAllowed = YES;
            
            NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
            [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                
                _metaData = [NSMutableDictionary dictionary];
                NSArray *commonMetaData = playerItem.asset.commonMetadata;
                for (AVMetadataItem *item in commonMetaData) {
                    _metaData[item.commonKey] = item.value;
                }
                
                [assetReadLock lock];
                [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
            }];
            [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
            [assetReadLock unlock];
            assetReadLock = nil;
        }
    }
    return _metaData;
}

- (NSDate *)creationDate
{
    return _phAsset.creationDate;
}

- (CLLocation *)location
{
    return _phAsset.location;
}

- (NSString *)localIdentifier
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _localIdentifier;
}

- (NSURL *)assetURL
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _assetURL;
}

- (unsigned long long)fileSize
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileSize;
}

- (UIImageOrientation)orientation
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _orientation;
}

- (NSString *)UTI
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _UTI;
}

- (NSString *)mimeType
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _mimeType;
}

- (UIImage *)thumbnail
{
    __block UIImage *image = nil;
    CGSize pixelSize = CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
    CGFloat pixelWidth = MIN(pixelSize.width, pixelSize.height);
    CGRect cropRect = CGRectMake((pixelSize.width - pixelWidth) * 0.5, (pixelSize.height - pixelWidth) * 0.5, pixelWidth, pixelWidth);
    
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeExact;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.normalizedCropRect = CGRectMake(cropRect.origin.x / pixelSize.width, cropRect.origin.y / pixelSize.height, cropRect.size.width / pixelSize.width, cropRect.size.height / pixelSize.height);
    request.synchronous = YES;
    
    [[PHCachingImageManager defaultManager] requestImageForAsset: _phAsset targetSize:AMPhotoAssetThumbnailSize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    return image;
}

- (UIImage *)aspectRatioThumbnail
{
    __block UIImage *image = nil;
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeFast;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = YES;
    
    [[PHCachingImageManager defaultManager] requestImageForAsset: _phAsset targetSize:AMPhotoAssetThumbnailSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullScreenImage
{
    __block UIImage *image = nil;
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeExact;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = YES;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    screenSize.width *= scale;
    screenSize.height *= scale;
    [[PHCachingImageManager defaultManager] requestImageForAsset: _phAsset targetSize:screenSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullResolutionImage
{
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    __block UIImage *image = nil;
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeNone;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = YES;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        image = [UIImage imageWithData: imageData];
    }];
    return image;
}

- (NSData *)imageFileData {
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    __block NSData *imageFileData = nil;
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeNone;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = YES;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        imageFileData = imageData;
    }];
    return imageFileData;
}

- (NSTimeInterval)duration
{
    return _duration;
}

- (void)getInfo
{
    if (!_hasGotInfo) {
        _hasGotInfo = YES;
        if (PHAssetMediaTypeImage == _mediaType) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.version = PHImageRequestOptionsVersionCurrent;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.synchronous = YES;
            
            [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                _fileSize = imageData.length;
                _UTI = dataUTI;
                _localIdentifier = _phAsset.localIdentifier;
                _assetURL = [info objectForKey:@"PHImageFileURLKey"];
                _orientation = orientation;
            }];
        }
        else if (PHAssetMediaTypeVideo == _mediaType) {
            PHVideoRequestOptions *request = [PHVideoRequestOptions new];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            request.networkAccessAllowed = YES;
            
            NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
            [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                NSURL *videoURL = [[self class] fetchPlayerItemURL:playerItem];
                NSNumber *fileSize = nil;;
                if ([videoURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil]) {
                    _fileSize = [fileSize unsignedLongLongValue];
                }
                else {
                    _fileSize = 0;
                }
                _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([videoURL pathExtension]), NULL));
                _localIdentifier = _phAsset.localIdentifier;
                _assetURL = videoURL;
                
                [assetReadLock lock];
                [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
            }];
            [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
            [assetReadLock unlock];
            assetReadLock = nil;
        }
    }
    CFStringRef UTI = (__bridge CFStringRef)_UTI;
    if (NULL != UTI) {
        _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    }
}

+ (NSURL *)fetchPlayerItemURL:(AVPlayerItem *)playerItem
{
    AVAsset *videoAsset = playerItem.asset;
    NSURL *videoURL = nil;
    if ([videoAsset isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)videoAsset;
        videoURL = urlAsset.URL;
    }
    else if ([videoAsset isKindOfClass:[AVComposition class]]) {
        AVComposition *composition = (AVComposition *)videoAsset;
        AVCompositionTrack *videoTrack = nil;
        for (AVCompositionTrack *track in composition.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                videoTrack = track;
                break;
            }
        }
        if (nil != videoTrack) {
            NSArray *segments = videoTrack.segments;
            for (AVCompositionTrackSegment *segment in segments) {
                videoURL = segment.sourceURL;
                break;
            }
        }
    }
    return videoURL;
}

+ (void)fetchAsset:(AMPhotoAsset *)asset rawData:(void (^)(NSData *, AVPlayerItem *))resultBlock
{
    if (AMAssetMediaTypeImage == asset.mediaType) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeNone;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = NO;
        request.networkAccessAllowed = YES;
        
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset.asPHAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            resultBlock(imageData, nil);
        }];
    }
    else if (AMAssetMediaTypeVideo == asset.mediaType) {
        PHVideoRequestOptions *request = [PHVideoRequestOptions new];
        request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        request.version = PHVideoRequestOptionsVersionCurrent;
        request.networkAccessAllowed = YES;
        
        [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:asset.asPHAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
            resultBlock(nil, playerItem);
        }];
    }
}

+ (void)fetchAsset:(AMPhotoAsset *)asset withImageType:(AMAssetImageType)imageType imageResult:(void (^)(UIImage *))resultBlock
{
    if (AMAssetMediaTypeImage != asset.mediaType) {
        if (AMAssetImageTypeFullResolution == imageType) {
            resultBlock(nil);
            return;
        }
    }
    
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.version = PHImageRequestOptionsVersionCurrent;
    //PHImageRequestOptionsDeliveryModeHighQualityFormat: Make sure clients will get one result only
    request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    request.synchronous = NO;
    request.networkAccessAllowed = YES;
    
    CGSize targetSize = CGSizeZero;
    switch (imageType) {
        case AMAssetImageTypeThumbnail:
        {
            targetSize = AMPhotoAssetThumbnailSize;
            CGSize pixelSize = asset.dimensions;
            CGFloat pixelWidth = MIN(pixelSize.width, pixelSize.height);
            CGRect cropRect = CGRectMake((pixelSize.width - pixelWidth) * 0.5, (pixelSize.height - pixelWidth) * 0.5, pixelWidth, pixelWidth);
            request.normalizedCropRect = CGRectMake(cropRect.origin.x / pixelSize.width, cropRect.origin.y / pixelSize.height, cropRect.size.width / pixelSize.width, cropRect.size.height / pixelSize.height);
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            break;
        }
        case AMAssetImageTypeAspectRatioThumbnail:
        {
            targetSize = AMPhotoAssetThumbnailSize;
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        }
            break;
        case AMAssetImageTypeFullScreen:
        {
            CGFloat scale = [UIScreen mainScreen].scale;
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            targetSize = CGSizeMake(screenSize.width *= scale, screenSize.height *= scale);
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
        }
            break;
        case AMAssetImageTypeFullResolution:
        {
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
        }
            break;
        default:
            break;
    }
    
    if (AMAssetImageTypeFullResolution != imageType) {
        [[PHCachingImageManager defaultManager] requestImageForAsset:[asset asPHAsset] targetSize:targetSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
            resultBlock(result);
        }];
    }
    else {
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:[asset asPHAsset] options:request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (nil == imageData) {
                resultBlock(nil);
            }
            else {
                resultBlock([UIImage imageWithData:imageData]);
            }
        }];
    }

}

@end
