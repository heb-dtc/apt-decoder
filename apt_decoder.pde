import processing.sound.*;

String fileName = "";

float[] frames;
int numTaps = 50;
double signalMean = 0;
double[] coeffs = getLowPassFirCoeffs(11025, 1200, numTaps);

FRIFilter filter = new FRIFilter(coeffs);
double[] filteredData;

double[] getLowPassFirCoeffs(float sampleRate, float halfAmplFreq, int numTaps) {
  numTaps += (numTaps + 1) % 2;
  double freq = halfAmplFreq / sampleRate;
  double[] coefs = new double[numTaps];
  double center = Math.floor(numTaps / 2);
  float sum = 0;
 
  for (int i = 0 ; i < numTaps ; i++) {
    double val;
    if (i == center) {
      val = 2 * Math.PI * freq;
    } else {
      double angle = 2 * Math.PI * (i + 1) / (numTaps + 1);
      println("ANGLE -> "+ angle);
      val = Math.sin(2 * Math.PI * freq * (i - center)) / (i - center);
      val *= 0.42 - 0.5 * Math.cos(angle) + 0.08 * Math.cos(2 * angle);
      println("VAL -> "+ val);
    }
    sum += val;
    coefs[i] = val;
  }

  for (int i = 0; i < numTaps; ++i) {
    coefs[i] /= sum;
  }
  
  return coefs;  
}  

void setup() {
  size(1920, 1000);
  background(255);
   
  SoundFile file = new SoundFile(this, fileName);
  println(file.sampleRate());
  
  frames = new float[file.frames()];
  file.read(frames);
  
  for (int i=0 ; i < frames.length ; i++) {
    frames[i] = Math.abs(frames[i]);
  }
  
  filterSamples();
}

void normalize() {
  double maxVal = 0;
  double minVal = 1;
  
  for(int i = 0; i < filteredData.length; i++) {
    if(filteredData[i] > maxVal){
      maxVal = filteredData[i];
    }
    if(filteredData[i] < minVal){
      minVal = filteredData[i];
    }
  }
  
  for(int i = 0; i < filteredData.length; i++) {
    filteredData[i] = (filteredData[i] - minVal) / (maxVal - minVal);
    signalMean += filteredData[i];
  }
  
  signalMean = signalMean / filteredData.length;
}

void filterSamples() {
  double[] fs = new double[frames.length];
  for (int i=0 ; i < frames.length ; i++) {
    fs[i] = frames[i] / 32768;
  }
  
  filter.loadSamples(fs);
  
  filteredData = new double[fs.length];
  for (int i = 0 ; i < fs.length ; i++) {
    filteredData[i] = filter.get(i);
  }
  
  normalize();
  FloatDict map = convolveWithSync(0, 22050);
  createImage((int)map.get("index"));
}

FloatDict convolveWithSync(int start, int range) {
  int[] sync = { 
    -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, -1, -1, -1, 
    -1, -1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, -1, 
    -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, 1, 1, 1, 
    1, 1, 1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, 
    1, 1, 1, 1, 1
  };
  
  float maxVal = 0;
  float maxIndex = 0;
  
  for (int i = start; i < start + range; i++) {
    float sum = 0;
    
    for (int c = 0; c < sync.length; c++) {
      int index = i + c;
      // clamping the index
      if (index > filteredData.length) {
        index = filteredData.length - 1;
      }
      sum += (filteredData[index] - signalMean) * sync[c];
    }
    
    if (sum > maxVal) {
      maxVal = sum;
      maxIndex = i;
    }
  }
  
  FloatDict res = new FloatDict();
  res.set("index", maxIndex);
  res.set("score", maxVal);
  return res;
}

void createImage(int startingIndex) {
  int pixelScale = 2;
  
  int lineCount = (int) Math.floor(filteredData.length/5513) / pixelScale;
  PImage image = createImage(1040, lineCount, ARGB);
  image.loadPixels();
  
  int lineStartIndex = startingIndex;
  println(lineCount, " possible lines");
  
  DownSampler downSampler = new DownSampler(11025, 4160, coeffs);
  double[] lineData;
  
  for(int line = 0; line < lineCount; line++) {
    println("line -> " + line);
    println("lineStartIndex -> ", lineStartIndex);
    
    int stopIndex = lineStartIndex + 5533;
    
    // need to clamp to a valid index range...
    if (stopIndex >= filteredData.length) {
      stopIndex = filteredData.length - 1;
    }
    int startIndex = lineStartIndex + 20;
    int count = (stopIndex - startIndex) + 1;
    
    // need to clamp to a valid index range...
    if (count < 0) {
      startIndex = 0;
      count = 0;
    }
    
    println("count: ", count);
    double[] bla = (double[]) subset(filteredData, startIndex, count);
    lineData = downSampler.downSample(bla);
    
    for(int column = 0; column < 1040; column++) {
      int index = 0 + column * pixelScale;
      
      if (lineData.length > 0) { 
        if (index >= lineData.length) {
          index = lineData.length - 1;
        }
        double value = lineData[index] * 256;
        //println(value);
        
        image.pixels[line * 1040 + column] = color((int)value, (int)value, (int)value, 255);
      } else {
        image.pixels[line * 1040 + column] = color(0, 0, 0, 255);
      }
    }
    
    FloatDict conv = convolveWithSync(lineStartIndex + (5512 * pixelScale) - 20, 40);
    if(conv.get("score") > 6) {
      lineStartIndex = (int) conv.get("index");
    } else {
      lineStartIndex += 5512 * pixelScale;
    }
  }
  
  image.updatePixels();
  image(image, 0, 0);
}
