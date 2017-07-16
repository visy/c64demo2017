PImage[] images;
PGraphics pg;
PImage greets;
  int frames = 16;

void setup() {
  size(400,900);
  frameRate(10);
  pg = createGraphics(80, 800);
  greets = loadImage("pcnu.png");
}

  int frame = 0;
void draw() {
  background(92,92,192);
  fill(0);
  rect(40,50,320,800);
  strokeWeight(1);
  byte[] picdata = new byte[2+1000*16];
  int byteindex = 2;
  picdata[0] = (byte)0;
  picdata[1] = (byte)68;
  
  
  pg.beginDraw();
  pg.background(255,255,255);
  pg.image(greets,0,0);
  pg.endDraw();
  
  for (int y=0; y < 800; y+=2) {
    for (int x=0; x < 80; x+=2) {
  
      String nyb = "";
      int nx = 0;
      int ny = 0;
      int bitvalue = 1;
      int times = 0;
      for (int y2=1; y2 >= 0; y2-=1) {
      for (int x2=1; x2 >= 0; x2-=1) {
      color c = pg.get(x+x2,y+y2);
      println(c);
      int cc = 0;
      if (c == -16777216) cc = 0;
      else if (c == -12303292) cc = 1;
      else if (c == -1) cc = 2;
  
      if (cc == 0) { noStroke(); fill(0);  }
      if (cc == 1) { stroke(255); fill(0); nx+=bitvalue; }
      if (cc == 2) { stroke(255); fill(255); nx+=bitvalue; ny+=bitvalue; }

      bitvalue = bitvalue << 1;
      
      ellipse(40+(x+x2)*4,50+(y+y2)*4,4,4);
      }
      }
  
      int charvalue = ((ny*16)+nx);
      picdata[byteindex++] = (byte)charvalue;
  
    }
  }
  
  saveBytes("bolgreets.bin",picdata);
  println("saved " + "bol" + frame + ".bin");

//  frame++;

  //if (frame >= frames) {
  println("conversion done");
  frameRate(0);
 // }
}