//
//  DetailViewController.m
//  BingSearcher
//
//  Created by Oleksandr Perepelitsyn on 3/22/16.
//  Copyright © 2016 L9. All rights reserved.
//

#import "DetailViewController.h"
#import "BingItem.h"

@interface DetailViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation DetailViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = self.detailItem.title;
    
    NSURL *url = [NSURL URLWithString:self.detailItem.href];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:15.0];
    [self.webView loadRequest:request];
}

#pragma mark - Web View Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error {
    NSString *alertTitle = @"Error";
    NSString *cancelButtonTitle = @"Ok";
    
    if ([UIAlertController class]) { // iOS 8,9
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    } else { // iOS 7 and older
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:error.localizedDescription
                                                       delegate:self
                                              cancelButtonTitle:cancelButtonTitle
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

@end
