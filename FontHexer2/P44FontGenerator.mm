//
//  P44FontGenerator.mm
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import "P44FontGenerator.h"

#include <string>
#include <list>
#include <map>

using namespace std;

// MARK: - copied from p44utils/utils.cpp

#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h> // for ssize_t, size_t etc.


// old-style C-formatted output into string object
void __printflike(3,0) string_format_v(string &aStringObj, bool aAppend, const char *aFormat, va_list aArgs)
{
  const size_t bufsiz=128;
  size_t actualsize;
  char buf[bufsiz];
  int ret;

  buf[0]='\0';
  char *bufP = NULL;
  if (!aAppend) aStringObj.erase();
  // using aArgs in vsnprintf() is destructive, need a copy in
  // case we call the function a second time
  va_list args;
  va_copy(args, aArgs);
  ret = vsnprintf(buf, bufsiz, aFormat, aArgs);
  if (ret>=0) {
    actualsize = (size_t)ret;
    if (actualsize>=bufsiz) {
      // default buffer was too small, create bigger dynamic buffer
      bufP = new char[actualsize+1];
      ret = vsnprintf(bufP, actualsize+1, aFormat, args);
      if (ret>0) {
        aStringObj += bufP;
      }
      delete [] bufP;
    }
    else {
      // small default buffer was big enough, add it
      aStringObj += buf;
    }
  }
  va_end(args);
} // vStringObjPrintf


// old-style C-formatted output as string
string string_format(const char *aFormat, ...)
{
  va_list args;
  va_start(args, aFormat);
  string s;
  // now make the string
  string_format_v(s, false, aFormat, args);
  va_end(args);
  return s;
} // string_format


// old-style C-formatted output appending to string
void string_format_append(string &aStringToAppendTo, const char *aFormat, ...)
{
  va_list args;

  va_start(args, aFormat);
  // now make the string
  string_format_v(aStringToAppendTo, true, aFormat, args);
  va_end(args);
} // string_format_append


// MARK: - copied from p44lrgraphics/textview.h

typedef struct {
  uint8_t width;
  const char *coldata; // for multi-byte columns: MSByte first. Bit order: Bit0 = top pixel
} glyph_t;

typedef struct {
  const char* prefix;
  uint8_t first;
  uint8_t last;
  uint8_t glyphOffset;
} GlyphRange;

typedef struct {
  const char* fontName; ///< name of the font
  uint8_t glyphHeight; ///< height of the glyphs in pixels (max 32)
  size_t numGlyphs; ///< total number of glyphs
  const GlyphRange* glyphRanges; ///< mapping to codepoints
  const glyph_t* glyphs; ///< actual glyphs
} font_t;


// MARK: - coopied and adapted from p44lrgraphics/textview.cpp

const int placeholderGlyphNo = 0; // placeholder must be the first glyph


typedef struct {
  NSUInteger maxHeight;
  NSUInteger minWidth;
  NSUInteger maxWidth;
  NSUInteger numGlyphs;
  CGFloat averageWidth;
} FontInfo;

static FontInfo getFontInfo(NSDictionary* aFontDict)
{
  FontInfo fontInfo;
  fontInfo.maxHeight = 0;
  fontInfo.minWidth = 999;
  fontInfo.maxWidth = 0;
  fontInfo.numGlyphs = 0;
  fontInfo.averageWidth = 0;
  NSUInteger widthSum = 0;
  for (NSString *key in aFontDict) {
    NSArray* glyph = aFontDict[key];
    fontInfo.numGlyphs++;
    if (glyph.count>fontInfo.maxWidth) fontInfo.maxWidth = glyph.count;
    if (glyph.count<fontInfo.minWidth) fontInfo.minWidth = glyph.count;
    widthSum += glyph.count;
    for (NSArray* col in glyph) {
      if (col.count>fontInfo.maxHeight) fontInfo.maxHeight = (int)col.count;
    }
  }
  fontInfo.averageWidth = fontInfo.numGlyphs>0 ? (CGFloat)widthSum / fontInfo.numGlyphs : 0;
  return fontInfo;
}


static NSArray* glyphForCode(NSDictionary* aFontDict, NSString* aCode, FontInfo& aFontInfo)
{
  NSArray* glyph;
  // synthesize some special chars
  if ([aCode isEqualToString:@" "]) {
    // synthetize space
    NSMutableArray* spaceGlyph = [NSMutableArray array];
    for (int i=0; i<(int)(aFontInfo.averageWidth+0.5); i++) {
      [spaceGlyph addObject:@[@(NO)]]; // single pixel empty row
    }
    glyph = spaceGlyph;
  }
  else if ([aCode isEqualToString:@"placeholder"]) {
    // synthetize placeholder (rectangle of average width and full height)
    NSMutableArray* placeholderGlyph = [NSMutableArray array];
    int avgWidth = (int)(aFontInfo.averageWidth+0.5);
    for (int i=0; i<avgWidth; i++) {
      NSMutableArray* col = [NSMutableArray array];
      for (int j=0; j<aFontInfo.maxHeight; j++) {
        [col addObject:@(j==0 || j==aFontInfo.maxHeight-1 || i==0 || i==avgWidth-1 ? YES : NO)];
      }
      [placeholderGlyph addObject:col];
    }
    glyph = placeholderGlyph;
  }
  else {
    // sampled normal char
    glyph = aFontDict[aCode];
  }
  return glyph;
}


static void renderGlyphTextPixels(int aGlyphNo, NSArray* aGlyph, NSInteger aGlyphHeight, FILE* aOutputFile)
{
  int colno = 0;
  NSUInteger fillerRows = (-(int)aGlyphHeight) & 0x07;
  for (NSArray* col in aGlyph) {
    // one column, bit 0 is topmost pixel, we want to print that last
    string colstr;
    for (int i=0; i<fillerRows; i++) {
      colstr += ".";
    }
    for (int i=0; i<aGlyphHeight; i++) {
      BOOL pix = NO;
      if (col.count>i) {
        pix = [col[i] boolValue];
      }
      colstr += pix ? "X" : ".";
    }
    fprintf(aOutputFile, "  \"\\n\"   \"%s\" %c\n", colstr.c_str(), colno==aGlyph.count-1 ? ',' : ' ');
    colno++;
  }
  fprintf(aOutputFile, "\n");
}


static void fontAsGlyphStrings(NSDictionary* aFontDict, const char* aFontName, FILE* aOutputFile)
{
  fprintf(aOutputFile, "\n// MARK: - '%s' generated font verification data\n", aFontName);
  fprintf(aOutputFile, "\nstatic const char * font_%s_glyphstrings[] = {\n", aFontName);
  NSArray *sortedKeys = [aFontDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
  int glyphno = 0;
  FontInfo fontInfo = getFontInfo(aFontDict);
  for (NSString* key in sortedKeys) {
    NSArray* glyph = glyphForCode(aFontDict, key, fontInfo);
    string chardesc = [key UTF8String];
    string codedesc = "UTF-8";
    for (size_t i=0; i<chardesc.size(); i++) string_format_append(codedesc, " %02X", (uint8_t)chardesc[i]);
    if (chardesc.size()==1) {
      char lastchar = chardesc[0];
      if (lastchar=='\\') chardesc = "\\\\";
      else if (lastchar=='"') chardesc = "\\\"";
      else if (lastchar<0x20 || lastchar>0x7E) {
        chardesc = string_format("\\x%02x", lastchar);
      }
    }
    fprintf(aOutputFile, "  \"%s\" /* %s - Glyph %d */\n\n", chardesc.c_str(), codedesc.c_str(), glyphno);
    renderGlyphTextPixels(glyphno, glyph, fontInfo.maxHeight, aOutputFile);
    glyphno++;
  }
  fprintf(aOutputFile, "  nullptr // terminator\n");
  fprintf(aOutputFile, "};\n\n");
  fprintf(aOutputFile, "// MARK: - end of generated font verification data\n\n");
}


typedef std::pair<string, string> StringPair;
static bool mapcmp(const StringPair &a, const StringPair &b)
{
  return a.first < b.first;
}


static bool glyphDataToFontSource(NSDictionary* aFontDict, const char* aFontName, FILE* aOutputFile)
{
  fprintf(aOutputFile, "\n\n// MARK: - '%s' generated font data\n", aFontName);
  fprintf(aOutputFile, "\nstatic const glyph_t font_%s_glyphs[] = {\n", aFontName);
  // UTF8 mappings
  typedef std::list<StringPair> GlyphMap;
  GlyphMap gm;
  int gh = 0;
  // figure out max glyph height
  FontInfo fontInfo = getFontInfo(aFontDict);
  NSLog(@"highest glyph has height = %ld", (long)fontInfo.maxHeight);
  // iterate over dictionary
  int g = 0;
  for (NSString *key in aFontDict) {
    g++; // count the glyph
    string code = [key UTF8String];
    NSArray* glyph = glyphForCode(aFontDict, key, fontInfo);
    // create character definition
    string chr = "\"";
    for (NSArray* col in glyph) {
      // new glyph column
      uint64_t pixmap = 0;
      gh = 0;
      for (int i=0; i<fontInfo.maxHeight; i++) {
        pixmap = pixmap<<1;
        if (col.count>i) {
          pixmap |= [col[i] boolValue] ? 1 : 0;
        }
      }
      // Bit 0 of pixmap is topmost pixel of the glyph
      // Bit 0 of the first byte of the col data is topmoxt pixel of the glyph
      for (int i=((int)fontInfo.maxHeight-1)>>3; i>=0; --i) {
        string_format_append(chr, "\\x%02x", (unsigned int)(pixmap>>(i*8))&0xFF);
      }
    }
    chr += "\"";
    int w = (int)glyph.count;
    string codedesc = code; // default to non-code
    if (code=="placeholder") {
      code="\0"; // make sure it comes first
    }
    else {
      codedesc = string_format("'%s' UTF-8", code.c_str());
      for (size_t i=0; i<code.size(); i++) string_format_append(codedesc, " %02X", (uint8_t)code[i]);
    }
    string chardef = string_format("  { %2d, %-42s },  // %-20s (input # %d", w, chr.c_str(), codedesc.c_str(), g);
    gm.push_back(make_pair(code,chardef));
  }
  // now sort by Code
  gm.sort(mapcmp);
  int gno = 0;
  for (GlyphMap::iterator g = gm.begin(); g!=gm.end(); ++g, ++gno) {
    fprintf(aOutputFile, "%s -> glyph # %d)\n", g->second.c_str(), gno);
  }
  fprintf(aOutputFile, "};\n\n");
  // generate glyph number lookup
  fprintf(aOutputFile, "static const GlyphRange font_%s_ranges[] = {\n", aFontName);
  string prefix="NONE";
  string rangedesc;
  gno = 0;
  int glyphOffset = 0;
  string dispchars;
  for (GlyphMap::iterator g = gm.begin(); g!=gm.end(); ++gno) {
    string code = g->first;
    ++g;
    if (code[0]==0) continue; // this is the 0 codepoint which is the placeholder
    dispchars += code; // accumulate for display
    // split in prefix and lastbyte
    uint8_t lastbyte = code[code.size()-1];
    code.erase(code.size()-1);
    if (code!=prefix) {
      // start a new prefix
      prefix = code;
      glyphOffset = gno;
      rangedesc = "  { \"";
      for (size_t i=0; i<code.size(); i++) string_format_append(rangedesc, "\\x%02x", (uint8_t)code[i]);
      string_format_append(rangedesc, "\", 0x%02X, ", lastbyte);
    }
    if (g==gm.end() || (uint8_t)(g->first[g->first.size()-1])!=lastbyte+1) {
      // end of range (but maybe same prefix)
      prefix = "NONE";
      string_format_append(rangedesc, "0x%02X, %d }, // %s", lastbyte, glyphOffset, dispchars.c_str());
      fprintf(aOutputFile, "%s\n", rangedesc.c_str());
      dispchars.clear();
      rangedesc.clear();
    }
  }
  fprintf(aOutputFile, "  { NULL, 0, 0, 0 }\n");
  fprintf(aOutputFile, "};\n");
  // now the font head record
  fprintf(aOutputFile, "\nstatic const font_t font_%s = {\n", aFontName);
  fprintf(aOutputFile, "  .fontName = \"%s\",\n", aFontName);
  fprintf(aOutputFile, "  .glyphHeight = %ld,\n", (long)fontInfo.maxHeight);
  fprintf(aOutputFile, "  .numGlyphs = %d,\n", gno);
  fprintf(aOutputFile, "  .glyphRanges = font_%s_ranges,\n", aFontName);
  fprintf(aOutputFile, "  .glyphs = font_%s_glyphs\n", aFontName);
  fprintf(aOutputFile, "};\n");
  // end
  fprintf(aOutputFile, "\n// MARK: - end of generated font data\n\n");
  return true;
}



@implementation P44FontGenerator

+ (void)generateFontNamed:(NSString*)aFontName fromData:(NSDictionary*)aFontDict intoFILE:(FILE*)aOutputFile;
{
  fprintf(aOutputFile, "//  SPDX-License-Identifier: GPL-3.0-or-later\n");
  fprintf(aOutputFile, "//\n");
  fprintf(aOutputFile, "//  Autogenerated by plan44 FontHexer2 pixel font generator\n");
  fprintf(aOutputFile, "//\n");
  fprintf(aOutputFile, "//  You should have received a copy of the GNU General Public License\n");
  fprintf(aOutputFile, "//  along with p44lrgraphics. If not, see <http://www.gnu.org/licenses/>.\n");
  fprintf(aOutputFile, "//\n\n");
  fprintf(aOutputFile, "// This is a font file to be included from textview.cpp to define a font\n");
  fprintf(aOutputFile, "\n#ifdef GENERATE_FONT_SOURCE\n");
  fontAsGlyphStrings(aFontDict, [aFontName UTF8String], aOutputFile);
  fprintf(aOutputFile, "\n#endif // GENERATE_FONT_SOURCE\n");
  glyphDataToFontSource(aFontDict, [aFontName UTF8String], aOutputFile);
}

@end
