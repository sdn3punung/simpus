# SIMPUS — Sistem Manajemen Perpustakaan Sekolah

Frontend statis Bahasa Indonesia dengan Supabase Auth + PostgreSQL. Tidak memerlukan backend server terpisah. Database menjalankan akses berbasis peran, audit, constraint unik, dan RPC transaksi atomik. Frontend hanya memakai Supabase URL dan anon/publishable key; `service_role` tidak pernah dipasang di browser.

## Isi folder

- `index.html`, `app.js`, `styles.css`: aplikasi responsif.
- `config.js`: konfigurasi publik proyek Supabase.
- `supabase/schema.sql`: skema, indeks, audit trigger, RPC, dan RLS.
- `supabase/seed.sql`: data koleksi contoh.
- `templates/`: lokasi template XLSX bila ingin menaruh berkas tetap; aplikasi menyusun template per modul saat tombol diunduh.

## Cakupan versi awal

- **Pustakawan:** CRUD anggota, judul koleksi, eksemplar, peminjaman manual, persetujuan permintaan, pengembalian dan pencatatan kondisi, kunjungan, impor/ekspor, laporan, audit, kartu anggota, label barcode.
- **Kepala Sekolah:** dashboard baca saja, ringkasan koleksi dan laporan sirkulasi.
- **Guru/murid:** katalog, ketersediaan eksemplar, permintaan pinjam, serta riwayat sendiri. Akun anggota harus ditautkan ke satu baris anggota.
- Transaksi memakai status dan audit. UI mengarsipkan anggota/koleksi; riwayat peminjaman tetap dipertahankan.
- Barcode eksemplar Code 128 dan QR kartu memakai token acak tanpa data pribadi. Kartu dan label dapat dicetak per pilihan atau massal melalui dialog cetak browser, lalu disimpan sebagai PDF dari dialog tersebut.
- Template impor XLSX berisi sheet `Data` dan `Petunjuk`, judul kolom berbahasa Indonesia, contoh dan validasi pratinjau. Ekspor tersedia sebagai XLSX; laporan CSV menggunakan titik koma dan BOM untuk Excel Indonesia.

## Panduan deploy untuk pemula

Ikuti urutan ini. Siapkan folder proyek SIMPUS yang sudah diekstrak dari ZIP dan koneksi internet. Jangan unggah aplikasi ke hosting sebelum URL Supabase dimasukkan ke `config.js`.

### A. Buat database Supabase

Dokumentasi resmi: [membuat proyek Supabase](https://supabase.com/docs/guides/getting-started) dan [database/SQL Editor](https://supabase.com/docs/guides/database/overview).

1. Buka [supabase.com](https://supabase.com), pilih **Start your project** lalu masuk atau buat akun.
2. Dari dashboard, pilih **New project**. Jika diminta, buat organisasi terlebih dahulu dengan paket yang sesuai.
3. Isi nama proyek, misalnya `simpus-sekolah`. Buat **Database Password** yang kuat, simpan di password manager, dan jangan masukkan sandi database ini ke kode aplikasi.
4. Pilih region terdekat dengan sekolah. Pilih paket dan opsi yang tersedia, kemudian tekan **Create new project**. Tunggu sampai status proyek siap.
5. Di menu proyek, buka **SQL Editor** lalu pilih **New query**.
6. Pada komputer, buka `supabase/schema.sql` dengan editor teks (Notepad cukup), pilih seluruh isinya, lalu salin. Tempel ke SQL Editor Supabase.
7. Tekan **Run**. Tunggu sampai selesai. Jika ada pesan error, jangan lanjut membuat akun dulu: pastikan file utuh disalin dan tidak ada bagian yang terlewat. Proyek Supabase baru disarankan agar tidak bentrok dengan tabel lama.
8. (Opsional) Untuk mencoba aplikasi dengan data contoh, buat query baru, salin seluruh `supabase/seed.sql`, lalu tekan **Run**. Data seperti Nadia Contoh hanya data demo; hapus atau ganti sebelum dipakai sekolah.

### B. Ambil URL dan kunci publik Supabase

1. Di dashboard Supabase buka proyek, lalu tekan **Connect** untuk melihat Project URL dan publishable key. Keduanya juga tersedia di **Project Settings → API Keys**.
2. Salin **Project URL**. Bentuknya seperti `https://abcxyz.supabase.co`.
3. Salin **publishable key** (biasanya berawalan `sb_publishable_`). Kunci ini memang digunakan dari browser; akses datanya dibatasi oleh policy RLS yang dibuat oleh skema. Jika dashboard hanya menampilkan key lama, gunakan `anon` key.
4. Jangan salin `secret key` (biasanya `sb_secret_`), `service_role`, atau database password ke aplikasi. Key rahasia dapat melewati perlindungan RLS. Lihat [dokumentasi kunci API](https://supabase.com/docs/guides/getting-started/api-keys).
5. Buka `config.js` di folder proyek dengan Notepad/editor teks. Ganti dua nilai contoh berikut, pertahankan tanda petik:

```js
export const SUPABASE_URL = 'https://abcxyz.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJ...kunci-publik...';
export const SCHOOL_NAME = 'Perpustakaan SMP Contoh';
```

Simpan file. URL dan kunci publik boleh disertakan di frontend. Kunci rahasia tidak boleh.

### C. Buat akun pustakawan dan Kepala Sekolah

1. Di Supabase buka **Authentication → Users → Add user** (atau **Create new user**).
2. Masukkan email pustakawan sekolah dan sandi sementara. Catat UUID/ID pengguna yang muncul setelah dibuat.
3. Buka **SQL Editor → New query**, salin contoh di bawah, ganti UUID dan nama dengan milik pengguna tadi, lalu **Run**:

```sql
insert into public.profiles(id, full_name, role)
values ('UUID-PENGGUNA-DARI-AUTH', 'Nama Pustakawan', 'pustakawan');
```

4. Ulangi **Add user** untuk Kepala Sekolah dan jalankan query profil dengan role `kepala_sekolah`.
5. Gunakan email dan sandi akun tersebut untuk masuk SIMPUS. Anggota murid/guru perlu dibuat sebagai baris di menu Anggota terlebih dahulu, lalu profil Auth-nya ditautkan memakai SQL di bagian **Buat akun dengan aman** di bawah.
6. Jangan membuat akun bersama untuk beberapa staf. Setiap orang sebaiknya punya akun masing-masing supaya jejak audit dapat menunjukkan pelakunya.

### D. Coba aplikasi di komputer sendiri

1. Ekstrak ZIP proyek, lalu buka folder `simpus` yang berisi `index.html` dan `app.js`.
2. Pastikan `config.js` sudah disimpan dengan URL serta anon/publishable key tadi.
3. Buka PowerShell di folder `simpus`. Cara mudah: buka folder di File Explorer, klik kanan area kosong, pilih **Open in Terminal**.
4. Jalankan:

```powershell
python -m http.server 8080
```

5. Biarkan jendela terminal tetap terbuka. Buka browser dan kunjungi [http://localhost:8080](http://localhost:8080).
6. Masuk sebagai pustakawan. Bila layar menyebut profil belum tersedia, cek bahwa baris `profiles` dibuat dengan UUID yang sama persis dengan ID di **Authentication → Users**.
7. Untuk menghentikan server lokal, kembali ke PowerShell lalu tekan `Ctrl+C`.

Jika perintah `python` tidak dikenali, instal Python dari python.org atau gunakan editor seperti Visual Studio Code dengan ekstensi **Live Server**: buka folder proyek, klik kanan `index.html`, pilih **Open with Live Server**. Jangan membuka file dengan klik ganda (`file://`) karena browser tidak menjalankan modul aplikasi dengan benar.

### E. Terbitkan ke internet dengan Netlify Drop

1. Pastikan proyek sudah masuk ke akun lokal Supabase yang benar dan berhasil dibuka melalui `http://localhost:8080`.
2. Buka [app.netlify.com/drop](https://app.netlify.com/drop), masuk atau buat akun Netlify.
3. Seret folder `simpus` (folder yang di dalamnya langsung terlihat `index.html`) ke area unggah. Jangan menyeret folder induk yang hanya berisi folder `simpus`.
4. Tunggu proses upload selesai. Netlify memberi alamat sementara, misalnya `https://nama-acak.netlify.app`. Buka alamat itu untuk memastikan halaman login SIMPUS tampil.
5. Kembali ke Supabase, buka **Authentication → URL Configuration**. Isi **Site URL** dengan alamat Netlify tersebut. Lihat [panduan URL Auth resmi](https://supabase.com/docs/guides/auth/redirect-urls).
6. Di **Redirect URLs**, tambahkan alamat produksi dan lokal, misalnya:

```text
https://nama-acak.netlify.app/**
http://localhost:8080/**
```

Tekan **Save changes**. Untuk penggunaan produksi, utamakan URL pasti domain sekolah. Supabase juga mendukung wildcard `**` untuk URL preview, tetapi jangan membuka redirect ke domain yang tidak dikuasai sekolah.
7. Coba login lagi pada alamat Netlify. Pastikan pustakawan dapat mengelola data, Kepala Sekolah dapat melihat laporan, dan anggota hanya dapat melihat riwayatnya sendiri.
8. Jika mengubah file sesudah deploy, seret ulang folder `simpus` ke halaman deploy Netlify atau hubungkan repo Git agar perubahan diterbitkan otomatis.

Dokumentasi resmi: [deploy manual Netlify](https://docs.netlify.com/deploy/create-deploys/#drag-and-drop) dan [panduan Netlify Drop](https://docs.netlify.com/manage/projects/add-new-project/). Alternatif hosting statis: Cloudflare Pages atau GitHub Pages. Semua berkas harus dipublikasikan dengan `index.html` di root situs, mendukung HTTPS, dan menggunakan path relatif proyek.

### F. Hubungkan profil murid/guru ke data anggota

1. Masuk sebagai pustakawan, buka **Anggota**, lalu tambahkan anggota. Simpan nomor anggota yang dipakai.
2. Buat akun Auth untuk anggota melalui **Authentication → Users → Add user** dan catat UUID-nya.
3. Di SQL Editor jalankan (ganti UUID dan nomor anggota):

```sql
insert into public.profiles(id, full_name, role, member_id)
select 'UUID-PENGGUNA-DARI-AUTH', full_name, 'anggota', id
from public.members
where member_no = 'MUR-2026-0001';
```

4. Minta anggota masuk menggunakan email akun tersebut. Mereka akan melihat katalog, permintaan pinjam, dan riwayat milik sendiri.

### G. Isi data sekolah dan uji sebelum dipakai

1. Tambahkan anggota dan judul koleksi secara manual, atau buka **Impor & ekspor** untuk mengunduh template XLSX.
2. Untuk eksemplar, gunakan ID judul koleksi yang tercatat di database (bisa disalin dari tabel `items` di Supabase **Table Editor**). Buat satu barcode inventaris unik per barang.
3. Uji impor dengan beberapa baris contoh kecil lebih dahulu. Periksa layar pratinjau dan perbaiki kesalahan sebelum menekan impor.
4. Coba permintaan pinjam sebagai anggota, lalu setujui dan kembalikan sebagai pustakawan. Periksa status barang dan halaman audit.
5. Periksa bagian **Checklist go-live** di bawah, terutama pengujian akses per peran, data ganda, ukuran cetak, dan backup.

### Masalah umum

- **Konfigurasi belum diisi:** periksa `config.js`, URL harus diawali `https://` dan jangan ada spasi tambahan di nilai key.
- **Profil belum tersedia:** UUID pada `profiles.id` salah atau belum dibuat. Cocokkan dengan **Authentication → Users**.
- **Invalid login credentials:** cek email/sandi akun Auth. Role bukan bagian dari sandi, role berasal dari baris `profiles`.
- **Tabel tidak ada / relation not found:** `schema.sql` belum berhasil dijalankan pada proyek Supabase tersebut.
- **Akses ditolak / data kosong:** pastikan login masih aktif, profil punya role yang tepat, dan policy skema telah dibuat. Anggota harus memiliki `member_id`.
- **Data duplikat:** kode anggota, kode koleksi, barcode, dan permintaan aktif memang dibatasi unik. Gunakan kode lain atau periksa data lama sebelum mengulang impor.
- **Halaman putih setelah deploy:** pastikan yang diunggah adalah isi folder `simpus`, bukan folder yang salah; periksa juga koneksi internet/CDN.
- **Login lokal bekerja, deploy gagal:** pastikan URL Netlify dimasukkan ke Auth **Site URL** dan **Redirect URLs**, lalu simpan perubahan.

## Buat akun dengan aman

Jangan buat endpoint frontend untuk memberi peran. Jangan pernah menaruh service role key di `config.js`, HTML, repo, atau hosting. Role dapat diubah oleh administrator tepercaya melalui Supabase, bukan oleh pengguna dari browser.

## Integritas dan batasan versi awal

- Tombol aksi terkunci selama proses dan menunjukkan status. UUID idempotensi dipakai pada permintaan pinjam, checkout manual, pengembalian, dan kunjungan. Unique constraint, partial unique index, `FOR UPDATE`, dan RPC menghindari pinjaman ganda serta memperbarui transaksi dan eksemplar dalam transaksi atomik.
- Jika hasil request tidak jelas karena timeout, muat ulang daftar sebelum tindakan baru. UI membatasi klik ganda; database membatasi satu transaksi aktif/menunggu per eksemplar.
- Daftar UI dibatasi 500–1.000 baris. Impor memasukkan satu batch; pecah file besar. Cetak PDF memakai browser print-to-PDF. Validasi awal impor berlangsung di browser dan constraint database menjadi pemeriksaan akhir.
- QR/barcode memerlukan scanner/kamera eksternal. Scanner USB yang mengetik isi kode dapat dipakai di kolom scan; transaksi manual tetap tersedia.
- Paket frontend dimuat dari CDN versi tetap. Untuk jaringan sekolah tertutup, vendorkan paket dan pin checksum.
- Skema belum dijalankan pada akun sekolah dari workspace ini.

## Checklist go-live

- [ ] Jalankan skema pada proyek Supabase kosong dan pastikan objek SQL dibuat.
- [ ] Konfigurasi URL/key publik dan URL Auth domain produksi.
- [ ] Buat akun staf/profil peran dan tautkan akun anggota tanpa berbagi akun.
- [ ] Uji pustakawan membuat/mengedit anggota, judul dan eksemplar; kode sama harus ditolak.
- [ ] Uji kepala sekolah hanya membuka dashboard/laporan.
- [ ] Uji anggota hanya melihat katalog dan riwayat sendiri serta dapat mengirim permintaan.
- [ ] Uji scan kartu, transaksi manual, persetujuan/pengembalian, dan dua sesi mencoba eksemplar yang sama.
- [ ] Uji impor: kolom salah, data wajib kosong, duplikat dalam file, kode yang sudah ada, dan file valid.
- [ ] Cetak kartu/label individual dan massal, periksa ukuran printer.
- [ ] Uji ponsel, jaringan lambat/putus, sesi habis dan login kembali.
- [ ] Aktifkan backup terjadwal sesuai paket Supabase dan tetapkan penanggung jawab pemulihan.
