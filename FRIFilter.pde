class FRIFilter {
  double[] coefficients;
  int offset;
  double center;
  double[] curSamples;
  
  FRIFilter(double[] coefficients) {
    this.coefficients = coefficients;
    offset = coefficients.length - 1;
    center = Math.floor(coefficients.length / 2);
    curSamples = new double[offset];
  }
  
  void loadSamples(double[] samples) {
    double[] newSamples = new double[samples.length + offset];

    double[] subCurSamples = (double[]) subset(curSamples, curSamples.length - offset);
    arrayCopy(subCurSamples, newSamples);
    arrayCopy(samples, 0, newSamples, offset, samples.length);
    
    curSamples = newSamples;
  }
  
  double get(int index) {
    double value = 0;
    
    for (int i = 0 ; i < coefficients.length ; i++) {
      value += coefficients[i] * curSamples[index + i];
    }
    return value;
  }
}
