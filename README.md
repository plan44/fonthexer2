# FontHexer2

FontHexer2 is a simple macOS app for converting fonts into "hex" (binary one-bit-per-pixel) representations for use in embedded devices with low-res pixel displays such as SmartLED (WS281x) chains.
This works best for fonts that were originally designed for low resolutions, like retro fonts taken from or inspired from old computers and terminals.

The current version of the app can only export the fonts as C++ source files suitable for use in [p44lrgraphics](https://github.com/plan44/p44lrgraphics) `TextView`. These can be of any height up to 64pixels max, and support variable character widths.

The app structure is such that adding different export formats would be simple, the sampling process is completely separated from the export (which is in the `P44FontGenerator` class)

![fonthexer2](assets/fonthexer2.png)

## Usage

- select a font using the popup or the font panel (sometimes flakey)
- use the size slider at the right to fit the grid on the first character (you can set different chars for preview).
- Drag the grid and place the red origin point at the bottom left corner (including descenders)
- possibly modify the character set in the long line at the bottom, these are the characters that will be included in the output. Standard is ASCII 0x20..0x7E plus a few Central European accented characters.
- possibly modify the font name for the output
- press "Generate...", select where to generate the output file
- To use/compile with p44lrgraphics, put the output file into the `p44lrgraphics/fonts` folder and modify the `fonts[]` table in `p44lrgraphics/textview.cpp` accordingly.

## How this app came to be

The p44lgraphics export part is fully hand-coded C++ mostly adapted from existing code in `p44lgraphics/textview.cpp`.

However the mac app itself is mostly the result of a conversion with ChatGPT 3.5. I have a firm understanding of the Cocoa concepts, but my practice is very dated and mostly iOS focused, so for every little UI detail I would have needed to research APIs and howtos. Asking the AI chatbot made this much easier - the suggested code usually worked out of the box. Finetuning then turned out to be more efficient to do manually (or leave for later, like proper fontpanel functioning) - the more detailed and specific my prompt was, the more the AI tended to hallucinate the APIs that *would* fit my needs - but don't exist.

---

(c) 2023 by luz/plan44.ch
