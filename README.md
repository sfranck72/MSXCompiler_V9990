# MSXCompiler_V9990  
*Adding V9990 fonctions to the MSXCompiler* 

**bosh77** is the author of MSXCompiler : [Download MSXCompiler](https://bosh77.itch.io/msx-compiler)  

## USE
In each Directory, the ROM is already available : `main.rom`
<br>  
But the use with MSXCompiler is :  
- Chose the 16 or 64 colors directory,
- Open `main.msxproj` file in MSXCompiler,
- Run the compilation to obtain the `main.rom`,
- use `main.rom` in MSX with V9990 or Emulator :
  - on openMSX, I use the `Boosted MSX2+ Japan` machine (include the V9990).
  - on WebMSX, set the ROM format to `KonamiSCC` and add `Video V9990` in the settings.

## RESULT

16 colors V9990             |  64 colors V9990
:-------------------------:|:-------------------------:  
[RUN in WebMSX](https://webmsx.org/?MACHINE=MSX2PJ&CARTRIDGE1_FORMAT=KonamiSCC&ROM=https://github.com/sfranck72/MSXCompiler_V9990/raw/refs/heads/main/mode%20B1%2016%20colors/main.rom&PRESETS=V9990) | [RUN in WebMSX](https://webmsx.org/?MACHINE=MSX2PJ&CARTRIDGE1_FORMAT=KonamiSCC&ROM=https://github.com/sfranck72/MSXCompiler_V9990/raw/refs/heads/main/mode%20B1%2064%20colors/main.rom&PRESETS=V9990)  
![](https://github.com/sfranck72/MSXCompiler_V9990/blob/main/image_B1_16colors.png)  |  ![](https://github.com/sfranck72/MSXCompiler_V9990/blob/main/image_B1_64colors.png)

## PREPARE IMAGES
I create a python script  [MSXCompiler_16_or_64_colors_V2.py](https://github.com/sfranck72/MSXCompiler_V9990/raw/refs/heads/main/MSXCompiler_16_or_64_colors_V2.py)  
Run it with the cmd command :  streamlit run path_of_the_script_MSXCompiler_16_or_64_colors_V2.py  
<br>
Load an image and obtain :  
- the RGB color list for the 16 or 64 colors
- the shrink data image files to suit the max of 16ko MSX pagination.
  
**CONSTRAINTS**
 - bmp image in the same root of the python script
 - bmp image must be 256 x 212 (or multiple height)
 - bmp image in the INDEXED mode (I use Aseprite for that) :
   - reduce the palette to 16 or 64 colors
   - menu SPRITE/COLOR MODE/INDEXED 


