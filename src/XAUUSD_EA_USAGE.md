# XAUUSD_EA v1.0 — EA Nyata Pertama (Liquidity-Sweep Fade, Variant D)

## Apa yang berubah dari TestEntry.mq5
| Aspek | TestEntry.mq5 (lama) | XAUUSD_EA.mq5 (baru) |
|---|---|---|
| Eksekusi | Catat trade virtual ke array | `OrderSend()` NYATA via CTrade |
| Lot | Tidak ada (hanya ATR) | Dihitung dari **1% risk** equity |
| P&L | Murni gerak harga (ATR) | Uang nyata, kena spread/komisi/swap/slippage |
| SL/TP | Disimulasikan di array | Dipasang di server (server-side SL/TP) |
| Forced exit 12 bar | Cek array | `PositionClose()` nyata |
| Guard biaya | Tidak ada | Skip entry bila spread > `InpMaxSpreadPoints` |

Pipeline engine (Structure → SD → Snr → Priority → Liquidity → Entry) **TIDAK diubah** — dipanggil dengan signature identik. Strategi entry sama persis dengan yang Anda validasi.

## Setup wajib sebelum jalan
1. **EntryEngine variant**: set `InpVariantMode = VARIANT_D_EFF_OUTSIDE` (Variant D). Ini parameter input EntryEngine, bukan EA.
2. Letakkan `XAUUSD_EA.mq5` di `MQL5/Experts/`, dan folder `engines/` relatif terhadapnya (sesuai `#include "engines/..."`). Atau sesuaikan path include ke lokasi Anda.

## Cara backtest JUJUR (ini yang mengubah "fana" → realita)
Strategy Tester:
- Symbol: **XAUUSD**, Timeframe: **M30**, Period: **2022–2025**
- Modeling: **"Every tick based on real ticks"** (bukan "Open prices only")
- **Use real spread** (centang) — atau set spread manual sesuai broker (XAUUSD sering 15–30 cent)
- Set **komisi & swap** broker Anda di properti simbol
- Deposit awal realistis (mis. sesuai akun riil Anda)

## Yang harus Anda lihat di hasil
- **Net Profit setelah biaya** — bukan ATR. Apakah masih positif?
- **Profit Factor** real (target > 1.2 setelah biaya agar layak)
- **Max Drawdown %** — apakah Anda sanggup menahannya?
- Bandingkan dengan ekspektasi lama (+0.27 ATR/trade). Jika edge hilang setelah biaya → itu temuan PENTING, bukan kegagalan.

## Tahap selanjutnya (setelah backtest)
1. Jika PF > 1.2 setelah biaya → **demo forward test 4–8 minggu**.
2. Bila demo konsisten → live dengan risk kecil (0.5%).
3. Jangan tambah engine/filter baru sebelum tahap ini lulus.

## Catatan risiko jujur
Win rate ~19% berarti psikologis berat (banyak loss beruntun itu normal). RR 1:2 membuatnya tetap bisa profit secara matematis, TAPI hanya jika edge bertahan setelah biaya. Backtest jujur ini yang akan menjawabnya.
