# CWB-Processing
Continuous whitebalance utility
This utility takes a video (in form of an image-sequence folder) and analyzes every frame for white (and black) balance and corrects it.
In the correction stage, the math from DaVinci Resolve was replicated.

**This is only a test.** This is a template for a future GLSL/OFX shader plugin for Resolve. ...I just needed to try the math somewhere. It was written in an evening and is poorly optimized.

### Usage
1) Change the sourceDir and outDir variables to match the source folder of images (preferably .png or .tiff) and the directory into which you want to render the results.
2) Start the sketch
3) Use the mouse to drag the "White" colorpicker to the area you want to sample for white reference. Use the mouse wheel to resize the area. It is recomended to make it as large as posible to reduce noise.
4) If you are using blackbalance, use the same controls with the SHIFT key pressed, to set it up in the same way
5) to preview the correction, press SPACE to enable both WB and BB, press W to enable WB and press B to enable BB (and also its colorpicker)
6) to render, press F12
