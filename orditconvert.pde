PImage im;

void setup() {
  size(80,25);

  im = loadImage("ordit.png");
  frameRate(1);
}


void draw() {
  background(0);
  byte[] barr1 = new byte[width/2*height];
  byte[] barr2 = new byte[width/2*height];
  int i = 0;
  image(im,0,0);
  for (int y = 0; y < height;y++) {
  for (int x = 0; x < width;x+=2) {
    color col = im.get(x,y);
    float value = brightness(col);
    barr1[i++] = byte(value/32); 
  }
  }

  i = 0;
  for (int y = 0; y < height;y++) {
  for (int x = 1; x < width;x+=2) {
    color col = im.get(x,y);
    float value = brightness(col);
    barr2[i++] = byte(value/32); 
  }
  }

  saveBytes("orditpic1.bin",barr1);
  saveBytes("orditpic2.bin",barr2);
  println("saved");
  exit();
}