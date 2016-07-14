//
//  AMPhotoChange.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoChange_Private.h"

#pragma mark - AMPhotoChange

@implementation AMPhotoChange {
    @private
    PHChange *_changeInstance;
}


+ (instancetype)changeWithPHChange:(PHChange *)changeInstance
{
    return [[AMPhotoChange alloc] initWithPHChange:changeInstance];
}

- (instancetype)initWithPHChange:(PHChange *)changeInstance
{
    self = [super init];
    if (self) {
        _changeInstance = changeInstance;
        _isAlbumCreated = NO;
        _isAlbumDeleted = NO;
    }
    return self;
}

- (void)setAlbumCreated:(BOOL)created
{
    _isAlbumCreated = created;
}

- (void)setAlbumDeleted:(BOOL)deleted
{
    _isAlbumDeleted = deleted;
}

- (AMPhotoChangeDetails *)changeDetailsForObject:(id)object
{
    AMPhotoChangeDetails *changeDetails = nil;
    if ([object isKindOfClass:[AMPhotoAsset class]]) {
        AMPhotoAsset *asset = (AMPhotoAsset *)object;
        changeDetails = [AMPhotoChangeDetails changeDetailsWithPHObjectChangeDetails:[_changeInstance changeDetailsForObject:[asset asPHAsset]] PHFetchResultChangeDetails:nil];
    }
    else if ([object isKindOfClass:[AMPhotoAlbum class]]) {
        AMPhotoAlbum *album = (AMPhotoAlbum *)object;
        changeDetails = [AMPhotoChangeDetails changeDetailsWithPHObjectChangeDetails:[_changeInstance changeDetailsForObject:[album asPHAssetCollection]] PHFetchResultChangeDetails:[_changeInstance changeDetailsForFetchResult:album.fetchResult]];
    }
    return changeDetails;
}

@end


#pragma mark - AMPhotoChangeDetails

@implementation AMPhotoChangeDetails {
    @private
    PHObjectChangeDetails *_changeDetails;
    PHFetchResultChangeDetails *_resultChangeDetails;
}


+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)resultChangeDetails
{
    if ((nil == changeDetails) && (nil == resultChangeDetails)) {
        return nil;
    }
    return [[[self class] alloc] initWithPHObjectChangeDetails: changeDetails PHFetchResultChangeDetails:resultChangeDetails];
}

- (instancetype)initWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)resultChangeDetails
{
    self = [super init];
    if (self) {
        _changeDetails = changeDetails;
        _resultChangeDetails = resultChangeDetails;
    }
    return self;
}


- (id)objectBeforeChanges
{
    if (nil != _changeDetails) {
        return _changeDetails.objectBeforeChanges;
    }
    else {
        return nil;
    }
}

- (id)objectAfterChanges
{
    if (nil != _changeDetails) {
        return _changeDetails.objectAfterChanges;
    }
    else {
        return nil;
    }
}

- (BOOL)objectWasChanged
{
    __block BOOL wasChanged = NO;
    if (nil != _changeDetails) {
        //For asset
        wasChanged = _changeDetails.assetContentChanged;
        //For collection property changed
        wasChanged |= (_changeDetails.objectBeforeChanges != _changeDetails.objectAfterChanges);
    }
    if (nil != _resultChangeDetails) {
        //For assets in collection changed
        wasChanged |= _resultChangeDetails.fetchResultBeforeChanges.count != _resultChangeDetails.fetchResultAfterChanges.count;
    }
    return wasChanged;
}

- (BOOL)objectWasDeleted
{
    __block BOOL wasDeleted = NO;
    if (nil != _changeDetails) {
        wasDeleted = _changeDetails.objectWasDeleted;
    }
    return wasDeleted;
}

@end
