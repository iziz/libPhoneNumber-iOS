//
//  NBPhoneMetaClassGenerator.m
//  libPhoneNumber
//
//

#import "NBPhoneMetaClassGenerator.h"
#import "NBPhoneMetaData.h"



@implementation NBPhoneMetaClassGenerator


- (id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}


- (void)generateMetaClasses
{
    NSDictionary *realMetadata = nil, *testMetadata = nil;
    realMetadata = [self generateMetaData];
    testMetadata = [self generateMetaDataWithTest];
    
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"src"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            NSError* error;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                NSLog(@"[%@] ERROR: attempting to write create MyFolder directory", [self class]);
            }
        }
        
        NSDictionary *mappedRealData = [self mappingObject:realMetadata];
        NSDictionary *mappedTestData = [self mappingObject:testMetadata];
        
        [self createClassWithDictionary:mappedRealData name:@"NBPhoneNumberMetadata"];
        [self createClassWithDictionary:mappedTestData name:@"NBPhoneNumberMetadataForTesting"];
    } @catch (NSException *exception) {
        NSLog(@"Error for creating metadata classes : %@", exception.reason);
    }
}


- (void)createClassWithDictionary:(NSDictionary *)data name:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"src"];
    
    NSString *filePathData = [NSString stringWithFormat:@"%@/%@.plist", dataPath, name];
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:data];
    [objData writeToFile:filePathData atomically:YES];
    
    /*
    NSString *codeStringHeader = [self generateSourceCodeWith:data name:name type:0];
    NSString *codeStringSource = [self generateSourceCodeWith:data name:name type:1];
    
    NSData *dataToWrite = [codeStringHeader dataUsingEncoding:NSUTF8StringEncoding];
    [fileManager createFileAtPath:filePathHeader contents:dataToWrite attributes:nil];
    
    dataToWrite = [codeStringSource dataUsingEncoding:NSUTF8StringEncoding];
    [fileManager createFileAtPath:filePathSource contents:dataToWrite attributes:nil];
    */
    
    NSData *fileData = [NSData dataWithContentsOfFile:filePathData];
    NSDictionary *unarchiveData = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
    
    NSLog(@"Created file to...[%@ / %zu]", filePathData, (unsigned long)[unarchiveData count]);
}


- (NSDictionary *)mappingObject:(NSDictionary *)parsedJSONData
{
    NSMutableDictionary *resMedata = [[NSMutableDictionary alloc] init];
    NSDictionary *countryCodeToRegionCodeMap = [parsedJSONData objectForKey:@"countryCodeToRegionCodeMap"];
    NSDictionary *countryToMetadata = [parsedJSONData objectForKey:@"countryToMetadata"];
    NSLog(@"- countryCodeToRegionCodeMap count [%zu]", (unsigned long)[countryCodeToRegionCodeMap count]);
    NSLog(@"- countryToMetadata          count [%zu]", (unsigned long)[countryToMetadata count]);
    
    NSMutableDictionary *genetatedMetaData = [[NSMutableDictionary alloc] init];
    
    for (id key in [countryToMetadata allKeys])
    {
        id metaData = [countryToMetadata objectForKey:key];
        
        NBPhoneMetaData *newMetaData = [[NBPhoneMetaData alloc] init];
        [newMetaData buildData:metaData];
        
        [genetatedMetaData setObject:newMetaData forKey:key];
    }
    
    [resMedata setObject:countryCodeToRegionCodeMap forKey:@"countryCodeToRegionCodeMap"];
    [resMedata setObject:genetatedMetaData forKey:@"countryToMetadata"];
    
    return resMedata;
}


- (NSString *)documentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}


- (NSDictionary *)generateMetaData
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneNumberMetaData" ofType:@"json"];
    return [self parseJSON:filePath];
}


- (NSDictionary *)generateMetaDataWithTest
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneNumberMetaDataForTesting" ofType:@"json"];
    return [self parseJSON:filePath];
}


- (NSDictionary *)parseJSON:(NSString *)filePath
{
    NSDictionary *jsonRes = nil;
    
    @try {
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
        NSError *error = nil;
        jsonRes = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@", exception.reason);
    }
    
    return jsonRes;
}


/*
- (NSString *)generateSourceCodeWith:(NSDictionary*)data name:(NSString*)name type:(int)type
{
    NSString *srcCode = @"";
    
    if (type == 0)
    {
        NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", curDir, @"resources/PhoneNumberTemplateClass.h"];
        NSString *stringContent =  [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        // header code
        srcCode = [NSString stringWithFormat:stringContent, name, name];
    }
    else if (type == 1)
    {
        NSMutableString *srcImplement = [[NSMutableString alloc] initWithString:@""];
        
        NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", curDir, @"resources/PhoneNumberTemplateClass.m"];
        NSString *stringContent =  [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        // source code
        NSString *instanceName = @"";
        [srcImplement appendString:[self encodeNSDictionary:data indent:0 createdInstanceName:&instanceName]];
        
        srcCode = [NSString stringWithFormat:stringContent, name, name, name, srcImplement, instanceName];
    }
    
    return srcCode;
}

 
- (NSString*)encodeNSDictionary:(NSDictionary*)object indent:(int)depth createdInstanceName:(NSString**)instanceName
{
    NSMutableString *curImplement = [[NSMutableString alloc] initWithString:@""];
    NSEnumerator *enumerator = [object keyEnumerator];
    id curKey = nil;
    
    NSString *tempInstanceName = [NSString stringWithFormat:@"%@_%@_%d", [self genRandStringLength:16], @"NSDictionary", depth];
    
    if (instanceName != NULL && (*instanceName) != nil)
        (*instanceName) = [tempInstanceName copy];
    
    NSString *createInstancFromat = @"%@NSMutableDictionary *%@ = [[NSMutableDictionary alloc] init];\n";
    
    NSString *currentSyntaxFormat = nil;
    NSString *buildedSyntax = nil;
    
    [curImplement appendFormat:createInstancFromat, [self indentTab:depth], tempInstanceName];
    
    while ((curKey = [enumerator nextObject]))
    {
        id curObject = [object objectForKey:curKey];
        currentSyntaxFormat = @"%@[%@ setObject:%@ forKey:@\"%@\"];\n";
        
        if ([curObject isKindOfClass:[NSString class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSString:curObject], curKey];
        }
        else if ([curObject isKindOfClass:[NSArray class]])
        {
            [curImplement appendFormat:@"%@{\n", [self indentTab:depth]];
            NSString *tempArrayInstanceName = @"";
            buildedSyntax = [self encodeNSArray:curObject indent:depth+1 createdInstanceName:&tempArrayInstanceName];
            [curImplement appendString:buildedSyntax];
            [curImplement appendString:[NSString stringWithFormat:currentSyntaxFormat, [self indentTab:depth + 1], tempInstanceName, tempArrayInstanceName, curKey]];
            [curImplement appendFormat:@"%@}\n", [self indentTab:depth]];
        }
        else if ([curObject isKindOfClass:[NSDictionary class]])
        {
            [curImplement appendFormat:@"%@{\n", [self indentTab:depth]];
            NSString *tempDictionaryInstanceName = @"";
            buildedSyntax = [self encodeNSDictionary:curObject indent:depth+1 createdInstanceName:&tempDictionaryInstanceName];
            [curImplement appendString:buildedSyntax];
            [curImplement appendString:[NSString stringWithFormat:currentSyntaxFormat, [self indentTab:depth + 1], tempInstanceName, tempDictionaryInstanceName, curKey]];
            [curImplement appendFormat:@"%@}\n", [self indentTab:depth]];
        }
        else if ([curObject isKindOfClass:[NSNumber class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSNumber:curObject], curKey];
        }
        else if ([curObject isKindOfClass:[NSNull class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSNull:curObject], curKey];
        }
        else
        {
            NSString *warningString = [NSString stringWithFormat:@"#warning cant parse data %@ key %@", curObject, curKey];
            [curImplement appendString:warningString];
            NSLog(@"!!! ERROR !!! - %@", warningString);
        }
    }
    
    return curImplement;
}


- (NSString*)encodeNSArray:(NSArray*)object indent:(int)depth createdInstanceName:(NSString**)instanceName
{
    NSMutableString *curImplement = [[NSMutableString alloc] initWithString:@""];
    NSString *tempInstanceName = [NSString stringWithFormat:@"%@_%@_%d", [self genRandStringLength:16], @"NSArray", depth];
    
    if (instanceName != NULL && (*instanceName) != nil)
        (*instanceName) = [tempInstanceName copy];
        
    NSString *createInstancFromat = @"%@NSMutableArray *%@ = [[NSMutableArray alloc] init];\n";
    
    NSString *currentSyntaxFormat = nil;
    NSString *buildedSyntax = nil;
    
    [curImplement appendFormat:createInstancFromat, [self indentTab:depth], tempInstanceName];
    
    for (id data in object)
    {
        currentSyntaxFormat = @"%@[%@ addObject:%@];\n";
        
        if ([data isKindOfClass:[NSString class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSString:data]];
        }
        else if ([data isKindOfClass:[NSNumber class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSNumber:data]];
        }
        else if ([data isKindOfClass:[NSArray class]])
        {
            [curImplement appendFormat:@"%@{\n", [self indentTab:depth]];
            NSString *tempArrayInstanceName = @"";
            buildedSyntax = [self encodeNSArray:data indent:depth+1 createdInstanceName:&tempArrayInstanceName];
            [curImplement appendString:buildedSyntax];
            [curImplement appendString:[NSString stringWithFormat:currentSyntaxFormat, [self indentTab:depth + 1], tempInstanceName, tempArrayInstanceName]];
            [curImplement appendFormat:@"%@}\n", [self indentTab:depth]];
        }
        else if ([data isKindOfClass:[NSDictionary class]])
        {
            [curImplement appendFormat:@"%@{\n", [self indentTab:depth]];
            NSString *tempDictionaryInstanceName = @"";
            buildedSyntax = [self encodeNSDictionary:data indent:depth+1 createdInstanceName:&tempDictionaryInstanceName];
            [curImplement appendString:buildedSyntax];
            [curImplement appendString:[NSString stringWithFormat:currentSyntaxFormat, [self indentTab:depth + 1], tempInstanceName, tempDictionaryInstanceName]];
            [curImplement appendFormat:@"%@}\n", [self indentTab:depth]];
        }
        else if ([data isKindOfClass:[NSNull class]])
        {
            [curImplement appendFormat:currentSyntaxFormat, [self indentTab:depth], tempInstanceName, [self encodeNSNull:data]];
        }
        else
        {
            NSString *warningString = [NSString stringWithFormat:@"#warning cant parse data %@ class %@", data, [data class]];
            [curImplement appendString:warningString];
            NSLog(@"!!! ERROR !!! - %@", warningString);
        }
    
    }
    return curImplement;
}


- (NSString*)encodeNSNull:(NSNull*)object
{
    return [NSString stringWithFormat:@"%@", @"[NSNull null]"];
}


- (NSString*)encodeNSString:(NSString*)object
{
    return [NSString stringWithFormat:@"@\"%@\"", [object stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]];
}


- (NSString*)encodeNSNumber:(NSNumber*)object
{
    return [NSString stringWithFormat:@"[NSNumber numberWithLongLong:%@]", object];
}
*/


@end
