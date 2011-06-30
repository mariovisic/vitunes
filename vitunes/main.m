//
//  main.m
//  vitunes
//
//  Created by Daniel Choi on 6/29/11.
//  Copyright 2011 by Daniel Choi. All rights reserved.
//
#import "iTunes.h"
#import <Foundation/Foundation.h>

static iTunesApplication *iTunes;
static iTunesPlaylist *music;
static iTunesSource *library;

NSString *formatTrackForDisplay(iTunesTrack *track) {
  return [NSString stringWithFormat: @"%d %@ %@ %@ (%d) %@", 
          track.databaseID,
          track.name,
          track.album,
          track.artist,
          track.year,
          track.genre];
}

SBElementArray *search(NSArray *args)  {
  NSString *query = [args componentsJoinedByString:@" "];
  return [music searchFor:query only:iTunesESrAAll];
}

void playTrackID(NSArray *args) {
  NSString *databaseIdString = [args objectAtIndex:0];
  NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
  [f setNumberStyle:NSNumberFormatterDecimalStyle];
  NSNumber *databaseId = [f numberFromString:databaseIdString];
  [f release];
  NSArray *matchingTracks = [[music tracks] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"databaseID == %@", databaseId]];
  iTunesTrack* t = [matchingTracks objectAtIndex:0];
  NSLog(@"playing track: %@", [t name]);
  [t playOnce:false];
}

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  NSArray *rawArgs = [[NSProcessInfo processInfo] arguments];
  NSString *action;
  NSArray *args;

  NSLog(@"args: %@", rawArgs);
  if ([rawArgs count] < 2) {
    action = @"search";
    args = [NSArray arrayWithObject:@"bach"];
  } else {
    action = [rawArgs objectAtIndex:1];
    NSRange aRange;
    aRange.location = 2;
    aRange.length = [rawArgs count] - 2;
    args = [rawArgs subarrayWithRange:aRange];
  }

  iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
  library = [[iTunes sources] objectWithName:@"Library"];
  music = [[library playlists] objectWithName:@"Music"];

  if ([action isEqual: @"search"]) {
    NSArray *tracks = search(args);
    for (iTunesTrack *track in tracks) {
      printf("%s\n", [formatTrackForDisplay(track) cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  } else if ([action isEqual: @"playTrackID"]) { 
    playTrackID(args);
  } 

  [pool drain];
  return 0;
}

