//
//  PNGImageResourceInfo.h
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 12..
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FileExistType)
{
    X1ImageOnlyExist,
    X2ImageOnlyExist,
    AllImageExist,
    FileExistTypeFault
};

@interface PNGImageResourceInfo : NSObject

@property (nonatomic, strong)   NSString    *x1FilePath;
@property (nonatomic, strong)   NSString    *x2FilePath;
@property (nonatomic, assign)   NSUInteger  usedCount;      /// source에서 해당 이미지가 사용된 횟수.
@property (nonatomic, assign)   BOOL        reservedImage;

- (FileExistType)fileExistType;

- (NSString*)fileExistTypeString;

@end


