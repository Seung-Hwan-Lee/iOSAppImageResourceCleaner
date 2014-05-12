//
//  PNGImageResourceInfo.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 12..
//
//

#import "PNGImageResourceInfo.h"

@implementation PNGImageResourceInfo

- (NSString*)description
{
    NSString *description = @"";
    
    FileExistType fileExistType = [self fileExistType];
    switch (fileExistType) {
        case X1ImageOnlyExist:
            description = @"1x only";
            break;
            
        case X2ImageOnlyExist:
            description = @"2x only";
            break;
            
        case AllImageExist:
            description = @"1x & 2x all exist";
            break;
            
        default:
            NSAssert(NO, @"");
            break;
    }
    
    
    return description;
}


- (FileExistType)fileExistType
{
    if ([_x1FilePath length] && [_x2FilePath length])
    {
        return AllImageExist;
    }
    
    if ([_x1FilePath length])
    {
        return X1ImageOnlyExist;
    }
    
    if ([_x2FilePath length])
    {
        return X2ImageOnlyExist;
    }
    
    return FileExistTypeFault;
}


@end
