-- Data contoh untuk demo. Jalankan setelah schema.sql; hapus sebelum penggunaan nyata.
insert into public.members(member_no,full_name,member_type,class_name,email) values
 ('MUR-2026-0001','Nadia Contoh','Murid','VII A','nadia@example.sch.id'),
 ('GRU-2026-0001','Budi Contoh','Guru','Bahasa Indonesia','budi@example.sch.id') on conflict(member_no) do nothing;
insert into public.items(inventory_code,title,creator,kind,isbn,publisher,publish_year,category,location) values
 ('KOL-2026-0001','Laskar Pelangi','Andrea Hirata','Buku','9789793062792','Bentang Pustaka',2005,'Fiksi','Rak A-01'),
 ('KOL-2026-0002','Ensiklopedia Sains','Tim Redaksi','Buku',null,'Pustaka Ilmu',2022,'Referensi','Rak B-02'),
 ('KOL-2026-0003','Globe Dunia','Penerbit Edukasi','Media',null,null,null,'Geografi','Lemari Media 1'),
 ('KOL-2026-0004','Model Tata Surya','Lab IPA','Alat peraga',null,null,null,'IPA','Lemari IPA 2') on conflict(inventory_code) do nothing;
insert into public.copies(item_id,barcode,condition,status)
select i.id,v.barcode,'Baik','Tersedia' from (values ('KOL-2026-0001','INV-2026-0001'),('KOL-2026-0001','INV-2026-0002'),('KOL-2026-0002','INV-2026-0003'),('KOL-2026-0003','INV-2026-0004'),('KOL-2026-0004','INV-2026-0005')) as v(code,barcode)
join public.items i on i.inventory_code=v.code on conflict(barcode) do nothing;
