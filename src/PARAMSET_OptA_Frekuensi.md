# Opsi A — Naikkan Frekuensi Trade (tanpa ubah kode)

Tujuan: menambah jumlah trade dengan melonggarkan filter, lalu **membuktikan** edge tetap positif.
Semua perubahan = ganti INPUT di Strategy Tester. Backtest **XAUUSD M30, 2022.01.01–2025.12.31**, real ticks, real spread, **isi komisi broker Anda**.

> Catatan: di backtest Anda InpVariantMode=0 (Variant A) — efficiency filter SUDAH off.
> Jadi pembatas utama frekuensi sekarang = Trend Gate + Rejection Margin.

---

## SET 0 — BASELINE (yang sudah Anda jalankan)
Pakai sebagai pembanding. Hasil 2022–2025: 55 trade, PF 1.32, Net +$669.
```
InpVariantMode           = 0     (Variant A baseline)
InpEnableTrendGate       = true
InpMinRejectionMarginATR = 0.50
```

## SET 1 — LONGGAR RINGAN  (matikan Trend Gate saja)
Izinkan fade dua arah (lawan & searah tren). Biasanya naikkan trade paling signifikan.
```
InpVariantMode           = 0
InpEnableTrendGate       = false   <-- diubah
InpMinRejectionMarginATR = 0.50
```

## SET 2 — LONGGAR SEDANG  (Trend Gate off + rejection turun)
Tambah sinyal dengan rejection lebih kecil.
```
InpVariantMode           = 0
InpEnableTrendGate       = false
InpMinRejectionMarginATR = 0.30   <-- diubah
```

## SET 3 — AGRESIF  (paling banyak sinyal)
```
InpVariantMode           = 0
InpEnableTrendGate       = false
InpMinRejectionMarginATR = 0.20   <-- diubah
```

---

## Cara membaca hasil (PENTING — ini inti pembuktiannya)
Untuk tiap SET, catat 4 angka ini:

| SET | Total Trades | Profit Factor | Net Profit | Max DD % |
|-----|-------------|---------------|------------|----------|
| 0 (baseline) | 55 | 1.32 | +669 | 4.73% |
| 1 | ?  | ?  | ?  | ?  |
| 2 | ?  | ?  | ?  | ?  |
| 3 | ?  | ?  | ?  | ?  |

### Aturan keputusan:
- **PILIH set dengan trade TERBANYAK yang PF-nya MASIH > 1.15.**
- Jika melonggarkan filter membuat **PF turun di bawah 1.0** → STOP, set itu merusak edge. Mundur ke set sebelumnya.
- Jangan tergiur trade banyak kalau PF jatuh. Trade banyak + PF<1 = bakar akun lebih cepat.

## Ekspektasi realistis
- Set 1–3 mungkin naikkan trade dari ~14/tahun → ~30–60/tahun.
- Itu ~3–5 trade/bulan, BUKAN harian. Untuk harian sejati perlu Opsi B (timeframe turun) atau C (multi-pair) — tahap berikutnya.
