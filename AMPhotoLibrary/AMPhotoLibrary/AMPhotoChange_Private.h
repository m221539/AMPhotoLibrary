//
//  AMPhotoChange_Private.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoChange.h"


#pragma mark - AMPhotoChange

@interface AMPhotoChange (Private)

+ (instancetype)changeWithPHChange:(PHChange *)changeInstance;

- (void)setAlbumCreated:(BOOL)created;
- (void)setAlbumDeleted:(BOOL)deleted;

@end


#pragma mark - AMPhotoChangeDetails

@interface AMPhotoChangeDetails (Private)

+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails;

@end
