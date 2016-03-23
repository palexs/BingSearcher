//
//  DetailViewController.h
//  BingSearcher
//
//  Created by Oleksandr Perepelitsyn on 3/22/16.
//  Copyright © 2016 L9. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BingItem;

@interface DetailViewController : UIViewController

@property (strong, nonatomic) BingItem *detailItem;

@end
