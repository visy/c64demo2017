PShape s;

void setup() {
  size(128, 128, P3D);
  s = loadShape("Chest.obj");
  frameRate(30);
    background(255);
  noSmooth();

}

class Pair {
  int a,b;
  
  Pair(int _a, int _b) {
    a = _a;
    b = _b;
  }
}

int totalnow = 0;
int steps = 8;
int res = 2;
  float pu = width/2,pv = height/2;
  
  ArrayList<Pair> out_pairs = new ArrayList<Pair>();


void draw() {
  pushMatrix();
  translate(width/2., height/2.1);
  scale(69.3);
  rotate(PI);
  rotateY(PI/1);
  PShape tes = s.getTessellation();
  int total = tes.getVertexCount();
  ArrayList<Pair> uvs = new ArrayList<Pair>();
  
  for (int j = 0; j < total; j++) {
    PVector vv = tes.getVertex(j);
    vertex(vv.x, vv.y, vv.z);
    float u = screenX(vv.x,vv.y,vv.z);
    float v = screenY(vv.x,vv.y,vv.z);
    Pair p = new Pair((int)u/res,(int)v/res);
    uvs.add(p);
  }
  popMatrix();
  strokeWeight(1.0);
  stroke(32);
  noFill();
  int vc = 0;
    
  for (int j = totalnow; j < totalnow+steps; j+=1) {
    Pair p;
    if (j >= 0) p = uvs.get(j);
    else continue;

    if (j >= 1) line(pu*res,pv*res,p.a*res,p.b*res);
    
    if (p.a < 0 || p.b < 0 || p.a > width/res-1 || p.b > height/res-1) continue;
    
    Pair store_pair = new Pair(p.a,p.b);
    out_pairs.add(store_pair);
    
    pu = p.a;
    pv = p.b;
  }
  
    totalnow+=steps;
  if (totalnow >= total-steps) { totalnow = total-steps;
    println(out_pairs.size());
    save("out.bmp");
    exit(); 
  }

  fill(0);
//  text(total,16,16);
}