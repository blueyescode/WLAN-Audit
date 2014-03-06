/*
 * WAMasterViewController.m
 *
 * Copyright 2014 Roberto Estrada
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "WAMasterViewController.h"
#import "WANetworkDetailsViewController.h"
#import "WANetworkData.h"

#if TARGET_IPHONE_SIMULATOR
    #import "WASimulatorNetworksManager.h"
#else
    #import "MSNetworksManager.h"
#endif

@interface WAMasterViewController ()

@property (nonatomic, strong) NSMutableArray *scannedNetworksList;
@property (nonatomic, strong) MSNetworksManager *networksManager;

@end

@implementation WAMasterViewController

@synthesize scannedNetworksList;
@synthesize networksManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scannedNetworksList = [NSMutableArray array];
    self.detailViewController = (WANetworkDetailsViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    // Notification of scan completion
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanFinished) name:@"stoppedScanning" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scanForNetworks];
}

#pragma mark - Network scanning

- (void)scanForNetworks {
    [self setupNetworksManager];
    [networksManager removeAllNetworks];
    [scannedNetworksList removeAllObjects];
    [networksManager scan];
}

- (void)setupNetworksManager {
	if (networksManager == nil) {
#if TARGET_IPHONE_SIMULATOR
		networksManager = [WASimulatorNetworksManager sharedNetworksManager];
#else
		networksManager = [MSNetworksManager sharedNetworksManager];
#endif
	}
}

- (void)scanFinished {
    // Reloading data in the table view
    NSArray *results = [[networksManager networks] allValues];
    for (NSDictionary* scanResult in results) {
        [scannedNetworksList addObject:[[WANetworkData alloc] initWithDictionary:scanResult]];
    }
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return scannedNetworksList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    WANetworkData *network = scannedNetworksList[indexPath.row];
    cell.textLabel.text = network.essid;
    cell.detailTextLabel.text = network.bssid;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        WANetworkData *network = scannedNetworksList[indexPath.row];
        self.detailViewController.network = network;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        WANetworkData *network = scannedNetworksList[indexPath.row];
        [[segue destinationViewController] setNetwork:network];
    }
}

@end
