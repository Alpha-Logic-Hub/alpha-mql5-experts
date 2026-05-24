//+------------------------------------------------------------------+
//| Mathematical Filters — linear regression, angle, statistics       |
//+------------------------------------------------------------------+

void CalculateLinearRegression(int period, double &slope, double &rSquared)
{
   slope = 0;
   rSquared = 0;
   int n = period;
   if(n <= 2 || iBars(_Symbol, _Period) < n) return;

   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

   for(int i = 0; i < n; i++) {
      double y = iClose(_Symbol, _Period, i + 1);
      double x = n - i;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
   }

   double numSlope = (n * sumXY) - (sumX * sumY);
   double denSlope = (n * sumX2) - (sumX * sumX);

   if(denSlope != 0) {
      slope = numSlope / denSlope;
   }

   double numR = numSlope;
   double denR = (n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY);
   if(denR > 0) {
      rSquared = (numR * numR) / denR;
   }
}

void CalculateLinearRegressionCustom(int period, int startShift, double &slope, double &rSquared)
{
   slope = 0;
   rSquared = 0;
   int n = period;
   if(n <= 2 || iBars(_Symbol, _Period) < n + startShift) return;

   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

   for(int i = 0; i < n; i++) {
      double y = iClose(_Symbol, _Period, i + startShift);
      double x = n - i;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
   }

   double numSlope = (n * sumXY) - (sumX * sumY);
   double denSlope = (n * sumX2) - (sumX * sumX);

   if(denSlope != 0) {
      slope = numSlope / denSlope;
   }

   double numR = numSlope;
   double denR = (n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY);
   if(denR > 0) {
      rSquared = (numR * numR) / denR;
   }
}

double CalculateStdDev(int period)
{
   int n = period;
   if(n <= 1 || iBars(_Symbol, _Period) < n) return 0;

   double sum = 0;
   for(int i = 0; i < n; i++) {
      sum += iClose(_Symbol, _Period, i + 1);
   }
   double mean = sum / n;

   double sumSqDiff = 0;
   for(int i = 0; i < n; i++) {
      double diff = iClose(_Symbol, _Period, i + 1) - mean;
      sumSqDiff += diff * diff;
   }

   return MathSqrt(sumSqDiff / n);
}

double CalculateSlopeAngle(double slopeVal, double atrVal)
{
   if(atrVal <= 0) return 0;

   double normalizedSlope = slopeVal / atrVal;
   double angleRad = MathArctan(normalizedSlope);
   double angleDeg = angleRad * 180.0 / M_PI;

   return angleDeg;
}
