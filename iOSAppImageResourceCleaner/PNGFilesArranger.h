//
//  PNGFilesArranger.h
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 15..
//
//

#import <Foundation/Foundation.h>
#import "PNGImageResourceInfo.h"


@interface PNGFilesArranger : NSObject

@property (nonatomic, strong)   NSMutableDictionary     *pngFilesDic;

- (void)listupPNGFiles:(NSString*)pngFilesRootPath;

- (void)makePNGArrangeReport:(NSString*)filePath;

@end
