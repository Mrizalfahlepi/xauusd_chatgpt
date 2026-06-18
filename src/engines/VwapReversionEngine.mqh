//+------------------------------------------------------------------+
//|                                         VwapReversionEngine.mqh   |
//|  MESIN D: VWAP MEAN-REVERSION (scalper harian M5)              |
//+------------------------------------------------------------------+
//| LOGIKA (referensi scalper pro VWAP reversion):                  |
//|   1. Hitung VWAP sesi harian (reset tiap hari, akumulasi        |
//|      typical price * tick-volume dari bar M5).                  |
//|   2. Hitung deviasi standar harga thd VWAP -> band SD.          |
//|   3. FADE: kalau harga melar >= bandSD * SD di ATAS VWAP -> SELL|
//|      (target balik ke VWAP). Di BAWAH -> BUY.                   |
//|   4. FILTER REZIM WAJIB: kalau ADX(M5) > maxADX -> pasar        |
//|      trending kuat, MATIKAN reversion (di sinilah ia gagal).    |
//|   5. TP = VWAP (mean), SL = bandSD lebih jauh (stopMult*SD).    |
//|                                                                  |
//| KORELASI RENDAH: ini fade thd VWAP intraday + filter ADX,       |
//|   beda dari Core (fade sweep struktural H4/M30) & lainnya.      |
//+------------------------------------------------------------------+
#ifndef __VWAP_REVERSION_ENGINE_MQH__
#define __VWAP_REVERSION_ENGINE_MQH__

struct VwapReversionSignal
{
   bool   isValid;
   bool   isBuy;
   double entryRef;
   double slPrice;
   double tpPrice;
   string reason;
};

class CVwapReversionEngine
{
private:
   double m_bandSD;     // ambang deviasi untuk entry (mis. 1.8)
   double m_stopSD;     // SL = stopSD * SD dari harga (mis. 2.8)
   double m_maxADX;     // matikan reversion bila ADX > ini (mis. 25)
   int    m_adxPeriod;  // 14
   int    m_winStartHour, m_winEndHour; // jam aktif (boleh seharian)

   int    m_adxHandle;
   datetime m_curDay;

   // Akumulator VWAP sesi
   double m_sumPV;   // sum(typical*vol)
   double m_sumV;    // sum(vol)
   double m_sumP2V;  // sum(typical^2 * vol) untuk varians berbobot
   int    m_count;
   datetime m_lastBarProcessed;

   datetime DayOf(datetime t){ return (datetime)((long)t-((long)t%86400)); }
   int HourOf(datetime t){ MqlDateTime st; TimeToStruct(t,st); return st.hour; }
   bool InWindow(int h){ if(m_winStartHour==m_winEndHour) return true; return (h>=m_winStartHour && h<m_winEndHour); }

   void ResetSession()
   {
      m_sumPV=0; m_sumV=0; m_sumP2V=0; m_count=0;
   }

public:
   void Configure(double bandSD,double stopSD,double maxADX,int adxPeriod,int winStart,int winEnd)
   {
      m_bandSD=bandSD; m_stopSD=stopSD; m_maxADX=maxADX; m_adxPeriod=adxPeriod;
      m_winStartHour=winStart; m_winEndHour=winEnd;
   }

   bool Init()
   {
      m_curDay=0; ResetSession(); m_lastBarProcessed=0;
      m_adxHandle = iADX(_Symbol, PERIOD_M5, m_adxPeriod);
      if(m_adxHandle==INVALID_HANDLE) { Print("VWAP: ADX handle gagal"); return false; }
      return true;
   }
   void Deinit(){ if(m_adxHandle!=INVALID_HANDLE) IndicatorRelease(m_adxHandle); }

   double CurrentADX()
   {
      double buf[]; if(CopyBuffer(m_adxHandle,0,1,1,buf)<=0) return -1.0;
      return buf[0];
   }

   // Update akumulator VWAP dengan bar M5 yang baru close (index 1)
   void UpdateVWAP(datetime now)
   {
      datetime d = DayOf(now);
      if(d != m_curDay) { m_curDay=d; ResetSession(); m_lastBarProcessed=0; }

      datetime bt = iTime(_Symbol, PERIOD_M5, 1);
      if(bt==0 || bt==m_lastBarProcessed) return; // sudah diproses
      m_lastBarProcessed = bt;

      double hi=iHigh(_Symbol,PERIOD_M5,1);
      double lo=iLow(_Symbol,PERIOD_M5,1);
      double cl=iClose(_Symbol,PERIOD_M5,1);
      double tp=(hi+lo+cl)/3.0;                       // typical price
      double v=(double)iTickVolume(_Symbol,PERIOD_M5,1);
      if(v<=0) v=1.0;
      m_sumPV  += tp*v;
      m_sumV   += v;
      m_sumP2V += tp*tp*v;
      m_count++;
   }

   double VWAP(){ return (m_sumV>0)? m_sumPV/m_sumV : 0.0; }
   double SD()
   {
      if(m_sumV<=0 || m_count<2) return 0.0;
      double mean=m_sumPV/m_sumV;
      double var=(m_sumP2V/m_sumV) - mean*mean;
      if(var<0) var=0;
      return MathSqrt(var);
   }

   VwapReversionSignal Evaluate(datetime now)
   {
      VwapReversionSignal s; s.isValid=false; s.isBuy=false;
      s.entryRef=0; s.slPrice=0; s.tpPrice=0; s.reason="";

      UpdateVWAP(now);

      int h=HourOf(now);
      if(!InWindow(h)) return s;
      if(m_count < 12) return s;            // butuh data sesi cukup (>=1 jam M5)

      double vwap=VWAP(), sd=SD();
      if(vwap<=0 || sd<=0) return s;

      // FILTER REZIM: jangan fade saat trending kuat
      double adx=CurrentADX();
      if(adx<0) return s;
      if(adx > m_maxADX) return s;

      double price=iClose(_Symbol,PERIOD_M5,1);
      if(price<=0) return s;
      double dev=(price - vwap)/sd;          // berapa SD dari VWAP

      // Harga jauh DI ATAS VWAP -> fade SELL, target balik ke VWAP
      if(dev >= m_bandSD)
      {
         s.isValid=true; s.isBuy=false; s.entryRef=price;
         s.tpPrice=vwap;
         s.slPrice=vwap + m_stopSD*sd;       // SL di atas, lebih jauh
         s.reason="VWAP_FADE_SELL";
         return s;
      }
      // Harga jauh DI BAWAH VWAP -> fade BUY
      if(dev <= -m_bandSD)
      {
         s.isValid=true; s.isBuy=true; s.entryRef=price;
         s.tpPrice=vwap;
         s.slPrice=vwap - m_stopSD*sd;
         s.reason="VWAP_FADE_BUY";
         return s;
      }
      return s;
   }
};

#endif
