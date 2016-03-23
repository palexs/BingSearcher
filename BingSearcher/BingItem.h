//
//  BingItem.h
//  BingApp
//
//  Created by Oleksandr Perepelitsyn on 3/19/16.
//  Copyright © 2016 L9. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BingItem : NSObject

- (instancetype)initWithTitle:(NSString *)title href:(NSString *)href;
- (BOOL)isEqualToItem:(BingItem *)item;

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *href;

@end
