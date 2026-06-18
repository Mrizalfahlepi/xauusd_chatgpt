//+------------------------------------------------------------------+
//|                                       SessionBreakoutEngine.mqh   |
//|  MESIN C: SESSION RANGE BREAKOUT (scalper harian M5)            |
//+------------------------------------------------------------------+
//| LOGIKA (referensi scalper pro London-NY overlap):               |
//|   1. Tiap hari, hitung HIGH/LOW range sesi Asia (22:00-06:00     |
//|      UTC server). Ini "kotak" likuiditas semalam.               |
//|   2. HANYA cari entry di window overlap London-NY (12:00-16:00   |
//|      UTC) -> ~60-65% range harian emas terjadi di sini.         |
//|   3. Entry saat candle M5 CLOSE tembus boundary range + jarak    |
//|      tembus minimum (buang false-break tipis).                  |
//|   4. SL ketat (di sisi seberang break), TP cepat (R:R ~1:1.2).  |
//|   5. Maks 1 trade arah-sama per hari per sisi (anti over-trade). |
//|                                                                  |
//| KORELASI RENDAH: pemicunya murni TIME-OF-DAY + range Asia,       |
//|   beda total dari Core (sweep struktural) & Breakout (BOS H4).  |
//+------------------------------------------------------------------+
#ifndef __SESSION_BREAKOUT_ENGINE_MQH__
#define __SESSION_BREAKOUT_ENGINE_MQH__

struct SessionBreakoutSignal
{
   bool   isValid;
   bool   isBuy;
   double entryRef;   // harga acuan (close M5 yang tembus)
   double slPrice;
   double tpPrice;
   string reason;
};

class CSessionBreakoutEngine
{
private:
   // Param (di-set dari EA)
   int    m_asiaStartHour;   // 22
   int    m_asiaEndHour;     // 6
   int    m_winStartHour;    // 12
   int    m_winEndHour;      // 16
   double m_minBreakUSD;     // jarak tembus minimum (USD harga)
   double m_slBufferUSD;     // buffer SL di luar range (USD)
   double m_rr;              // risk:reward (TP = SL*rr)
   double m_atrSLcap;        // batas SL maksimum = x * ATR (proteksi)

   // State harian
   datetime m_curDay;
   double   m_asiaHigh, m_asiaLow;
   bool     m_rangeReady;
   bool     m_boughtToday, m_soldToday;

   datetime DayOf(datetime t) { return (datetime)((long)t - ((long)t % 86400)); }

   int HourOf(datetime t)
   {
      MqlDateTime st; TimeToStruct(t, st); return st.hour;
   }

   // Apakah jam tersebut termasuk window Asia (boleh lintas tengah malam)
   bool InAsia(int h)
   {
      if(m_asiaStartHour <= m_asiaEndHour)
         return (h >= m_asiaStartHour && h < m_asiaEndHour);
      return (h >= m_asiaStartHour || h < m_asiaEndHour); // 22..6 lintas hari
   }
   bool InWindow(int h) { return (h >= m_winStartHour && h < m_winEndHour); }

public:
   void Configure(int asiaStart,int asiaEnd,int winStart,int winEnd,
                  double minBreakUSD,double slBufferUSD,double rr,double atrSLcap)
   {
      m_asiaStartHour=asiaStart; m_asiaEndHour=asiaEnd;
      m_winStartHour=winStart;   m_winEndHour=winEnd;
      m_minBreakUSD=minBreakUSD;  m_slBufferUSD=slBufferUSD;
      m_rr=rr;                    m_atrSLcap=atrSLcap;
   }

   void Init()
   {
      m_curDay=0; m_asiaHigh=0; m_asiaLow=0; m_rangeReady=false;
      m_boughtToday=false; m_soldToday=false;
   }

   // Reset state saat hari baru
   void NewDayCheck(datetime now)
   {
      datetime d = DayOf(now);
      if(d != m_curDay)
      {
         m_curDay=d; m_rangeReady=false;
         m_asiaHigh=0; m_asiaLow=0;
         m_boughtToday=false; m_soldToday=false;
      }
   }

   // Hitung range Asia dari bar M5 (dipanggil sekali saat masuk window)
   bool ComputeAsiaRange(datetime now)
   {
      double hi=-DBL_MAX, lo=DBL_MAX; int found=0;
      // Scan ~300 bar M5 ke belakang (24 jam), ambil yang jamnya di window Asia & hari ini/kemarin sesi terdekat
      int bars = 320;
      datetime today = DayOf(now);
      for(int i=1;i<=bars;i++)
      {
         datetime bt = iTime(_Symbol, PERIOD_M5, i);
         if(bt==0) break;
         // hanya bar dalam 24 jam terakhir
         if(now - bt > 24*3600) break;
         int h = HourOf(bt);
         if(!InAsia(h)) continue;
         double bh = iHigh(_Symbol, PERIOD_M5, i);
         double bl = iLow(_Symbol, PERIOD_M5, i);
         if(bh>hi) hi=bh;
         if(bl<lo) lo=bl;
         found++;
      }
      if(found < 5 || hi<=lo) return false;
      m_asiaHigh=hi; m_asiaLow=lo; m_rangeReady=true;
      return true;
   }

   // Evaluasi sinyal pada CLOSE bar M5 terakhir (index 1 = bar baru saja close)
   SessionBreakoutSignal Evaluate(datetime now, double atr)
   {
      SessionBreakoutSignal s; s.isValid=false; s.isBuy=false;
      s.entryRef=0; s.slPrice=0; s.tpPrice=0; s.reason="";

      NewDayCheck(now);
      int h = HourOf(now);
      if(!InWindow(h)) return s;                 // hanya jam overlap
      if(!m_rangeReady) { if(!ComputeAsiaRange(now)) return s; }
      if(m_asiaHigh<=m_asiaLow) return s;

      double c1 = iClose(_Symbol, PERIOD_M5, 1); // close bar M5 terakhir
      if(c1<=0) return s;

      // BUY: close tembus di atas Asia high + jarak minimum
      if(!m_boughtToday && c1 > m_asiaHigh + m_minBreakUSD)
      {
         double sl = m_asiaLow - m_slBufferUSD;          // SL di sisi seberang range
         double slDist = c1 - sl;
         // cap SL agar tidak kebesaran (proteksi): pakai max(atrSLcap*atr)
         if(m_atrSLcap>0 && atr>0 && slDist > m_atrSLcap*atr)
            sl = c1 - m_atrSLcap*atr, slDist = c1 - sl;
         if(slDist<=0) return s;
         s.isValid=true; s.isBuy=true; s.entryRef=c1;
         s.slPrice=sl; s.tpPrice=c1 + slDist*m_rr;
         s.reason="ASIA_BO_UP";
         return s;
      }
      // SELL: close tembus di bawah Asia low - jarak minimum
      if(!m_soldToday && c1 < m_asiaLow - m_minBreakUSD)
      {
         double sl = m_asiaHigh + m_slBufferUSD;
         double slDist = sl - c1;
         if(m_atrSLcap>0 && atr>0 && slDist > m_atrSLcap*atr)
            sl = c1 + m_atrSLcap*atr, slDist = sl - c1;
         if(slDist<=0) return s;
         s.isValid=true; s.isBuy=false; s.entryRef=c1;
         s.slPrice=sl; s.tpPrice=c1 - slDist*m_rr;
         s.reason="ASIA_BO_DN";
         return s;
      }
      return s;
   }

   void MarkTraded(bool isBuy) { if(isBuy) m_boughtToday=true; else m_soldToday=true; }

   double AsiaHigh() { return m_asiaHigh; }
   double AsiaLow()  { return m_asiaLow; }
};

#endif
