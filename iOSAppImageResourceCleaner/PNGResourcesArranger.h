//
//  PNGResourcesArranger.h
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 15..
//
//

#import "PNGFilesArranger.h"


@protocol PNGResourcesArrangerDelegate <NSObject>

- (void)PNGResourcesArrangerDidSearchPNGImage:(NSUInteger)currentProcessCount totalPNGImageCount:(NSUInteger)totalCount;
- (void)PNGResourcesArrangerDidStartSearch;
- (void)PNGResourcesArrangerDidEndSearch;

@end


@interface PNGResourcesArranger : PNGFilesArranger


- (id)initWithDelegate:(id<PNGResourcesArrangerDelegate>)delegate searchResultSaveDirectory:(NSString*)searchResultSaveDirectory reportSaveDirectory:(NSString*)reportSaveDirectory;


- (void)checkWhetherImageIsUsed:(PNGFilesArranger*)reservedImagesInfo inSourceRootDirectory:(NSString*)sourceRootDirectoryPath;


@end
