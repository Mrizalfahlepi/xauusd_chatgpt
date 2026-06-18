# XAUUSD_EA v4.0 — Panduan Backtest QUAD Strategy

EA v4 menambah **dua mesin aktivitas harian di timeframe M5** ke atas v3:

| Mesin | Tipe | TF | Pemicu | Magic | Tujuan |
|---|---|---|---|---|---|
| A — Core | FADE liquidity sweep (Variant D) | M30 | sweep gagal | 880118 | edge berkualitas, jarang |
| B — Breakout | MOMENTUM ikut BOS H4 | M30 | BOS searah tren | 880120 | edge trending, jarang |
| **C — Session** | **RANGE BREAKOUT sesi Asia** | **M5** | close tembus range Asia di overlap London-NY 12-16 UTC | **880122** | **aktivitas HARIAN** |
| **D — VWAP** | **MEAN-REVERSION thd VWAP** | **M5** | harga melar ≥1.8 SD dari VWAP + ADX<28 | **880124** | **aktivitas HARIAN** |

Filosofi tetap sama: **4 strategi berkorelasi rendah**. A & B = edge jarang tapi berkualitas. C & D = sinyal harian di TF kecil. Karena pemicunya beda-beda (sweep struktural vs BOS H4 vs time-of-day range vs VWAP intraday), drawdown saling meredam, bukan menumpuk.

---

## ATURAN PALING PENTING: in-sample vs out-of-sample

Pelajaran dari backtest 2026 kemarin: **angka in-sample selalu lebih bagus dari kenyataan.** Jadi disiplin ini WAJIB:

- **TUNING / OPTIMASI** → HANYA pakai data **2021-01-01 s/d 2025-12-31** (in-sample).
- **VALIDASI** → pakai data **2026** TERPISAH, dan **JANGAN PERNAH** ubah parameter berdasarkan hasil 2026.
- Kalau hasil 2026 (OOS) mirip hasil 2021-2025 → strategi sehat & layak demo.
- Kalau hasil 2026 jauh lebih jelek → strategi overfit, jangan dipakai live.

Data 2026 itu "ujian akhir" yang cuma boleh dilihat sekali. Begitu kamu nge-tweak parameter biar 2026 bagus, kamu sudah mencurangi ujian sendiri.

---

## Urutan backtest yang benar (periode 2021-2025)

Selalu set di Strategy Tester:
- Symbol: **XAUUSDm**, Timeframe chart: **M5** (penting — EA evaluasi mesin C/D per bar M5)
- Model: **Every tick based on real ticks**
- **Commission: isi manual ~$3.5-7 per lot per sisi** (Exness). Jangan biarkan 0 — scalper M5 paling sensitif komisi.

| Langkah | Preset | Tujuan |
|---|---|---|
| 1 | `SET_v4_SessionOnly.set` | Apakah mesin C (Session) profitable SENDIRI? PF harus >1.2 |
| 2 | `SET_v4_VwapOnly.set` | Apakah mesin D (VWAP) profitable SENDIRI? PF harus >1.2 |
| 3 | `SET_v4_v3plusSession.set` | v3 juara + Session (tambahan teraman) |
| 4 | `SET_v4_QUAD_Full.set` | 4 mesin penuh — paling banyak trade |

**Cara baca:** bandingkan tiap preset dengan baseline v3 (`SET_v3_DUAL_Breakout`, net $305 / PF 1.47 / DD 4% / 257 trade in-sample).
- Naik trade + PF tetap ≥1.3 + DD tetap < ~7% → **bagus, mesin baru menambah nilai.**
- Trade naik tapi PF anjlok <1.2 atau DD meledak → **mesin itu numpuk risiko, matikan.**

Mesin yang gagal isolasi (langkah 1/2) JANGAN dimasukkan ke QUAD. Kill-switch: set `InpEnableSession=false` atau `InpEnableVwap=false`.

---

## Setelah lolos in-sample

1. Jalankan **preset terbaik** sekali di periode **2026** (OOS) — catat, jangan tuning.
2. Kalau OOS konsisten → **forward-test demo 4-8 minggu** dengan komisi & spread real.
3. Risiko tiap mesin scalper tetap kecil (0.25%) selama validasi.

## Catatan teknis
- Jam di EA mengikuti **jam server broker** (Exness biasanya GMT+0/+2/+3). Kalau range Asia/overlap meleset, sesuaikan `InpSessAsiaStart/End` & `InpSessWinStart/End` ke jam server-mu.
- Mesin C maks 1 buy + 1 sell per hari (anti over-trade). Mesin D maks 1 posisi sekaligus.
- `InpMaxTotalPositions=4` memberi ruang ke-4 mesin; turunkan kalau mau lebih konservatif.

Referensi strategi: [Trading on MT5 — London-NY overlap gold scalp](https://www.tradingonmt5.com/london-ny-gold-scalp), [CrossTrade — VWAP reversion](https://crosstrade.io/learn/trading-strategies/vwap-reversion).
