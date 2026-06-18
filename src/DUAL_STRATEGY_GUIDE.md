# XAUUSD_EA v2.0 — Dual-Strategy (Core Variant D + Daily Scalper)

## Ringkasan keputusan (berdasarkan backtest 5 tahun Anda)
Data Anda membuktikan: makin banyak trade dipaksa lewat pelonggaran filter, makin hancur edge.
| Set | Trades | PF | Net | Max DD |
|-----|--------|----|----|--------|
| SETD (Variant D) | 55 | **1.49** | $95 | **3.43%** |
| SET1 | 81 | 1.34 | $106 | 5.02% |
| SET0 | 67 | 1.24 | $64 | 5.20% |
| SET2 | 164 | 1.03 | $17 | 9.79% |
| SET3 | 224 | 1.02 | $16 | 13.67% |

**Kesimpulan: Variant D = fondasi terbaik.** Maka v2.0 mempertahankan D sebagai inti,
dan menambah modul Scalper TERPISAH (tidak merusak D).

## Cara kerja v2.0
Satu sinyal Variant D yang valid memicu DUA posisi terpisah:
- **CORE** (magic 880118): TP 2.0 ATR, risk 1.0% -> mesin pertumbuhan akun (kualitas D).
- **SCALPER** (magic 880119): TP 0.7 ATR, risk 0.25%, exit cepat 6 bar -> "profit kecil sering".

Keduanya pakai filter Variant D yang SAMA. Scalper hanya beda exit + risk lebih kecil.

## Kenapa desain ini aman
1. **Magic terpisah** -> di laporan backtest, P&L Core vs Scalper bisa dipisah (filter kolom Comment: CORE_VarD vs SCALP).
2. **Kill-switch** -> kalau Scalper ternyata merugi, set `InpEnableScalper=false`. Core tetap jalan utuh.
3. **Risk Scalper kecil (0.25%)** -> walau salah, dampaknya 1/4 dari Core.
4. **Daily loss cap 3%** -> tidak ada satu hari pun yang bisa menghancurkan akun.

## Cara uji (WAJIB - bandingkan 2 backtest)
Jalankan DUA backtest, periode sama (XAUUSD M30, 2021-2025, real ticks, isi komisi):

1. **SET_CoreOnly_D.set**  -> baseline: hanya Core (harus ~ samai SETD: PF 1.49).
2. **SET_DUAL_CoreD_Scalper.set** -> Core + Scalper aktif.

### Pertanyaan yang dijawab perbandingan ini:
- Apakah DUAL menaikkan Net Profit & jumlah trade DIBANDING Core-only?
- Apakah PF total tetap sehat (> 1.2)?
- Pisahkan P&L Scalper (Comment=SCALP): apakah modul Scalper SENDIRI profit (PF>1.0)?
  - Jika SCALP profit -> pertahankan.
  - Jika SCALP rugi -> matikan (InpEnableScalper=false), pakai Core saja.

## Parameter Scalper yang bisa Anda tuning
- `InpScalpTP_ATR` (0.5 - 1.0): TP lebih kecil = winrate naik tapi profit/trade turun.
- `InpScalpRiskPercent` (0.1 - 0.5): jangan besar; ini modul eksperimen.
- `InpScalpMaxBars` (4 - 8): berapa cepat keluar.

## Realita "harian"
Scalper menambah 1 trade per sinyal Core, jadi frekuensi ~2x. Itu masih BUKAN puluhan
trade/hari. Untuk harian sejati perlu MULTI-PAIR: jalankan EA ini di beberapa simbol
(XAUUSD, EURUSD, GBPUSD...) -> peluang trade berlipat tanpa merusak edge per-pair.
Itu langkah berikutnya setelah dual-strategy terbukti.

## Setup wajib
- Modeling: "Every tick based on real ticks"
- Isi komisi & swap broker (akun XAUUSDm Exness biasanya komisi ~$3.5-7/lot/sisi)
- Bandingkan Net Profit SETELAH biaya, bukan sebelum.
