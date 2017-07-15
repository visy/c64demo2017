int sintab[];
int costab[];

void setup() {
  size(128,128);
  frameRate(300);

  sintab = new int[256];
  costab = new int[256];
  for (int i = 0; i < 256; i++) {
    sintab[i] = round(63.*sin(radians(i*360./128.)));
    costab[i] = round(63.*cos(radians(i*360./128.)));
  }

  background(255);
}

int f = 0;

int i = 0;
int i2 = 0;

void draw() {
  int x = (sintab[(i) & 255]);
  int y = costab[(i+i2) & 255]+costab[i & 255];
  set(63+x,63+y,color(0));
  f++;
  i++;
  
  if (f > 32) {i2+=1; f = 0; }

  if (i > 255) i = 0;
  if (i2 > 255) i2 = 0;
  if (f > 255) f = 0;

}