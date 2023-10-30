/*****************************************************************************
 * VLCLibraryCollectionViewMediaItemSupplementaryDetailView.m: MacOS X interface module
 *****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
 *
 * Authors: Claudio Cambra <claudio.cambra@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCLibraryCollectionViewMediaItemSupplementaryDetailView.h"

#import "extensions/NSString+Helpers.h"
#import "extensions/NSFont+VLCAdditions.h"
#import "extensions/NSColor+VLCAdditions.h"
#import "extensions/NSView+VLCAdditions.h"

#import "main/VLCMain.h"

#import "library/VLCInputItem.h"
#import "library/VLCLibraryController.h"
#import "library/VLCLibraryDataTypes.h"
#import "library/VLCLibraryImageCache.h"
#import "library/VLCLibraryModel.h"
#import "library/VLCLibraryMenuController.h"
#import "library/VLCLibraryRepresentedItem.h"
#import "library/VLCLibraryWindow.h"

#import "views/VLCImageView.h"

NSString *const VLCLibraryCollectionViewMediaItemSupplementaryDetailViewIdentifier = @"VLCLibraryCollectionViewMediaItemSupplementaryDetailViewIdentifier";
NSCollectionViewSupplementaryElementKind const VLCLibraryCollectionViewMediaItemSupplementaryDetailViewKind = @"VLCLibraryCollectionViewMediaItemSupplementaryDetailViewIdentifier";

@implementation VLCLibraryCollectionViewMediaItemSupplementaryDetailView

- (void)awakeFromNib
{
    _mediaItemTitleTextField.font = NSFont.VLCLibrarySubsectionHeaderFont;
    _mediaItemDetailButton.font = NSFont.VLCLibrarySubsectionSubheaderFont;

    if (@available(macOS 10.14, *)) {
        _mediaItemDetailButton.contentTintColor = NSColor.VLCAccentColor;
    }

    if(@available(macOS 10.12.2, *)) {
        _playMediaItemButton.bezelColor = NSColor.VLCAccentColor;
    }
}

- (NSString *)formattedYearAndDurationString
{
    if (self.representedItem == nil) {
        return @"";
    }

    const VLCMediaLibraryMediaItem * const actualItem = self.representedItem.item;

    if (actualItem.year > 0) {
        return [NSString stringWithFormat:@"%u · %@", actualItem.year, actualItem.durationString];
    } else if (actualItem.files.count > 0) {
        VLCMediaLibraryFile * const firstFile = actualItem.files.firstObject;
        const time_t fileLastModTime = firstFile.lastModificationDate;

        if (fileLastModTime > 0) {
            NSDate * const lastModDate = [NSDate dateWithTimeIntervalSince1970:fileLastModTime];
            NSDateComponents * const components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:lastModDate];
            return [NSString stringWithFormat:@"%ld · %@", components.year, actualItem.durationString];
        }
    }

    return actualItem.durationString;
}

- (void)updateRepresentation
{
    NSAssert(self.representedItem, @"no represented item assigned for collection view item", nil);
    VLCMediaLibraryMediaItem * const actualItem = self.representedItem.item;
    NSAssert(actualItem != nil, @"represented item is not a media item", nil);

    _mediaItemTitleTextField.stringValue = actualItem.displayString;
    _mediaItemDetailButton.title = actualItem.detailString;
    _mediaItemYearAndDurationTextField.stringValue = [self formattedYearAndDurationString];
    _mediaItemFileNameTextField.stringValue = actualItem.inputItem.name;
    _mediaItemPathTextField.stringValue = actualItem.inputItem.decodedMRL;

    const BOOL actionableDetail = actualItem.actionableDetail;
    self.mediaItemDetailButton.enabled = actionableDetail;
    if (@available(macOS 10.14, *)) {
        self.mediaItemDetailButton.contentTintColor = actionableDetail ? NSColor.VLCAccentColor : NSColor.secondaryLabelColor;
    }
    self.mediaItemDetailButton.action = @selector(detailAction:);

    [VLCLibraryImageCache thumbnailForLibraryItem:actualItem withCompletion:^(NSImage * const thumbnail) {
        self->_mediaItemArtworkImageView.image = thumbnail;
    }];
}

- (IBAction)playAction:(id)sender
{
    [self.representedItem play];
}

- (IBAction)enqueueAction:(id)sender
{
    [self.representedItem queue];
}

- (IBAction)detailAction:(id)sender
{
    VLCMediaLibraryMediaItem * const actualItem = self.representedItem.item;
    if (actualItem == nil || !actualItem.actionableDetail) {
        return;
    }

    VLCLibraryWindow * const libraryWindow = VLCMain.sharedInstance.libraryWindow;
    const id<VLCMediaLibraryItemProtocol> libraryItem = actualItem.actionableDetailLibraryItem;
    [libraryWindow presentLibraryItem:libraryItem];
}

@end
