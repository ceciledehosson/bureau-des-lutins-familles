-- Bureau des Lutins : édition multi-familles, projet Supabase distinct uniquement.
create extension if not exists pgcrypto with schema extensions;
create table public.families (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(trim(title)) between 1 and 80),
 invite_hash text not null unique,
 created_at timestamptz not null default now()
);
create table public.members (
 id uuid primary key default gen_random_uuid(),
 family_id uuid not null references public.families(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 60),
 code_hash text not null unique,
 created_at timestamptz not null default now(),
 unique(family_id,name)
);
create table public.wishes (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.members(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 180),
 details text not null default '' check(length(details) <= 1500),
 price numeric(10,2) check(price >= 0),
 url text not null default '' check(length(url) <= 1000),
 priority text not null default 'Ça me ferait plaisir'
 check(priority in ('J’en rêve','Ça me ferait plaisir','Si le Père Noël est riche')),
 created_at timestamptz not null default now()
);
create table public.reservations (
 wish_id uuid primary key references public.wishes(id) on delete cascade,
 organizer_id uuid not null references public.members(id) on delete cascade,
 status text not null default 'Réservé' check(status in ('Réservé','Acheté')),
 created_at timestamptz not null default now()
);
create table public.contributions (
 wish_id uuid not null references public.reservations(wish_id) on delete cascade,
 member_id uuid not null references public.members(id) on delete cascade,
 amount numeric(10,2) check(amount is null or amount>0),
 created_at timestamptz not null default now(),
 primary key(wish_id, member_id)
);
alter table public.families enable row level security;
alter table public.members enable row level security;
alter table public.wishes enable row level security;
alter table public.reservations enable row level security;
alter table public.contributions enable row level security;
revoke all on public.families,public.members,public.wishes,public.reservations,public.contributions from anon,authenticated;

create or replace function public.create_family(p_title text,p_name text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare f_id uuid; invite text; access_code text;
begin
 if length(trim(coalesce(p_title,''))) not between 1 and 80
 or length(trim(coalesce(p_name,''))) not between 1 and 60 then
 raise exception 'Nom de famille ou prénom invalide'; end if;
 invite := encode(extensions.gen_random_bytes(24),'hex');
 access_code := encode(extensions.gen_random_bytes(24),'hex');
 insert into public.families(title,invite_hash)
 values(trim(p_title),encode(extensions.digest(invite,'sha256'),'hex')) returning id into f_id;
 insert into public.members(family_id,name,code_hash)
 values(f_id,trim(p_name),encode(extensions.digest(access_code,'sha256'),'hex'));
 return jsonb_build_object('code',access_code,'invitation',invite);
end; $$;

create or replace function public.join_family(p_invitation text,p_name text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare f_id uuid; access_code text; existing_count integer;
begin
 if length(trim(coalesce(p_name,''))) not between 1 and 60 then raise exception 'Prénom invalide'; end if;
 select id into f_id from public.families where invite_hash =
 encode(extensions.digest(coalesce(p_invitation,''),'sha256'),'hex');
 if f_id is null then raise exception 'Invitation inconnue'; end if;
 perform 1 from public.families where id=f_id for update;
 select count(*) into existing_count from public.members where family_id=f_id;
 if existing_count >=20 then raise exception 'Ce Bureau a atteint 20 lutins'; end if;
 access_code := encode(extensions.gen_random_bytes(24),'hex');
 insert into public.members(family_id,name,code_hash)
 values(f_id,trim(p_name),encode(extensions.digest(access_code,'sha256'),'hex'));
 return jsonb_build_object('code',access_code);
exception when unique_violation then
 raise exception 'Ce prénom est déjà utilisé dans ce Bureau';
end; $$;

create or replace function public.board(p_code text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare me_id uuid; f_id uuid; board_data jsonb;
begin
 select id,family_id into me_id,f_id from public.members
 where code_hash=encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if me_id is null then return null; end if;
 select jsonb_build_object(
 'me',me_id,'family',(select title from public.families where id=f_id),
 'members',(select coalesce(jsonb_agg(jsonb_build_object('id',m.id,'name',m.name) order by m.name),'[]'::jsonb)
 from public.members m where m.family_id=f_id),
 'wishes',(select coalesce(jsonb_agg(jsonb_build_object(
 'id',w.id,'owner_id',w.owner_id,'title',w.title,'details',w.details,
 'price',w.price,'url',w.url,'priority',w.priority,
 'reservation',case when w.owner_id=me_id then null else
   (select jsonb_build_object('organizer_id',r.organizer_id,'status',r.status,
    'participants',(select coalesce(jsonb_agg(jsonb_build_object('member_id',c.member_id,'amount',c.amount)),'[]'::jsonb)
     from public.contributions c where c.wish_id=w.id))
    from public.reservations r where r.wish_id=w.id) end)
 order by w.created_at desc),'[]'::jsonb)
 from public.wishes w join public.members owner on owner.id=w.owner_id where owner.family_id=f_id)
 ) into board_data;
 return board_data;
end; $$;

create or replace function public.save_wish(p_code text,p_id uuid,p_title text,p_details text,p_price numeric,p_url text,p_priority text)
returns void language plpgsql security definer set search_path='' as $$
declare me_id uuid;
begin
 select id into me_id from public.members where code_hash=
 encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if me_id is null then raise exception 'Code invalide'; end if;
 if p_id is null then
 insert into public.wishes(owner_id,title,details,price,url,priority)
 values(me_id,trim(p_title),coalesce(p_details,''),p_price,coalesce(p_url,''),p_priority);
 else
 update public.wishes set title=trim(p_title),details=coalesce(p_details,''),
 price=p_price,url=coalesce(p_url,''),priority=p_priority
 where id=p_id and owner_id=me_id;
 if not found then raise exception 'Cadeau non autorisé'; end if;
 end if;
end; $$;

create or replace function public.delete_wish(p_code text,p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare me_id uuid;
begin
 select id into me_id from public.members where code_hash=
 encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if me_id is null then raise exception 'Code invalide'; end if;
 delete from public.wishes where id=p_id and owner_id=me_id;
 if not found then raise exception 'Cadeau non autorisé'; end if;
end; $$;

create or replace function public.reserve_wish(p_code text,p_wish_id uuid,p_action text)
returns void language plpgsql security definer set search_path='' as $$
declare me_id uuid; my_family uuid; gift_owner uuid; gift_family uuid;
begin
 select id,family_id into me_id,my_family from public.members where code_hash=
 encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if me_id is null then raise exception 'Code invalide'; end if;
 select w.owner_id,m.family_id into gift_owner,gift_family
 from public.wishes w join public.members m on m.id=w.owner_id where w.id=p_wish_id;
 if gift_family is distinct from my_family or gift_owner=me_id then raise exception 'Cadeau non autorisé'; end if;
 if p_action='reserve' then
 insert into public.reservations(wish_id,organizer_id) values(p_wish_id,me_id)
 on conflict(wish_id) do nothing;
 if not found then raise exception 'Cadeau déjà réservé'; end if;
 elsif p_action='buy' then
 update public.reservations set status='Acheté' where wish_id=p_wish_id and organizer_id=me_id;
 if not found then raise exception 'Tu ne coordonnes pas ce cadeau'; end if;
 elsif p_action='release' then
 perform 1 from public.reservations where wish_id=p_wish_id and organizer_id=me_id for update;
 if not found then raise exception 'Tu ne coordonnes pas ce cadeau'; end if;
 if exists(select 1 from public.contributions where wish_id=p_wish_id) then
 raise exception 'Les participants doivent se retirer avant la libération'; end if;
 delete from public.reservations where wish_id=p_wish_id and organizer_id=me_id;
 else raise exception 'Action inconnue'; end if;
end; $$;

create or replace function public.contribute(p_code text,p_wish_id uuid,p_action text,p_amount numeric)
returns void language plpgsql security definer set search_path='' as $$
declare me_id uuid; my_family uuid; gift_owner uuid; gift_family uuid; coordinator uuid;
begin
 select id,family_id into me_id,my_family from public.members where code_hash=
 encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if me_id is null then raise exception 'Code invalide'; end if;
 select w.owner_id,m.family_id,r.organizer_id into gift_owner,gift_family,coordinator
 from public.wishes w join public.members m on m.id=w.owner_id
 join public.reservations r on r.wish_id=w.id where w.id=p_wish_id for update of r;
 if gift_family is distinct from my_family or gift_owner=me_id or coordinator=me_id
 or coordinator is null then raise exception 'Participation non autorisée'; end if;
 if p_action='join' then
 insert into public.contributions(wish_id,member_id,amount) values(p_wish_id,me_id,p_amount)
 on conflict(wish_id,member_id) do update set amount=excluded.amount;
 elsif p_action='leave' then
 delete from public.contributions where wish_id=p_wish_id and member_id=me_id;
 else raise exception 'Action inconnue'; end if;
end; $$;

revoke all on function public.create_family(text,text) from public;
revoke all on function public.join_family(text,text) from public;
revoke all on function public.board(text) from public;
revoke all on function public.save_wish(text,uuid,text,text,numeric,text,text) from public;
revoke all on function public.delete_wish(text,uuid) from public;
revoke all on function public.reserve_wish(text,uuid,text) from public;
revoke all on function public.contribute(text,uuid,text,numeric) from public;
grant execute on function public.create_family(text,text) to anon,authenticated;
grant execute on function public.join_family(text,text) to anon,authenticated;
grant execute on function public.board(text) to anon,authenticated;
grant execute on function public.save_wish(text,uuid,text,text,numeric,text,text) to anon,authenticated;
grant execute on function public.delete_wish(text,uuid) to anon,authenticated;
grant execute on function public.reserve_wish(text,uuid,text) to anon,authenticated;
grant execute on function public.contribute(text,uuid,text,numeric) to anon,authenticated;
