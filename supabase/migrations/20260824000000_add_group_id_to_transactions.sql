-- Menambahkan group_id untuk menautkan mutasi transfer (debit, kredit)
-- dan biaya admin ke dalam satu grup transaksi.
-- Jalankan di Supabase SQL Editor SEBELUM menggunakan fitur transfer baru.
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS group_id text;

CREATE INDEX IF NOT EXISTS idx_transactions_group_id ON public.transactions (group_id);
