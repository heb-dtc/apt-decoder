class DownSampler {

  FRIFilter filter;
  float rateMul;
  
  DownSampler(int inRate, int outRate, double[] coefficients) {
    filter = new FRIFilter(coefficients);
    rateMul = inRate / outRate;
  }
  
  double[] downSample(double[] samples) {
    filter.loadSamples(samples);
    double[] out = new double[(int) Math.floor(samples.length / rateMul)];
    
    for (int i = 0, readFrom = 0; i < out.length; ++i, readFrom += rateMul) {
      out[i] = filter.get((int) Math.floor(readFrom));
    }
    
    return out;
  }
}
