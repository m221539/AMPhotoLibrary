//
//  AMPhotoAlbum.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAlbum.h"

@interface AMAssetsFilter ()

@property (nonatomic, assign) BOOL includeImage;
@property (nonatomic, assign) BOOL includeVideo;
@property (nonatomic, assign) BOOL includeAudio;

@end

@implementation AMAssetsFilter

+ (AMAssetsFilter *)allAssets
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = YES;
    filter.includeAudio = YES;
    return filter;
}

+ (AMAssetsFilter *)allImages
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = NO;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allVideos
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = YES;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allAudios
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = NO;
    filter.includeAudio = YES;
    return filter;
}

- (BOOL)isEqual:(id)object
{
    AMAssetsFilter *filter = (AMAssetsFilter *)object;
    return (self.includeImage == filter.includeImage) && (self.includeVideo == filter.includeVideo) && (self.includeAudio == filter.includeAudio);
}

@end

@interface AMPhotoAlbum ()
{
    PHAssetCollection *_assetCollection;
    PHFetchResult *_fetchResult;
    
    BOOL _hasGotPosterImage;
    UIImage *_posterImage;
}
@end

@implementation AMPhotoAlbum


+ (AMPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection
{
    return [[AMPhotoAlbum alloc] initWithPHAssetCollection: assetCollection];
}

- (AMPhotoAlbum *)initWithPHAssetCollection:(PHAssetCollection *)assetCollection
{
    self = [super init];
    if (self) {
        _assetCollection = assetCollection;
        [self commonInit];
    }
    return self;
}

- (PHAssetCollection *)asPHAssetCollection
{
    return _assetCollection;
}

- (PHFetchResult *)fetchResult
{
    if (nil == _fetchResult) {
        if (nil == self.assetsFilter) {
            _fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:nil];
        }
        else {
            NSString *queryString = @"";
            if (self.assetsFilter.includeImage) {
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeImage];
            }
            if (self.assetsFilter.includeVideo) {
                if (queryString.length > 0) {
                    queryString = [queryString stringByAppendingString:@" || "];
                }
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeVideo];
            }
            if (self.assetsFilter.includeAudio) {
                if (queryString.length > 0) {
                    queryString = [queryString stringByAppendingString:@" || "];
                }
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeVideo];
            }
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.predicate = [NSPredicate predicateWithFormat:queryString];
            _fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:fetchOptions];
        }
    }
    return _fetchResult;
}


- (void)commonInit
{
    [self setNeedsUpdate];
}

- (NSString *)title
{
    NSString *title = _assetCollection.localizedTitle;
    return title;
}

- (NSInteger)numberOfAssets
{
    NSUInteger number = self.fetchResult.count;
    if (NSNotFound == number) {
        return 0;
    }
    else {
        return number;
    }
}

- (UIImage *)posterImage
{
    if (!_hasGotPosterImage) {
        _hasGotPosterImage = YES;
        
        NSEnumerationOptions options = 0;
        if (PHAssetCollectionTypeSmartAlbum == self.asPHAssetCollection.assetCollectionType) {
            options = NSEnumerationReverse;
        }
        [self.fetchResult enumerateObjectsWithOptions:options usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            AMPhotoAsset *photoAsset = [AMPhotoAsset photoAssetWithPHAsset: obj];
            _posterImage = photoAsset.thumbnail;
            *stop = YES;
        }];
    }
    return _posterImage;
}

- (void)setAssetsFilter:(AMAssetsFilter *)assetsFilter
{
    if ([assetsFilter isEqual:_assetsFilter]) {
        return;
    }
    _assetsFilter = assetsFilter;
    _fetchResult = nil;

}

- (void)setNeedsUpdate
{
    _hasGotPosterImage = NO;
    _posterImage = nil;
    _fetchResult = nil;
}

- (void)changed:(id)afterChanges
{
    if ([afterChanges isKindOfClass:[PHAssetCollection class]]) {
        _assetCollection = afterChanges;
    }
    [self setNeedsUpdate];
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [self.fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (enumerationBlock) {
            AMPhotoAsset *photoAsset = [AMPhotoAsset photoAssetWithPHAsset: obj];
            enumerationBlock(photoAsset, idx, stop);
        }
    }];
    resultBlock(YES, nil);
}

@end
