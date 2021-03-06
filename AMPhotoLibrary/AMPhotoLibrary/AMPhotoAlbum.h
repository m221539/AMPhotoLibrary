//
//  AMPhotoAlbum.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AMPhotoAlbum, AMPhotoAsset, PHAssetCollection, PHFetchResult;

typedef void (^AMPhotoManagerResultBlock)(BOOL success, NSError *error);
typedef void (^AMPhotoManagerCheckBlock)(AMPhotoAlbum *album, NSError *error);
typedef void (^AMPhotoManagerAlbumEnumerationBlock)(AMPhotoAlbum *album, BOOL *stop);
typedef void (^AMPhotoManagerAssetEnumerationBlock)(AMPhotoAsset *asset, NSUInteger index, BOOL *stop);

@interface AMAssetsFilter : NSObject

+ (AMAssetsFilter *)allAssets;
+ (AMAssetsFilter *)allImages;
+ (AMAssetsFilter *)allVideos;
+ (AMAssetsFilter *)allAudios;

@end

@interface AMPhotoAlbum : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, assign) NSInteger numberOfAssets;
@property (nonatomic, readonly, strong) UIImage *posterImage;

@property (nonatomic, strong) AMAssetsFilter *assetsFilter;


+ (AMPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection;
- (PHAssetCollection *)asPHAssetCollection;

@property (nonatomic, readonly, strong) PHFetchResult *fetchResult;


- (void)changed:(id)afterChanges;
- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock;

@end
