PImage[] images;
PGraphics pg;

  int frames = 16;

void setup() {
  size(400,300);
  frameRate(10);
  images = new PImage[frames];
  images[0] = loadImage("bol0.png");
  images[1] = loadImage("bol1.png");
  images[2] = loadImage("bol2.png");
  images[3] = loadImage("bol3.png");
  images[4] = loadImage("bol4.png");
  images[5] = loadImage("bol5.png");
  images[6] = loadImage("bol6.png");
  images[7] = loadImage("bol7.png");
  images[8] = loadImage("bol6.png");
  images[9] = loadImage("bol5.png");
  images[10] = loadImage("bol4.png");
  images[11] = loadImage("bol3.png");
  images[12] = loadImage("bol2.png");
  images[13] = loadImage("bol1.png");
  images[14] = loadImage("bol0.png");
  images[15] = loadImage("bol1.png");
  pg = createGraphics(80, 50);
}

  int frame = 0;
void draw() {
  background(92,92,192);
  fill(0);
  rect(40,50,320,200);
  strokeWeight(1);
  byte[] picdata = new byte[1002];
  int byteindex = 2;
  picdata[0] = (byte)0;
  picdata[1] = (byte)68;
  
  
  pg.beginDraw();
  pg.background(255,0,0);
  pg.image(images[frame],0,0);
  pg.endDraw();
  
  for (int y=0; y < 50; y+=2) {
    for (int x=0; x < 80; x+=2) {
  
      String nyb = "";
      int nx = 0;
      int ny = 0;
      int bitvalue = 1;
      int times = 0;
      for (int y2=0; y2 < 2; y2+=1) {
      for (int x2=0; x2 < 2; x2+=1) {
      color c = pg.get(x+x2,y+y2);
      int cc = 0;
      if (c == -16777216) cc = 0;
      else if (c == -8355712) cc = 1;
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
  
  saveBytes("bol" + frame + ".bin",picdata);
  println("saved " + "bol" + frame + ".bin");

  frame++;

  if (frame >= frames) {
  println("conversion done");
  frameRate(0);
  }
}