// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

typedef id (^DFCacheDecodeBlock)(NSData *data);
typedef NSData *(^DFCacheEncodeBlock)(id object);
typedef NSUInteger (^DFCacheCostBlock)(id object);

#pragma mark - <NSCoding>

static const DFCacheEncodeBlock DFCacheEncodeNSCoding = ^NSData *(id<NSCoding> object){
    if (!object) {
        return nil;
    }
    return [NSKeyedArchiver archivedDataWithRootObject:object];
};

static const DFCacheDecodeBlock DFCacheDecodeNSCoding = ^id<NSCoding>(NSData *data){
    if (!data) {
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
};

#pragma mark - JSON

static const DFCacheEncodeBlock DFCacheEncodeJSON = ^NSData *(id JSON){
    if (!JSON) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:JSON options:kNilOptions error:nil];
};

static const DFCacheDecodeBlock DFCacheDecodeJSON = ^id(NSData *data){
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
};
