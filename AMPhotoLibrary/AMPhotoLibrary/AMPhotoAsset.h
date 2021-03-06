//
//  AMPhotoAsset.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AMAssetMediaType) {
    AMAssetMediaTypeUnknown = 0,
    AMAssetMediaTypeImage   = 1,
    AMAssetMediaTypeVideo   = 2,
    AMAssetMediaTypeAudio   = 3,
};

@class CLLocation, PHAsset, AVPlayerItem;

@interface AMPhotoAsset : NSObject

@property (nonatomic, readonly, assign) AMAssetMediaType mediaType;

@property (nonatomic, readonly, assign) CGSize dimensions;
@property (nonatomic, readonly, strong) NSDictionary *metadata;
@property (nonatomic, readonly, strong) NSDate *creationDate;
@property (nonatomic, readonly, strong) CLLocation *location;
@property (nonatomic, readonly, copy) NSString *localIdentifier;
@property (nonatomic, readonly, strong) NSURL *assetURL;
@property (nonatomic, readonly, assign) unsigned long long fileSize;

@property (nonatomic, readonly, strong) UIImage *thumbnail;
@property (nonatomic, readonly, strong) UIImage *aspectRatioThumbnail;
@property (nonatomic, readonly, copy) NSString *UTI;
@property (nonatomic, readonly, copy) NSString *mimeType;

//Image Property
/*
 UIImageOrientation for fullResolutionImage
 */
@property (nonatomic, readonly, assign) UIImageOrientation orientation;
@property (nonatomic, readonly, strong) UIImage *fullScreenImage;
@property (nonatomic, readonly, strong) UIImage *fullResolutionImage;
@property (nonatomic, readonly, strong) NSData *imageFileData;

//Video Property
@property (nonatomic, readonly, assign) NSTimeInterval duration;


+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset;
- (PHAsset *)asPHAsset;

+ (NSURL *)fetchPlayerItemURL:(AVPlayerItem *)playerItem;

+ (void)fetchAsset:(AMPhotoAsset *)asset rawData:(void (^)(NSData *, AVPlayerItem *))resultBlock;

/*
 For Image: use rawData
 For Video: use playerItem, for URL use 'fetchPlayerItemURL'
 For iOS8 below: use assetRepresentation
 */


typedef NS_ENUM(NSInteger, AMAssetImageType) {
    AMAssetImageTypeThumbnail = 0,
    AMAssetImageTypeAspectRatioThumbnail = 1,
    AMAssetImageTypeFullScreen = 2,
    AMAssetImageTypeFullResolution = 3
};

/*
 For async mode get image, use this method
 */
+ (void)fetchAsset:(AMPhotoAsset *)asset withImageType:(AMAssetImageType)imageType imageResult:(void(^)(UIImage *image))resultBlock;

@end
