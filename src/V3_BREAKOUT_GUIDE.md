# XAUUSD_EA v3.0 — Core (FADE) + Breakout Scalper (MOMENTUM)

## Kenapa v3 dibuat (kesimpulan dari backtest dual v2 Anda)
v2 (Core + Scalper-bayangan) hasil 5 tahun:
| | Core-only | Dual v2 |
|---|---|---|
| Net | $104 | $167 (+$62 dari Scalper) |
| Win rate | 47.3% | 54.0% |
| Trades | 55 | 111 |
| **Max DD** | **3.4%** | **9.0%** (naik 2.6x!) |

**Masalah v2:** Scalper entry di sinyal & arah yang SAMA dengan Core -> saat Core kalah,
Scalper ikut kalah -> risiko MENUMPUK. Profit naik tapi drawdown ikut meledak.

## Solusi v3: dua strategi BERKORELASI RENDAH
- **CORE** = mean-reversion (fade sweep, Variant D). Menang saat market ranging.
- **BREAKOUT** = momentum (ikut Break of Structure searah tren H4). Menang saat market TRENDING.

Keduanya menang di kondisi BERBEDA -> saat satu rugi, yang lain cenderung cuan ->
**drawdown saling meredam, bukan menumpuk.** Inilah prinsip portofolio strategi.
Breakout memakai deteksi BOS yang SUDAH ADA di StructureEngine Anda (bukan strategi karangan).

## Logika Breakout (Mesin B)
1. Ambil BOS event terbaru dari StructureEngine.
2. Filter: jarak break >= InpBoMinBreakATR (buang break lemah/palsu).
3. Filter tren (opsional): hanya breakout searah tren H4 (InpBoRequireTrend).
4. Entry MOMENTUM searah BOS: BOS bullish -> BUY, BOS bearish -> SELL.
5. TP 0.8 ATR / SL 0.8 ATR (RR 1:1, profit kecil cepat), exit 6 bar, risk 0.25%.
6. Anti-duplikat: 1 entry per BOS event.

## Cara uji (3 backtest, periode sama, real ticks, isi komisi)
1. **SET_v3_BreakoutOnly.set**  -> ukur PF MURNI modul breakout. Harus PF>1.0 agar layak.
2. **SET_v3_DUAL_Breakout.set** -> Core + Breakout (filter tren ON). Target utama.
3. **SET_v3_DUAL_BoNoTrend.set** -> Breakout tanpa filter tren (lebih banyak trade, lebih harian).

### Yang dibandingkan vs Core-only (PF 1.54, DD 3.4%, 55 trade):
- Apakah Net Profit naik?
- Apakah jumlah trade naik signifikan (lebih harian)?
- **Apakah Max DD TETAP rendah (< 6%)?** <- ini bukti korelasi rendah berhasil.
  - Jika DD tetap rendah & profit naik -> BERHASIL, breakout melengkapi core.
  - Jika DD ikut meledak -> breakout masih korelasi tinggi, matikan (InpEnableBreakout=false).

## Tuning Breakout
- `InpBoTP_ATR` / `InpBoSL_ATR`: RR. Naikkan TP utk profit/trade lebih besar (winrate turun).
- `InpBoMinBreakATR` (0.05-0.3): makin tinggi = makin selektif (buang break kecil).
- `InpBoRequireTrend`: false = lebih banyak trade harian, true = lebih berkualitas.
- `InpBoRiskPercent`: jaga kecil (0.1-0.5) selama fase uji.

## Pengaman tetap aktif
- Daily loss cap 3% equity.
- Maks 3 posisi serentak total.
- Magic terpisah (CORE_VarD=880118, BREAKOUT=880120) -> P&L terukur per mesin.

## Target realistis harian
v3 + filter tren OFF bisa naikkan trade signifikan. Untuk benar2 harian konsisten 1-2%/hari,
langkah final tetap MULTI-PAIR (jalankan v3 di XAUUSD+EURUSD+GBPUSD). Tapi buktikan v3
unggul di XAUUSD dulu.
