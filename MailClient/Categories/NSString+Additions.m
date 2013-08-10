//
//  NSString+Additions.m
//  MailClient
//
//  Created by Barney on 7/28/13.
//  Copyright (c) 2013 pvllnspk. All rights reserved.
//

#import "NSString+Additions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Additions)

-(BOOL) contains:(NSString*) substring
{
    return ([self rangeOfString:substring].location != NSNotFound);
}

- (NSString *) md5{
    const char *concat_str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}

-(NSString *)replaceIfEmptyWith:(NSString *)string
{
    
}

@end
