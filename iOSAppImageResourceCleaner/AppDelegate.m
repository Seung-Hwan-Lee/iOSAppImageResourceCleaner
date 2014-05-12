//
//  AppDelegate.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 12..
//
//

#import "AppDelegate.h"
#import "PNGImageResourceInfo.h"





@interface AppDelegate ()

@property (weak) IBOutlet NSTextField *sourceRootPath;
@property (weak) IBOutlet NSTextField *imageResourcePath;

@property (nonatomic, strong)   NSMutableDictionary     *pngImageFilesDic;

@property (nonatomic, strong)   NSMutableDictionary     *x1OnlyFiles;
@property (nonatomic, strong)   NSMutableDictionary     *x2OnlyFiles;
@property (nonatomic, strong)   NSMutableDictionary     *allFiles;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _pngImageFilesDic = [NSMutableDictionary dictionary];

    _x1OnlyFiles      = [NSMutableDictionary dictionary];
    _x2OnlyFiles      = [NSMutableDictionary dictionary];
    _allFiles         = [NSMutableDictionary dictionary];
}


- (IBAction)onGoButton:(id)sender
{
    NSLog(@"source path : %@", [_sourceRootPath stringValue]);
    NSLog(@"image path : %@", [_imageResourcePath stringValue]);
    
    
    [self listUpPNGImageResources:[_imageResourcePath stringValue]];

//    NSLog(@"%@", _pngImageFilesDic);
    
    [_pngImageFilesDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *imageFileName         = key;
        PNGImageResourceInfo *imageInfo = obj;
        
        FileExistType fileExistType = [imageInfo fileExistType];
        switch (fileExistType) {
            case X1ImageOnlyExist:
                _x1OnlyFiles[imageFileName] = imageInfo;
                break;
                
            case X2ImageOnlyExist:
                _x2OnlyFiles[imageFileName] = imageInfo;
                break;
                
            case AllImageExist:
                _allFiles[imageFileName] = imageInfo;
                break;
                
            default:
                NSAssert(NO, @"");
                break;
        }
    }];
    
    
    NSLog(@"** 1x only files **\n%@", [_x1OnlyFiles allKeys]);
    
    
    NSLog(@"** 2x only files **\n%@", [_x2OnlyFiles allKeys]);
    
    
    NSLog(@"** all files **\n%@", [_allFiles allKeys]);
}


- (void)listUpPNGImageResources:(NSString*)imageFilesDirectoryPath
{
    NSLog(@"%s invoked , %@", __func__, imageFilesDirectoryPath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:imageFilesDirectoryPath error:&error];
    if (nil == directoryContents)
    {
        NSLog(@"failed contentsOfDirectoryAtPath:error:\nimage file path : %@\nerror : %@", imageFilesDirectoryPath, error);
        return ;
    }
    
    
    [directoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *fileName = obj;
        NSString *filePath = [imageFilesDirectoryPath stringByAppendingPathComponent:fileName];
        
        
        NSError *error = nil;
        NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (nil == fileAttributeDic)
        {
            NSLog(@"failed attributesOfItemAtPath:error:\nimage file path : %@\nerror : %@", filePath, error);
            return ;
        }
        
        
        NSString *fileType = fileAttributeDic[NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular])
        {
            NSString *fileExtension = [[fileName pathExtension] lowercaseString];
            if ([fileExtension isEqualToString:@"png"])
            {
                fileName = [fileName substringToIndex:[fileName length] - 4];
                
                BOOL is2xFile = NO;
                NSString *fileNameTail = nil;
                
                if ([fileName length] > 3)
                {
                    fileNameTail = [[fileName substringFromIndex:[fileName length] - 3] lowercaseString];
                }
                
                if ([fileNameTail isEqualToString:@"@2x"])
                {
                    fileName = [fileName substringToIndex:[fileName length] - 3];
                    is2xFile = YES;
                }

                [self savePNGImageFileInfo:fileName filePath:filePath is2xFile:is2xFile];
            }
        }
        else if ([fileType isEqualToString:NSFileTypeDirectory])
        {
            [self listUpPNGImageResources:filePath];
        }
//        NSLog(@"%@", fileAttributeDic);
    }];
    
//    NSLog(@"%@", directoryContents);
    
}


- (void)savePNGImageFileInfo:(NSString*)fileName filePath:(NSString*)filePath is2xFile:(BOOL)is2xFile
{
    PNGImageResourceInfo *imageInfo = _pngImageFilesDic[fileName];
    if (nil == imageInfo)
    {
        imageInfo = [[PNGImageResourceInfo alloc] init];
        _pngImageFilesDic[fileName] = imageInfo;
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
