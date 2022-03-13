# Bacure - Little help for Basickness patients
 App Game Kit 2 Tier 1 language helper functions 
 by Leo Rela Leo.Rela@gmail.com

 Note: Function names beginning with "_" e.g. like _DoSomething are internal ones, don't use them directly

## Features:
	+ Boolean constants
	+ Low performance string key/value maps + wrappers for float and integers
	+ Low performance string value sets + wrappers for float and integers	
	+ Type guess/check for string content: int, float or str
	+ (De)serialize maps to/from CSV files
	+ Logging
	+ TGF Trivial Graph Format parser
	+ Simple XML parser (Partial support)
	+ Tiled (map editor) TMX file parser (Partial support, read TMX support specification* for more info)
	+ Stack for string values
	+ Generate UUIDs
	+ Yarn document parser
	+ DialogTree D3 support http://sol.gfxile.net/d3/


 Use Tiled 1.1.0 with following export settings:
	Format: .tmx
	Orientation: Orthogonal
	Tile layer format: CSV
	
	As Tiled is only partially supported so there are NO support for:
	  - External TSX tile set files
	  - Other tile layer data formats than CSV
	  - Embedded Tile data, tile content must be taken from Image file
	  - Wang sets
	  - Chunks

  D3 Studio 110808 ALPHA supported
	 Format: XML 
