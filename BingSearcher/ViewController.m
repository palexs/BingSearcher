//
//  ViewController.m
//  BingSearcher
//
//  Created by Oleksandr Perepelitsyn on 3/22/16.
//  Copyright © 2016 L9. All rights reserved.
//

#import "ViewController.h"
#import "TFHpple.h"
#import "BingItem.h"
#import "DetailViewController.h"

NSTimeInterval const kTimerInterval = 2.0;
NSString const *kBingWebSeacrhUrlString = @"https://www.bing.com/search";
NSString const *kBingImageSeacrhUrlString = @"https://www.bing.com/images/search";
NSString *kPersistenceKey = @"BingSearchResults";

typedef NS_ENUM(NSInteger, SearchType) {
    SearchTypeWeb = 0,
    SearchTypeImage
};

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) SearchType currentSeacrhType;
@property NSMutableArray *objects;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadObjects];
    self.currentSeacrhType = (SearchType)self.searchBar.selectedScopeButtonIndex;
    self.navigationItem.title = @"Search bing.com";

    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self purgeObjects];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];
    self.timer = nil;
    
    [super viewWillDisappear:animated];
}

#pragma mark - Persistence

- (void)saveObjects {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:self.objects];
    [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:kPersistenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadObjects {
    NSData *encodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:kPersistenceKey];
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    if (objects) {
        self.objects = objects;
    } else {
        self.objects = [NSMutableArray array];
    }
}

- (void)purgeObjects {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
    [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:kPersistenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        BingItem *item = self.objects[indexPath.row];
        DetailViewController *detailVC = (DetailViewController *)[segue destinationViewController];
        [detailVC setDetailItem:item];
    }
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.objects.count == 0) {
        UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        noDataLabel.text = @"No data is available.";
        noDataLabel.textAlignment = NSTextAlignmentCenter;
        [noDataLabel sizeToFit];
        self.tableView.backgroundView = noDataLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        return 0;
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    BingItem *item = self.objects[indexPath.row];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.href;
    
    switch (self.currentSeacrhType) {
        case SearchTypeWeb: {
            cell.imageView.image = nil;
        }
            break;
        case SearchTypeImage: {
            cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
            NSURL *url = [NSURL URLWithString:item.href];
            NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data) {
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.imageView.image = image;
                            [cell layoutSubviews];
                        });
                    }
                }
            }];
            [task resume];
        }
            break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0;
}

#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"Searching for: %@", searchText);
    
    if (searchText.length > 0) {
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:kTimerInterval target:self selector:@selector(timerFired:) userInfo:@{@"keyword" : searchText} repeats:NO];
    } else {
        [self processResult:@[]];
    }
}

- (void)processResult:(NSArray *)objects {
    [self.objects removeAllObjects];
    [self.objects addObjectsFromArray:objects];
    [self.tableView reloadData];
    [self saveObjects];
}

- (void)timerFired:(NSTimer *)timer {
    NSString *searchKeyword = timer.userInfo[@"keyword"];
    [self performSearchWithKeyword:searchKeyword];
}

- (void)performSearchWithKeyword:(NSString *)keyword {
    self.objects = [NSMutableArray array];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    void (^searchCompleted)(NSArray *) = ^(NSArray *objects) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self processResult:objects];
        });
    };
    
    if (keyword.length > 0) {
        switch (self.currentSeacrhType) {
            case SearchTypeWeb: {
                [self performWebSearchForKeyword:keyword completion:^(NSArray *objects) {
                    searchCompleted(objects);
                }];
            }
                break;
            case SearchTypeImage: {
                [self performImageSearchForKeyword:keyword completion:^(NSArray *objects) {
                    searchCompleted(objects);
                }];
            }
                break;
        }
    } else {
        searchCompleted([NSArray array]);
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.currentSeacrhType = (SearchType)selectedScope;
    
    NSString *searchKeyword = self.searchBar.text;
    if (searchKeyword.length > 0) {
        [self performSearchWithKeyword:searchKeyword];
    } else {
        [self processResult:@[]];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Bing Search

- (void)performWebSearchForKeyword:(NSString *)searchKeyword completion:(void (^)(NSArray *))completion {
    NSString *searchString = [[NSString stringWithFormat:@"%@?q=%@", kBingWebSeacrhUrlString, searchKeyword] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *searchUrl = [NSURL URLWithString:searchString];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSData *htmlData = [NSData dataWithContentsOfURL:searchUrl];
        
        TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
        NSArray *nodes = [parser searchWithXPathQuery:@"//li[@class='b_algo']/h2/a | //li[@class='b_algo']/div[@class='b_title']/h2/a"];
        
        NSMutableArray *items = [NSMutableArray array];
        for (TFHppleElement *node in nodes) {
            NSString *href = [node objectForKey:@"href"];
            
            NSMutableString *title = [NSMutableString string];
            for (TFHppleElement *child in node.children) {
                if ([child text]) [title appendString:[child text]];
                if ([child content]) [title appendString:[child content]];
            }
            
            BingItem *item = [[BingItem alloc] initWithTitle:[title copy] href:href];
            [items addObject:item];
        }
        
        if (completion) {
            completion([items copy]);
        }
    });
    
}

- (void)performImageSearchForKeyword:(NSString *)searchKeyword completion:(void (^)(NSArray *))completion {
    NSString *searchString = [[NSString stringWithFormat:@"%@?q=%@", kBingImageSeacrhUrlString, searchKeyword] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *searchUrl = [NSURL URLWithString:searchString];
    NSData *htmlData = [NSData dataWithContentsOfURL:searchUrl];
    
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    
//    NSMutableArray *titles = [NSMutableArray array];
//    NSArray *nodes1 = [parser searchWithXPathQuery:@"//div[@class='des']"];
//    for (TFHppleElement *node in nodes1) {
//        NSString *title = [node text];
//        [titles addObject:title];
//    }
    
    NSMutableArray *items = [NSMutableArray array];
    NSArray *nodes = [parser searchWithXPathQuery:@"//div[@class='cico']/img"]; //@"//div[@class='dg_u']/a/img"];
    for (TFHppleElement *node in nodes) {
        NSString *imgUrl = [node objectForKey:@"src"];
        NSLog(@"imgUrl: %@", imgUrl);
        BingItem *item = [[BingItem alloc] initWithTitle:searchKeyword href:imgUrl];
        [items addObject:item];
    }
    
    if (completion) {
        completion([items copy]);
    }
}

@end
