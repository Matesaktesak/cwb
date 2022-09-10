//import processing.video.*;

PImage src;
//Movie src;
PImage out;

int wRadius = 15;
int wPickerP[] = new int[2];

int bRadius = 15;
int bPickerP[] = new int[2];

int previewFrame = 0;

boolean wCorrection = false;
boolean bCorrection = false;
boolean rendering = false;

int frameRendered = 0;
int frames = 0;

String sourceDir = "D:/Projects/CWB Processing/cwb/src";
String outDir = "D:/Projects/CWB Processing/cwb/out1";

java.io.File folder = new java.io.File(dataPath(sourceDir));
String filenames[] = folder.list();

void settings() {
  src = loadImage(sourceDir + "/" + filenames[0]);
  size(src.width, src.height);
  
  size(1920, 1080);
  
  println("Sketch setting processed");
}

void setup() {
  println("Sketch setup started");

  out = createGraphics(width, height);
  
  //frameRate(25);
  //src = new Movie(this, "D:/Projects/CWB Processing/cwb/test.mov");
  //src.loop();
  
  frames = filenames.length;

  wPickerP[0] = width/2;
  wPickerP[1] = height/2;
  
  bPickerP[0] = width/2 + wRadius + bRadius + 10;
  bPickerP[1] = height/2;

  colorMode(RGB, 255, 255, 255);

  println("Sketch setup completed");
}

void draw() {
  if(!rendering){
    //if(src.available()) src.read();
    src.loadPixels();
    
    color srcWhite = sampleArea(src, wPickerP[0], wPickerP[1], wRadius);
    color srcBlack = sampleArea(src, bPickerP[0], bPickerP[1], bRadius);
    
    if(wCorrection || bCorrection){
      out = corrector(src, wCorrection, bCorrection);
    }
    
    image(wCorrection || bCorrection ? out : src, 0, 0);
  
    // White picker
    push();
      fill(0);
      text("White", wPickerP[0]-wRadius, wPickerP[1]-wRadius);
      fill(srcWhite);
      rect(wPickerP[0]-wRadius, wPickerP[1]-wRadius, wRadius*2, wRadius*2);
    pop();
    
    // Black picker
    if(bCorrection){
      push();
        fill(255);
        text("Black", bPickerP[0]-bRadius, bPickerP[1]-bRadius);
        fill(srcBlack);
        stroke(255);
        rect(bPickerP[0]-bRadius, bPickerP[1]-bRadius, bRadius*2, bRadius*2);
      pop();
    }
  
    push();
    noStroke();
    fill(0x55000000);
    rect(20, 20, 300, 100);
    pop();
  
    fill(255);
    text("Sample wRadius: " + nf(wRadius), 50, 50);
    text("Sample area center: [" + nf(wPickerP[0]) + ", " + nf(wPickerP[1]) + "]", 50, 65);
    text("Sampled color: " + hex(srcWhite).substring(2), 50, 80);
  
    push();
    fill(srcWhite);
    rect(190, 67, 20, 20);
    pop();
  
    //text("Sampled luma: " + nf(whiteLuma), 50, 95);
    text(wCorrection || bCorrection ? "CORRECTED IMAGE" : "SOURCE IMAGE", 50, 95);
    
    push();
      fill(0x55000000);
      rect(0,height-50, width, 50);
      fill(0xff000000);
      rect(width*previewFrame/frames, height-50, 20, 50);
    pop();
  }
  
  if(rendering){
    background(0);
    push();
      noStroke();
      fill(0xffFFFF00);
      rect(0,0,width*frameRendered/frames,height);
    pop();
    
    push();
      noStroke();
      fill(0x55000000);
      rect(20, 20, 300, 100);
    pop();
    
    text("RENDERING", 50, 60);
    text("Progress: " + nf(frameRendered) + "/" + nf(frames) + "frames (" + nf((frameRendered/frames)*100) + "% done)", 50, 75);
    
    image(out, 20, 160, width/3, height/3);
  
  }
}

void render(){
  rendering = true;
  frames = filenames.length;
  
  for(int i = 0; i<frames; i++){
    if(keyPressed && keyCode == 9) break; // If TAB was pressed, abort
    
    frameRendered = i;
    out = corrector(loadImage(sourceDir + "/" + filenames[i]), wCorrection, bCorrection);
    out.save(outDir + "/" + filenames[i]);
  }
  
  rendering = false;
}

/*
PImage correct(Movie srcMov){
  srcMov.loadPixels();
  return correct(srcMov.get());
}
*/

PImage corrector(PImage src, boolean wC, boolean bC){
  colorMode(RGB, 255, 255, 255, 255);
  PImage o = createImage(src.width, src.height, ARGB);
  
  o.loadPixels();
  src.loadPixels();
  o.pixels = src.pixels.clone();
  
  color srcWhite = wC ? sampleArea(src, wPickerP[0], wPickerP[1], wRadius) : 0xffFFFFFF;
  color srcBlack = bC ? sampleArea(src, bPickerP[0], bPickerP[1], bRadius) : 0xff000000;
  
  //out.beginDraw();
  float wLuma = wC ? (red(srcWhite) + green(srcWhite) + blue(srcWhite)) / 3f : 1;
  float bLuma = bC ? (red(srcBlack) + green(srcBlack) + blue(srcBlack)) / 3f : 0;
  float wFac[] = new float[3];
  float bFac[] = new float[3];
  for (int i = 0; i < 3; i++) {
    if(wC) wFac[i] = wLuma / ((srcWhite >> 8*(2-i))&0xFF) - 1;
    if(bC) bFac[i] = (255-bLuma) / (255-((srcBlack >> 8*(2-i))&0xFF)) - 1;
  }
  
  printArray(bFac);
  
  for(int p = 0; p < o.pixels.length; p++){
    color c = o.pixels[p];
    int r = c >> 16 & 0xFF, g = c >> 8 & 0xFF, b = c >> 0 & 0xFF, a = c & 0xff000000; // Separate channels (and shift the color channels to LSB)
    
    float dr = r*wFac[0] -(255-r)*bFac[0];;
    float dg = g*wFac[1] -(255-g)*bFac[1];;
    float db = b*wFac[2] -(255-b)*bFac[2];;
    
    r = brick255(r + dr - (dg+db)/4) <<16 & 0x00FF0000; // Colorcombine the channels and shift the color back from LSB to b17 - b24
    g = brick255(g + dg - (dr+db)/4) <<8  & 0x0000FF00; // Colorcombine the channels and shift the color back from LSB to b9 - b16
    b = brick255(b + db - (dr+dg)/4)      & 0x000000FF; // Colorcombine the channels and shift the color back from LSB to b1 - b8
    
    o.pixels[p] = floor(r+g+b+a);
    //println(hex(o.pixels[p]));
  }
  o.updatePixels();
  return o;
}

int brick255(float n){
  return n > 255 ? 255 : (n < 0 ? 0 : floor(n));
}

void periodicUpdate(){
  while(mousePressed){
    src = loadImage(sourceDir + "/" + filenames[previewFrame]);
    delay(100);
  }
}

void mouseDragged(MouseEvent e) {
  if (abs(mouseX - wPickerP[0]) < (wRadius + 5) && abs(mouseY - wPickerP[1]) < (wRadius + 5) && wPickerP[1]-wRadius > 0) {
    wPickerP[0] += e.getX() - wPickerP[0];
    wPickerP[1] += e.getY() - wPickerP[1];
  }
  
  if (bCorrection && abs(mouseX - bPickerP[0]) < (bRadius + 5) && abs(mouseY - bPickerP[1]) < (bRadius + 5) && bPickerP[1]-bRadius > 0) {
    bPickerP[0] += e.getX() - bPickerP[0];
    bPickerP[1] += e.getY() - bPickerP[1];
  }
  
  if (abs(mouseX - width*previewFrame/frames) < 20 && mouseY > (height-50)) {
    previewFrame = mouseX*frames/width;
  }
}

void mouseReleased(){
   src = loadImage(sourceDir + "/" + filenames[previewFrame]);
}

void mouseWheel(MouseEvent e) {
  if(!keyPressed){
    if (wRadius >= 1) wRadius -= e.getCount();
    if (wRadius == 0) wRadius++;
  } else if(keyPressed && keyCode == SHIFT){
    if (bRadius >= 1) bRadius -= e.getCount();
    if (bRadius == 0) bRadius++;
  }
}

void mousePressed(MouseEvent e) {
  thread("periodicUpdate");
  
  if (!keyPressed && e.getButton() == RIGHT && mouseY < height-50) {
    wPickerP[0] = e.getX();
    wPickerP[1] = e.getY();
  } else if (keyPressed && keyCode == SHIFT && e.getButton() == RIGHT && mouseY < height-50) {
    bPickerP[0] = e.getX();
    bPickerP[1] = e.getY();
  }
  
  if (e.getButton() == RIGHT && mouseY > height-50) {
    previewFrame = mouseX*frames/width;
  }
}

void keyPressed(KeyEvent e) {
  if(key == 'w') wCorrect();    // w
  if(key == 'b') bCorrect();    // b
  if(key == ' ') correct();     // SPACE
  if(keyCode == 123) thread("render");        // F12
}

void correct(){
  wCorrect();
  bCorrect();
}

void wCorrect(){
  wCorrection = !wCorrection;
}

void bCorrect(){
  bCorrection = !bCorrection;
}

color sampleArea(PImage sample, int x, int y, int r) {
  sample.loadPixels();

  int rounds = (2*r)*(2*r);
  //println(rounds);
  long sum[] = new long[3];

  for (int i = x-r; i <= x+r; i++) for (int j = y-r; j <= y+r; j++) {
    int p = j*sample.width + i;
    sum[0] += red(sample.pixels[p]); //<>//
    sum[1] += green(sample.pixels[p]);
    sum[2] += blue(sample.pixels[p]);

    //sample.pixels[p] = color(0xFFFF0000); // Test for showing the actual pixels sampled in red
  }

  //sample.updatePixels(); // Test for showing the actual pixels sampled in red

  for (int i = 0; i < 3; i++) sum[i] = sum[i]/rounds;

  return color(sum[0], sum[1], sum[2]);
}
