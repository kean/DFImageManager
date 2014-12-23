/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "SDFFlickrPhoto.h"

@implementation SDFFlickrPhoto

- (id)initWithJSON:(id)JSON {
    if (self = [super init]) {
        self.farm = [JSON valueForKey:@"farm"];
        self.itemid = [JSON valueForKey:@"id"];
        self.isfamily = [JSON valueForKey:@"isfamily"];
        self.isfriend = [JSON valueForKey:@"isfriend"];
        self.ispublic = [JSON valueForKey:@"ispublic"];
        self.owner = [JSON valueForKey:@"owner"];
        self.secret = [JSON valueForKey:@"secret"];
        self.server = [JSON valueForKey:@"server"];
        self.title = [JSON valueForKey:@"title"];
        // http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
        self.photoURL = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_m.jpg", self.farm, self.server, self.itemid, self.secret];
        self.photoURLSmall = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_s.jpg", self.farm, self.server, self.itemid, self.secret];
    }
    return self;
}

@end
