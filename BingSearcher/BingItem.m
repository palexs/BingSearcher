//
//  BingItem.m
//  BingApp
//
//  Created by Oleksandr Perepelitsyn on 3/19/16.
//  Copyright © 2016 L9. All rights reserved.
//

#import "BingItem.h"

@interface BingItem ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *href;

@end

@implementation BingItem

- (instancetype)initWithTitle:(NSString *)title href:(NSString *)href {
    self = [super init];
    if (self) {
        _title = [title copy];
        _href = [href copy];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.href forKey:@"href"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.title = [decoder decodeObjectForKey:@"title"];
        self.href = [decoder decodeObjectForKey:@"href"];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[BingItem class]]) {
        return NO;
    }
    
    return [self isEqualToItem:(BingItem *)object];
}

- (BOOL)isEqualToItem:(BingItem *)item {
    return [self.title isEqualToString:item.title] && [self.href isEqualToString:item.href];
}

- (NSUInteger)hash {
    return [self.title hash] ^ [self.href hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BingItem - title: %@, href: %@", self.title, self.href];
}

@end
