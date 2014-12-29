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

#pragma mark - Functions -

static inline void
_dwarf_cache_callback(void (^block)(id), id object) {
    if (block != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(object);
        });
    }
}

/*! Produces 160-bit hash value using SHA-1 algorithm.
 @return String containing 160-bit hash value expressed as a 40 digit hexadecimal number.
 */
extern NSString *
_dwarf_cache_sha1(const char *data, uint32_t length);

/*! Returns user-friendly string with bytes.
 */
extern NSString *
_dwarf_bytes_to_str(unsigned long long bytes);

#pragma mark - Types -

typedef unsigned long long _dwarf_cache_bytes;
