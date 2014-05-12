//
//  AppDelegate.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 12..
//
//

#import "AppDelegate.h"
#import "PNGImageResourceInfo.h"



static const NSUInteger kThreadCount    = 4;



@interface AppDelegate ()

@property (weak) IBOutlet NSTextField *sourceRootPath;
@property (weak) IBOutlet NSTextField *imageResourcePath;

@property (nonatomic, strong)   NSMutableDictionary     *pngImageFilesDic;

@property (nonatomic, strong)   NSMutableDictionary     *x1OnlyFiles;
@property (nonatomic, strong)   NSMutableDictionary     *x2OnlyFiles;
@property (nonatomic, strong)   NSMutableDictionary     *allFiles;

@property (nonatomic, strong)   NSMutableArray          *threadList;

@property (nonatomic, strong)   NSMutableDictionary     *nouseImageFilesDic;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _pngImageFilesDic = [NSMutableDictionary dictionary];

    _x1OnlyFiles      = [NSMutableDictionary dictionary];
    _x2OnlyFiles      = [NSMutableDictionary dictionary];
    _allFiles         = [NSMutableDictionary dictionary];
    
    _threadList       = [NSMutableArray array];
    
    _nouseImageFilesDic = [NSMutableDictionary dictionary];
    
    
    [_sourceRootPath setStringValue:@"/Users/thomas/work/91.src/shcmobile"];
    [_imageResourcePath setStringValue:@"/Users/thomas/work/91.src/shcmobile/_Resource"];
}


- (IBAction)onGoButton:(id)sender
{
    NSLog(@"source path : %@", [_sourceRootPath stringValue]);
    NSLog(@"image path : %@", [_imageResourcePath stringValue]);
    
    
    [self listUpPNGImageResources:[_imageResourcePath stringValue]];

    NSLog(@"image file count : %ld", [_pngImageFilesDic count]);

    [self categorizePNGImageFileDictionary];
    
    
    [self checkWhetherPNGImageIsUsed];
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


- (void)categorizePNGImageFileDictionary
{
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
    
    
    //    NSLog(@"** 1x only files **\n%@", [_x1OnlyFiles allKeys]);
    //
    //
    //    NSLog(@"** 2x only files **\n%@", [_x2OnlyFiles allKeys]);
    //
    //
    //    NSLog(@"** all files **\n%@", [_allFiles allKeys]);
}


- (void)checkWhetherPNGImageIsUsed
{
    for (NSUInteger i = 0 ; i < kThreadCount ; i++)
    {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(performSearchPNGImageFileInSourceFiles:) object:@(i)];
        [thread start];
        [_threadList addObject:thread];
    }
    
//    [_pngImageFilesDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        NSString *imageFileName         = key;
//        
//        [self searchPNGImageFileInSourceFiles:imageFileName];
//    }];
}


- (void)performSearchPNGImageFileInSourceFiles:(NSNumber*)threadIdx
{
    NSInteger threadIndex = [threadIdx integerValue];
    
    NSLog(@"%s invoked , thread index : %ld", __func__, threadIndex);

    NSArray *allPNGImageNameList = [_pngImageFilesDic allKeys];
    NSUInteger fileCount = [allPNGImageNameList count];
    for (NSUInteger i = 0 ; i < fileCount ; i++)
    {
        if (threadIndex == i % kThreadCount)
        {
            [self searchPNGImageFileInSourceFiles:allPNGImageNameList[i]];
        }
    }
}


//- (void)searchPNGImageFileInSourceFiles:(NSNumber*)threadIdx
- (void)searchPNGImageFileInSourceFiles:(NSString*)imageFileName
{
    NSString *outputFilePath = [self prepareOutputFile];
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
    [outputFileHandle truncateFileAtOffset:0];

    
    
    NSTask *task = [[NSTask alloc] init];
    
    
    [task setLaunchPath:@"/usr/bin/grep"];
    [task setCurrentDirectoryPath:[_sourceRootPath stringValue]];
    [task setArguments:@[@"-rn", imageFileName, [_sourceRootPath stringValue]]];
    

    [task setStandardOutput:outputFileHandle];
    
    
    // Run the task
    [task launch];
    [task waitUntilExit];
    
    
    [outputFileHandle closeFile];

    
    NSTaskTerminationReason terminationReason = [task terminationReason];
    NSAssert(terminationReason == NSTaskTerminationReasonExit, @"terminationReason != NSTaskTerminationReasonExit");
    
    
    NSError *error = nil;
    NSString *searchResult = [NSString stringWithContentsOfFile:outputFilePath encoding:NSUTF8StringEncoding error:&error];
    NSAssert(searchResult != nil, @"failed to load output file\n%@", error);
    
    
    @synchronized(self)
    {
        printf("** %s **\n%s\n\n\n", [imageFileName UTF8String], [searchResult UTF8String]);
        
        if (![searchResult length])
        {
            _nouseImageFilesDic[imageFileName] = _pngImageFilesDic[imageFileName];
        }
    }
    
    
    [self deleteOutputFile:outputFilePath];
}


- (NSString*)prepareOutputFile
{
    NSString *outputFilePath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager createFileAtPath:outputFilePath contents:nil attributes:nil];
    
    
    NSAssert(result, @"%s failed to create file - %@", __func__, outputFilePath);
    
    
    return outputFilePath;
}


- (void)deleteOutputFile:(NSString*)outputFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL result = [fileManager removeItemAtPath:outputFilePath error:&error];

    NSAssert(result, @"%s failed to remove file - %@\n%@", __func__, outputFilePath, error);
}


@end

