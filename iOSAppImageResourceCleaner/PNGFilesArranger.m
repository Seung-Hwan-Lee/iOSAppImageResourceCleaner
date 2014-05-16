//
//  PNGFilesArranger.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 15..
//
//

#import "PNGFilesArranger.h"


@implementation PNGFilesArranger

- (id)init
{
    self = [super init];
    if (self)
    {
        self.pngFilesDic = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (void)listupPNGFiles:(NSString*)pngFilesRootPath
{
//    NSLog(@"%s invoked , %@", __func__, pngFilesRootPath);
    
    
    /// directory내 file들 list up.
    NSArray *fileList = [self fileList:pngFilesRootPath];
    if (![fileList count])
    {
        return ;
    }
    
    
    /// directory 내 file들에서 png 파일 찾아 처리.
    [fileList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *fileName = obj;
        NSString *filePath = [pngFilesRootPath stringByAppendingPathComponent:fileName];
        
        
        /// file attribute 추출.
        NSDictionary *fileAttributeDic = [self fileAttributes:filePath];
        
        
        NSString *fileType = fileAttributeDic[NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular])
        {
            NSString *fileExtension = [[fileName pathExtension] lowercaseString];
            
            
            /// png 파일인지 확인
            if ([fileExtension isEqualToString:@"png"])
            {
                /// png 파일 정보 저장.
                [self savePNGImageFileInfo:fileName filePath:filePath];
            }
        }
        else if ([fileType isEqualToString:NSFileTypeDirectory])
        {
            [self listupPNGFiles:filePath];
        }
    }];
}


- (void)makePNGArrangeReport:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    BOOL result = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    NSAssert(result, @"%s failed to create file - %@", __func__, filePath);
    
    
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [outputFileHandle truncateFileAtOffset:0];
    
    
    NSString *outputString = nil;
    
    
    outputString = @"PNG Image File Name | File Exist Type | Used Count | Is Reserved | 1x File Path | 2x File Path\n";
    [outputFileHandle writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSArray *imageFileList = [self.pngFilesDic allKeys];
    imageFileList = [imageFileList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    
    for (NSString *fileName in imageFileList)
    {
        PNGImageResourceInfo *imageInfo = self.pngFilesDic[fileName];
        
        outputString = [NSString stringWithFormat:@"%@ | %@ | %lu | %@ | %@ | %@\n",
                        fileName,
                        [imageInfo fileExistTypeString],
                        imageInfo.usedCount,
                        (imageInfo.reservedImage)?@"reserved":@"",
                        imageInfo.x1FilePath,
                        imageInfo.x2FilePath];
        [outputFileHandle writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [outputFileHandle closeFile];
}


- (NSArray*)fileList:(NSString*)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (nil == fileList)
    {
        NSAssert(NO, @"failed contentsOfDirectoryAtPath:error:\nimage file path : %@\nerror : %@", path, error);
    }
    
    return fileList;
}


- (NSDictionary*)fileAttributes:(NSString*)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:path error:&error];
    if (nil == fileAttributeDic)
    {
        NSAssert(NO, @"failed attributesOfItemAtPath:error:\nimage file path : %@\nerror : %@", path, error);
    }
    
    return fileAttributeDic;
}


- (void)savePNGImageFileInfo:(NSString*)fileName filePath:(NSString*)filePath
{
    /// 파일 확장자 제거.
    fileName = [fileName substringToIndex:[fileName length] - 4];
    
    
    
    BOOL is2xFile          = NO;
    NSString *fileNameTail = nil;
    
    
    /// Retina용 파일인지 확인.
    if ([fileName length] > 3)
    {
        /// Retina용 파일인지 확인.
        fileNameTail = [[fileName substringFromIndex:[fileName length] - 3] lowercaseString];
        if ([fileNameTail isEqualToString:@"@2x"])
        {
            /// Retina용 파일이면 file name에서 @2x 빼고, Retina 용이라는 flag를 YES로.
            fileName = [fileName substringToIndex:[fileName length] - 3];
            is2xFile = YES;
        }
    }
    
    
    
    PNGImageResourceInfo *imageInfo = _pngFilesDic[fileName];
    if (nil == imageInfo)
    {
        imageInfo = [[PNGImageResourceInfo alloc] init];
        _pngFilesDic[fileName] = imageInfo;
    }
    
    
    if (is2xFile)
    {
        imageInfo.x2FilePath = filePath;
    }
    else
    {
        imageInfo.x1FilePath = filePath;
    }
}


@end
