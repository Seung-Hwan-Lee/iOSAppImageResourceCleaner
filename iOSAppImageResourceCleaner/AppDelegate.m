//
//  AppDelegate.m
//  iOSAppImageResourceCleaner
//
//  Created by 이승환 on 2014. 5. 12..
//
//

#import "AppDelegate.h"
#import "PNGFilesArranger.h"
#import "PNGResourcesArranger.h"






@interface AppDelegate () <PNGResourcesArrangerDelegate>

@property (weak) IBOutlet       NSTextField             *sourceRootPath;
@property (weak) IBOutlet       NSTextField             *imageResourcePath;
@property (weak) IBOutlet       NSTextField             *refImageFilesPath;
@property (weak) IBOutlet       NSTextField             *progressCountTextField;

@property (weak) IBOutlet       NSProgressIndicator     *progressIndicator;
@property (weak) IBOutlet       NSButton                *okButton;


@property (nonatomic, strong)   NSString                *searchResultDirectory;
@property (nonatomic, strong)   NSString                *arrangeReportDirectory;


@property (nonatomic, strong)   PNGFilesArranger        *reservedImagesArranger;
@property (nonatomic, strong)   PNGResourcesArranger    *pngResourcesArranger;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    
    /// user / thomas / iOSCleaner / searchResult
    /// user / thomas / iOSCleaner / arrangeReport
    
    
    /// remove directory iOSCleaner
    NSString *appDataDirectory = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), [self applicationName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    
    NSLog(@"app data directory : %@", appDataDirectory);
    
    
    if (![fileManager removeItemAtPath:appDataDirectory error:&error])
    {
        NSAssert((error.code == NSFileNoSuchFileError), @"failed remove directory - %@\n%@", appDataDirectory, error);
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self makeAppDataDirectory:appDataDirectory];
    });

    
    
    [self prepareDefaultInputValues];
}


#pragma mark - Prepare Methods


/**
 input text field에 기본값 입력.
 */
- (void)prepareDefaultInputValues
{
    [_sourceRootPath setStringValue:@"/Users/thomas/work/91.src/shcmobile"];
    [_imageResourcePath setStringValue:@"/Users/thomas/work/91.src/shcmobile/_Resource"];
    [_refImageFilesPath setStringValue:@"/Users/thomas/work/82.GUI/backup"];
}


#pragma mark - Action Methods
- (IBAction)checkReferenceImageFiles:(id)sender
{
    [self resetInstanceVariables];
    
    
    [self arrangeReservedPNGImages];
    
    
    NSString *filePath = [NSString stringWithFormat:@"%@/ReservedPNGFilesReport.csv", _arrangeReportDirectory];
    [_reservedImagesArranger makePNGArrangeReport:filePath];
}


- (IBAction)checkResourceImageFiles:(id)sender
{
    [self resetInstanceVariables];
    
    
    [self arrangePNGImageResources];
    
    
    NSString *filePath = [NSString stringWithFormat:@"%@/ResourcePNGFilesReport.csv", _arrangeReportDirectory];
    [_pngResourcesArranger makePNGArrangeReport:filePath];
}


- (IBAction)onGoButton:(id)sender
{
    [self resetInstanceVariables];

    
    NSLog(@"source path : %@", [_sourceRootPath stringValue]);
    NSLog(@"image path  : %@", [_imageResourcePath stringValue]);
    NSLog(@"ref path    : %@", [_refImageFilesPath stringValue]);
    

    [self arrangeReservedPNGImages];


    [self arrangePNGImageResources];

    
    [_pngResourcesArranger checkWhetherImageIsUsed:_reservedImagesArranger inSourceRootDirectory:[_sourceRootPath stringValue]];
}


#pragma mark - Process Methods


- (void)arrangeReservedPNGImages
{
    NSLog(@"reserved image path  : %@", [_refImageFilesPath stringValue]);
    
    
    
    self.reservedImagesArranger = [[PNGFilesArranger alloc] init];
    [_reservedImagesArranger listupPNGFiles:[_refImageFilesPath stringValue]];
    
    
    NSLog(@"reserved image count : %ld", [_reservedImagesArranger.pngFilesDic count]);
}


- (void)arrangePNGImageResources
{
    NSLog(@"resource image path  : %@", [_imageResourcePath stringValue]);
    
    
    self.pngResourcesArranger = [[PNGResourcesArranger alloc] initWithDelegate:self
                                                     searchResultSaveDirectory:_searchResultDirectory
                                                           reportSaveDirectory:_arrangeReportDirectory];
    [_pngResourcesArranger listupPNGFiles:[_imageResourcePath stringValue]];
    
    
    NSLog(@"resource image count : %ld", [_pngResourcesArranger.pngFilesDic count]);
}


#pragma mark - Reset Methods


/**
 인스턴스 변수 reset.
 */
- (void)resetInstanceVariables
{
}


#pragma mark - PNGResourcesArrangerDelegate Methods


- (void)PNGResourcesArrangerDidSearchPNGImage:(NSUInteger)currentProcessCount totalPNGImageCount:(NSUInteger)totalCount
{
    [self showSearchProcess:currentProcessCount totalPNGImageCount:totalCount];
}


- (void)PNGResourcesArrangerDidStartSearch
{
    [self setControlEnabled:NO];
}


- (void)PNGResourcesArrangerDidEndSearch
{
    [self setControlEnabled:YES];
}


#pragma mark - UI Methods


- (void)showSearchProcess:(NSUInteger)processedFileNum totalPNGImageCount:(NSUInteger)totalCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *string = [NSString stringWithFormat:@"%lu / %lu", processedFileNum, totalCount];
        [_progressCountTextField setStringValue:string];
    });
}


- (void)setControlEnabled:(BOOL)enabled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (enabled)
        {
            [_progressIndicator stopAnimation:nil];
        }
        else
        {
            [_progressIndicator startAnimation:nil];
        }
        
        [_okButton setEnabled:enabled];
    });
}


#pragma mark - Utility Methods


- (void)makeAppDataDirectory:(NSString*)appDataDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    
    /// create directory searchResult
    {
        self.searchResultDirectory = [NSString stringWithFormat:@"%@/searchResult", appDataDirectory];
        if (![fileManager createDirectoryAtPath:_searchResultDirectory withIntermediateDirectories:YES attributes:nil error:&error])
        {
            if (error.code != NSFileWriteFileExistsError)
            {
                NSAssert(NO, @"failed create directory - %@\n%@", _searchResultDirectory, error);
            }
        }
    }
    
    
    /// create directory arrangeReport
    {
        self.arrangeReportDirectory = [NSString stringWithFormat:@"%@/arrangeReport", appDataDirectory];
        if (![fileManager createDirectoryAtPath:_arrangeReportDirectory withIntermediateDirectories:YES attributes:nil error:&error])
        {
            if (error.code != NSFileWriteFileExistsError)
            {
                NSAssert(NO, @"failed create directory - %@\n%@", _arrangeReportDirectory, error);
            }
        }
    }
}


- (NSString*)applicationName
{
    NSBundle *bundle          = [NSBundle mainBundle];
    NSDictionary *info        = [bundle infoDictionary];
    NSString *applicationName = [info objectForKey:@"CFBundleName"];
    
    return applicationName;
}


@end

