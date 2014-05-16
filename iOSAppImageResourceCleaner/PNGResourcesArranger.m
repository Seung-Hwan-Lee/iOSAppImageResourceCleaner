//
//  PNGResourcesArranger.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 15..
//
//

#import "PNGResourcesArranger.h"
#import "PNGImageResourceInfo.h"


static const NSUInteger kThreadCount          = 4;
//static const NSUInteger kThreadCount          = 1;


@interface PNGResourcesArranger ()

@property (nonatomic, weak)     id<PNGResourcesArrangerDelegate>    delegate;


@property (atomic, copy)        NSString                            *workingDirectory;
@property (atomic, copy)        NSString                            *searchResultSaveDirectory;
@property (atomic, copy)        NSString                            *reportSaveDirectory;


@property (atomic, strong)      PNGFilesArranger                    *reservedImagesInfo;

@property (atomic, assign)      NSUInteger                          processedFileCount;    /// 처리된 PNG 파일 수.

@property (nonatomic, strong)   NSMutableArray                      *threadList;           /// grep 처리하는 Thread들

@end


@implementation PNGResourcesArranger


- (id)initWithDelegate:(id<PNGResourcesArrangerDelegate>)delegate searchResultSaveDirectory:(NSString*)searchResultSaveDirectory reportSaveDirectory:(NSString*)reportSaveDirectory
{
    self = [super init];
    if (self)
    {
        self.delegate                  = delegate;

        self.searchResultSaveDirectory = searchResultSaveDirectory;
        self.reportSaveDirectory       = reportSaveDirectory;
    }
    
    return self;
}


- (void)checkWhetherImageIsUsed:(PNGFilesArranger*)reservedImagesInfo inSourceRootDirectory:(NSString*)sourceRootDirectoryPath
{
    self.workingDirectory   = sourceRootDirectoryPath;
    self.reservedImagesInfo = reservedImagesInfo;
    
    
    [self performSelectorInBackground:@selector(searchPNGFilesInSources) withObject:nil];
}


- (void)searchPNGFilesInSources
{
    _processedFileCount = 0;
    
    
    [_delegate PNGResourcesArrangerDidSearchPNGImage:0 totalPNGImageCount:[self.pngFilesDic count]];
    [_delegate PNGResourcesArrangerDidStartSearch];
    
    _threadList = [NSMutableArray array];
    for (NSUInteger i = 0 ; i < kThreadCount ; i++)
    {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(searchPNGFilesInSources:) object:@(i)];
        [thread start];
        [_threadList addObject:thread];
    }
    
    
    [self waitAllThreadsFinish];
    
    
    NSString *filePath = [NSString stringWithFormat:@"%@/ResourcePNGFilesUsageReport.csv", self.reportSaveDirectory];
    [self makePNGArrangeReport:filePath];
    //    NSLog(@"** no use image files ** \n%@", _nouseImageFilesDic);
    
    
    [_delegate PNGResourcesArrangerDidEndSearch];
}


- (void)waitAllThreadsFinish
{
    while (YES)
    {
        __block NSUInteger finishedThreadCount = 0;
        [_threadList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSThread *thread = obj;
            if ([thread isFinished])
            {
                finishedThreadCount++;
            }
        }];
        
        if (finishedThreadCount >= kThreadCount)
        {
            break;
        }
    }
}


- (void)searchPNGFilesInSources:(NSNumber*)threadIdx
{
    NSInteger threadIndex = [threadIdx integerValue];
    
    
    NSLog(@"%s invoked , thread index : %ld", __func__, threadIndex);
    
    
    NSString *outputFilePath  = [self prepareTemporaryFileForThread];

    
    NSArray *allPNGImageNameList = [self.pngFilesDic allKeys];
    NSUInteger fileCount = [allPNGImageNameList count];
    for (NSUInteger i = 0 ; i < fileCount ; i++)
    {
        if (threadIndex == i % kThreadCount)
        {
            [self searchPNGFileInSourceFile:allPNGImageNameList[i] outputFilePath:outputFilePath];
        }
    }
    
    
    [self deleteFile:outputFilePath];
}


- (void)searchPNGFileInSourceFile:(NSString*)imageFileName outputFilePath:(NSString*)outputFilePath
{
    NSLog(@"%@", imageFileName);
    
    
    /// Default.png 파일은 찾지 않음.
    if ([imageFileName isEqualTo:@"Default"])
    {
        @synchronized(self)
        {
            self.processedFileCount++;
        }
        [_delegate PNGResourcesArrangerDidSearchPNGImage:self.processedFileCount totalPNGImageCount:[self.pngFilesDic count]];
        return ;
    }
    
    
    /// grep 결과를 저장할 file 준비.
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
    [outputFileHandle truncateFileAtOffset:0];
    
    
    /// grep을 실행시키는데 사용할 NSTask 준비.
    NSTask *task = [[NSTask alloc] init];
    
    
    /// configure task
    [task setLaunchPath:@"/usr/bin/grep"];
    [task setCurrentDirectoryPath:_workingDirectory];
    [task setArguments:@[@"-rn", imageFileName, _workingDirectory]];
    [task setStandardOutput:outputFileHandle];
    
    
    /// Run the task
    [task launch];
    

//    NSLog(@"%s launch task!", __func__);
    
    
    [task waitUntilExit];
    
    
//    NSLog(@"%s task was finished!", __func__);

    
    /// close - output file handle
    [outputFileHandle closeFile];
    
    
    
    /// check task termination
    NSTaskTerminationReason terminationReason = [task terminationReason];
    NSAssert(terminationReason == NSTaskTerminationReasonExit, @"terminationReason != NSTaskTerminationReasonExit");
    
    
    
    /// load search result
    NSError *error = nil;
    NSString *searchResult = [NSString stringWithContentsOfFile:outputFilePath encoding:NSUTF8StringEncoding error:&error];
    NSAssert(searchResult != nil, @"failed to load output file\n%@", error);
    
    

    if ([searchResult length])
    {
        /// count found file
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:searchResult
                                                            options:0
                                                              range:NSMakeRange(0, [searchResult length])];

        PNGImageResourceInfo *info = self.pngFilesDic[imageFileName];
        info.usedCount = numberOfMatches;

        
        NSLog(@"USE - %lu", numberOfMatches);

        
        if (self.reservedImagesInfo.pngFilesDic[imageFileName])
        {
            info.reservedImage = YES;
        }
        else
        {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@.txt", self.searchResultSaveDirectory, imageFileName];
            if (![searchResult writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error])
            {
                NSAssert(NO, @"failed to write file : %@\n%@", filePath, error);
            }
        }
    }
    else
    {
        NSLog(@"NO USE!");
        
        if (self.reservedImagesInfo.pngFilesDic[imageFileName])
        {
            PNGImageResourceInfo *info = self.pngFilesDic[imageFileName];
            info.reservedImage = YES;
        }
    }

    
    @synchronized(self)
    {
        self.processedFileCount++;
    }
    [_delegate PNGResourcesArrangerDidSearchPNGImage:self.processedFileCount totalPNGImageCount:[self.pngFilesDic count]];
}


#pragma mark - Utility Methods


- (NSString*)prepareTemporaryFileForThread
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%p", self.searchResultSaveDirectory, [NSThread currentThread]];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    
    
    NSAssert(result, @"%s failed to create file - %@", __func__, filePath);
    
    
    return filePath;
}


- (void)deleteFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    BOOL result = [fileManager removeItemAtPath:filePath error:&error];
    
    NSAssert(result, @"%s failed to remove file - %@\n%@", __func__, filePath, error);
}


@end
