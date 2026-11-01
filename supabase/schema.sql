-- SIMPUS schema v1 | Jalankan di SQL Editor proyek Supabase baru.
create extension if not exists pgcrypto;
create type public.app_role as enum ('pustakawan','kepala_sekolah','anggota');
create table public.members (
 id uuid primary key default gen_random_uuid(), member_no text not null unique, full_name text not null,
 member_type text not null check (member_type in ('Murid','Guru','Staf')), class_name text,
 email text, phone text, card_token uuid not null default gen_random_uuid() unique,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade, full_name text not null,
 role public.app_role not null default 'anggota', member_id uuid unique references public.members(id) on delete set null,
 created_at timestamptz not null default now()
);
create table public.items (
 id uuid primary key default gen_random_uuid(), inventory_code text not null unique, title text not null, creator text,
 kind text not null check (kind in ('Buku','Media','Alat peraga')), isbn text, publisher text,
 publish_year integer check (publish_year between 1000 and 2200), category text, location text, description text,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.copies (
 id uuid primary key default gen_random_uuid(), item_id uuid not null references public.items(id) on delete restrict,
 barcode text not null unique, condition text not null default 'Baik' check (condition in ('Baik','Rusak ringan','Rusak berat')),
 status text not null default 'Tersedia' check (status in ('Tersedia','Dipinjam','Perbaikan','Hilang')),
 acquired_on date, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.loans (
 id uuid primary key default gen_random_uuid(), member_id uuid not null references public.members(id) on delete restrict,
 copy_id uuid not null references public.copies(id) on delete restrict,
 status text not null check (status in ('Menunggu','Dipinjam','Dikembalikan','Ditolak','Dibatalkan')),
 requested_on date not null default current_date, due_on date, returned_on date, return_condition text,
 idempotency_key uuid not null unique, requested_by uuid not null default auth.uid() references auth.users(id),
 processed_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index one_open_loan_per_copy on public.loans(copy_id) where status in ('Menunggu','Dipinjam');
create index loans_member_recent on public.loans(member_id,created_at desc);
create table public.visits (
 id uuid primary key default gen_random_uuid(), member_id uuid references public.members(id) on delete set null,
 visitor_name text, purpose text not null default 'Umum', visited_at timestamptz not null default now(), active boolean not null default true,
 idempotency_key uuid not null unique, recorded_by uuid not null default auth.uid() references auth.users(id)
);
create table public.audit_log (
 id bigint generated always as identity primary key, table_name text not null, record_id uuid not null,
 action text not null, old_data jsonb, new_data jsonb, actor_id uuid default auth.uid() references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);
create index audit_recent on public.audit_log(created_at desc);
create function public.current_role() returns public.app_role language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
create function public.is_librarian() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(public.current_role()='pustakawan',false) $$;
create function public.audit_row() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.audit_log(table_name,record_id,action,old_data,new_data,actor_id)
 values(tg_table_name,coalesce(new.id,old.id),tg_op,to_jsonb(old),to_jsonb(new),auth.uid());
 return coalesce(new,old);
end $$;
create trigger audit_members after insert or update or delete on public.members for each row execute function public.audit_row();
create trigger audit_items after insert or update or delete on public.items for each row execute function public.audit_row();
create trigger audit_copies after insert or update or delete on public.copies for each row execute function public.audit_row();
create trigger audit_loans after insert or update or delete on public.loans for each row execute function public.audit_row();
create trigger audit_visits after insert or update or delete on public.visits for each row execute function public.audit_row();
create function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create trigger touch_members before update on public.members for each row execute function public.touch_updated_at();
create trigger touch_items before update on public.items for each row execute function public.touch_updated_at();
create trigger touch_copies before update on public.copies for each row execute function public.touch_updated_at();
create trigger touch_loans before update on public.loans for each row execute function public.touch_updated_at();
create function public.request_loan(p_item_id uuid,p_idempotency_key uuid) returns uuid language plpgsql security definer set search_path=public as $$
declare mid uuid; cid uuid; result uuid;
begin
 select id into result from public.loans where idempotency_key=p_idempotency_key;
 if result is not null then return result; end if;
 select member_id into mid from public.profiles where id=auth.uid() and role='anggota';
 if mid is null then raise exception 'Profil anggota tidak memiliki tautan data anggota.'; end if;
 select c.id into cid from public.copies c where c.item_id=p_item_id and c.status='Tersedia' order by c.barcode for update skip locked limit 1;
 if cid is null then raise exception 'Tidak ada eksemplar tersedia.'; end if;
 insert into public.loans(member_id,copy_id,status,idempotency_key) values(mid,cid,'Menunggu',p_idempotency_key)
 on conflict(idempotency_key) do nothing returning id into result;
 if result is null then select id into result from public.loans where idempotency_key=p_idempotency_key; end if;
 return result;
end $$;
create function public.checkout_manual(p_member_id uuid,p_copy_id uuid,p_due_on date,p_idempotency_key uuid) returns uuid language plpgsql security definer set search_path=public as $$
declare result uuid;
begin
 if not public.is_librarian() then raise exception 'Hanya pustakawan yang dapat mencatat peminjaman.'; end if;
 insert into public.loans(member_id,copy_id,status,due_on,idempotency_key,processed_by) values(p_member_id,p_copy_id,'Dipinjam',p_due_on,p_idempotency_key,auth.uid())
 on conflict(idempotency_key) do nothing returning id into result;
 if result is null then select id into result from public.loans where idempotency_key=p_idempotency_key; return result; end if;
 update public.copies set status='Dipinjam' where id=p_copy_id and status='Tersedia';
 if not found then raise exception 'Eksemplar sudah tidak tersedia.'; end if;
 return result;
end $$;
create function public.approve_loan(p_loan_id uuid,p_idempotency_key uuid) returns uuid language plpgsql security definer set search_path=public as $$
declare l public.loans; prior uuid;
begin
 if not public.is_librarian() then raise exception 'Akses pustakawan diperlukan.'; end if;
 select id into prior from public.loans where idempotency_key=p_idempotency_key; if prior is not null then return prior; end if;
 select * into l from public.loans where id=p_loan_id for update;
 if l.status='Dipinjam' then return l.id; end if;
 if l.status<>'Menunggu' then raise exception 'Permintaan bukan dalam status menunggu.'; end if;
 update public.copies set status='Dipinjam' where id=l.copy_id and status='Tersedia';
 if not found then update public.loans set status='Ditolak',processed_by=auth.uid() where id=l.id; raise exception 'Eksemplar sudah tidak tersedia.'; end if;
 update public.loans set status='Dipinjam',due_on=current_date+14,processed_by=auth.uid() where id=l.id;
 return l.id;
end $$;
create function public.return_loan(p_loan_id uuid,p_idempotency_key uuid,p_condition text default 'Baik') returns uuid language plpgsql security definer set search_path=public as $$
declare l public.loans; prior uuid;
begin
 if not public.is_librarian() then raise exception 'Akses pustakawan diperlukan.'; end if;
 select id into prior from public.loans where idempotency_key=p_idempotency_key; if prior is not null then return prior; end if;
 select * into l from public.loans where id=p_loan_id for update;
 if l.status='Dikembalikan' then return l.id; end if;
 if l.status<>'Dipinjam' then raise exception 'Peminjaman tidak berstatus aktif.'; end if;
 if p_condition not in ('Baik','Rusak ringan','Rusak berat') then raise exception 'Kondisi pengembalian tidak valid.'; end if;
 update public.loans set status='Dikembalikan',returned_on=current_date,return_condition=p_condition,processed_by=auth.uid() where id=l.id;
 update public.copies set status=case when p_condition='Baik' then 'Tersedia' else 'Perbaikan' end,condition=p_condition where id=l.copy_id;
 return l.id;
end $$;
create function public.record_visit(p_member_id uuid,p_visitor_name text,p_purpose text,p_idempotency_key uuid) returns uuid language plpgsql security definer set search_path=public as $$
declare result uuid;
begin
 if not public.is_librarian() then raise exception 'Hanya pustakawan yang dapat mencatat kunjungan.'; end if;
 insert into public.visits(member_id,visitor_name,purpose,idempotency_key) values(p_member_id,nullif(p_visitor_name,''),coalesce(nullif(p_purpose,''),'Umum'),p_idempotency_key)
 on conflict(idempotency_key) do nothing returning id into result;
 if result is null then select id into result from public.visits where idempotency_key=p_idempotency_key; end if; return result;
end $$;
alter table public.profiles enable row level security;
alter table public.members enable row level security;
alter table public.items enable row level security;
alter table public.copies enable row level security;
alter table public.loans enable row level security;
alter table public.visits enable row level security;
alter table public.audit_log enable row level security;
create policy profiles_read_self_or_staff on public.profiles for select to authenticated using(id=auth.uid() or public.current_role() in ('pustakawan','kepala_sekolah'));
create policy members_read on public.members for select to authenticated using(public.is_librarian() or public.current_role()='kepala_sekolah' or id=(select member_id from public.profiles where id=auth.uid()));
create policy members_manage on public.members for all to authenticated using(public.is_librarian()) with check(public.is_librarian());
create policy items_read on public.items for select to authenticated using(true);
create policy items_manage on public.items for all to authenticated using(public.is_librarian()) with check(public.is_librarian());
create policy copies_read on public.copies for select to authenticated using(true);
create policy copies_manage on public.copies for all to authenticated using(public.is_librarian()) with check(public.is_librarian());
create policy loans_read on public.loans for select to authenticated using(public.is_librarian() or public.current_role()='kepala_sekolah' or member_id=(select member_id from public.profiles where id=auth.uid()));
create policy loans_manage on public.loans for all to authenticated using(public.is_librarian()) with check(public.is_librarian());
create policy visits_manage on public.visits for all to authenticated using(public.is_librarian()) with check(public.is_librarian());
create policy audit_staff_read on public.audit_log for select to authenticated using(public.is_librarian() or public.current_role()='kepala_sekolah');
grant usage on schema public to authenticated;
grant select,insert,update,delete on public.members,public.items,public.copies,public.loans,public.visits to authenticated;
grant select on public.profiles,public.audit_log to authenticated;
grant usage,select on sequence public.audit_log_id_seq to authenticated;
grant execute on function public.request_loan(uuid,uuid),public.checkout_manual(uuid,uuid,date,uuid),public.approve_loan(uuid,uuid),public.return_loan(uuid,uuid,text),public.record_visit(uuid,text,text,uuid) to authenticated;
