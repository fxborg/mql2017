//+------------------------------------------------------------------+
//|                                                GannSwingBars.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  DodgerBlue,Red
#property indicator_width1 2

int CalcBars=10;
input int ReverseBars=2;

double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double TrendBuffer[];
double ColorBuffer[];

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=CalcBars+2;
//--- indicator buffers mapping
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,TrendBuffer,INDICATOR_CALCULATIONS);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);
//---

   first=CalcBars+ReverseBars;

   if(first+1<prev_calculated)
      first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      //---
      OpenBuffer[i]=open[i];
      HighBuffer[i]=high[i];
      LowBuffer[i]=low[i];
      CloseBuffer[i]=close[i];
      double trend=TrendBuffer[i-1];
      gannswing(trend,high,low,close,i);
      TrendBuffer[i]=trend;
      ColorBuffer[i]=(TrendBuffer[i]>=0) ? 0: 1;
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void gannswing(double  &trend,const double  &h[],const double  &l[],const double  &c[],const int i)
  {
// inside bar
   if(h[i-1]>=h[i] && l[i-1] <= l[i]) return;

   bool isOutSide  = (h[i-1] <  h[i]   && l[i-1] >  l[i]);
   bool prevInSide = (h[i-2] >= h[i-1] && l[i-2] <= l[i-1]);
   bool isUpClose  = h[i-1] < c[i];
   bool isDnClose  = l[i-1] > c[i];
   bool isHigh     = h[i-1] < h[i];
   bool isLow      = l[i-1] > l[i];


// first time only
   if(trend==0.0)trend=1.0;

   if(trend>0.0) // Up Trend 
     {
      double dmin=l[ArrayMinimum(l,i-ReverseBars,ReverseBars)];
      if((isOutSide && dmin>c[i]) || (!isOutSide && dmin>l[i]))
        {
         trend=-ReverseBars;
         return;
        }
      // up or not enough down...
      else if(trend>1.0)
        {
         if((isOutSide && isUpClose) || (!isOutSide && isLow))
           {
            trend--;
            return;
           }
        }
      // enough down
      else if(trend==1.0)
        {
         if((isOutSide && prevInSide) || (!isOutSide && isLow))
           {
            trend=-ReverseBars;
            return;
           }
        }
     }
   else if(trend<0.0) // Down Trend
     {
      double dmax=h[ArrayMaximum(h,i-ReverseBars,ReverseBars)];
      if((isOutSide && dmax<c[i]) || (!isOutSide && dmax<h[i]))
        {
         trend=ReverseBars;
         return;
        }
      // down or not enough up
      if(trend<-1.0)
        {
         if((isOutSide && isDnClose) || (!isOutSide && isHigh))
           {
            trend++;
            return;
           }
        }
      // dnough up
      else if(trend==-1.0)
        {
         if((isOutSide && prevInSide) || (!isOutSide && isHigh))
           {
            trend=ReverseBars;
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+
