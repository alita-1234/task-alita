-- Alita Task Workspace: Supabase schema
-- รันไฟล์นี้หนึ่งครั้งใน Supabase Dashboard > SQL Editor

create extension if not exists pgcrypto;

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade default auth.uid(),
  type text not null check (type in ('project', 'general')),
  title text not null check (char_length(title) between 1 and 500),
  priority text not null default 'Medium' check (priority in ('High', 'Medium', 'Low')),
  registered_date date not null default current_date,
  due_date date,
  status text not null default 'ยังไม่เริ่ม' check (status in ('ยังไม่เริ่ม', 'กำลังทำ', 'ตรวจสอบเอกสาร', 'เสร็จสิ้น')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subtasks (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 500),
  checked boolean not null default false,
  note text not null default '',
  days_spent integer not null default 0 check (days_spent >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists subtasks_task_id_idx on public.subtasks(task_id);
create index if not exists tasks_created_at_idx on public.tasks(created_at desc);

-- ประเภทระบบงานที่ Admin จัดการได้
create table if not exists public.task_types (
  code text primary key check (code ~ '^[a-z0-9][a-z0-9_-]{1,39}$'),
  name text not null check (char_length(name) between 1 and 100),
  template_kind text not null default 'general' check (template_kind in ('project', 'general')),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
insert into public.task_types (code, name, template_kind, is_active, sort_order) values
  ('project', 'โครงการจัดซื้อจัดจ้าง', 'project', true, 10),
  ('general', 'งานทั่วไป / Task ของกอง', 'general', true, 20)
on conflict (code) do nothing;

alter table public.tasks drop constraint if exists tasks_type_check;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'tasks_type_fkey') then
    alter table public.tasks add constraint tasks_type_fkey foreign key (type)
      references public.task_types(code) on update cascade on delete restrict;
  end if;
end $$;

alter table public.tasks enable row level security;
alter table public.subtasks enable row level security;
alter table public.task_types enable row level security;

-- รองรับฐานข้อมูลที่เคยรัน schema เวอร์ชัน Prototype ไปแล้ว
alter table public.tasks
  add column if not exists user_id uuid references auth.users(id) on delete cascade default auth.uid();
alter table public.tasks
  add column if not exists registered_date date not null default current_date;
create index if not exists tasks_user_id_idx on public.tasks(user_id);

drop policy if exists "prototype tasks access" on public.tasks;
drop policy if exists "prototype subtasks access" on public.subtasks;
drop policy if exists "users manage own tasks" on public.tasks;
create policy "users manage own tasks" on public.tasks
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users manage subtasks of own tasks" on public.subtasks;
create policy "users manage subtasks of own tasks" on public.subtasks
  for all to authenticated
  using (exists (
    select 1 from public.tasks
    where tasks.id = subtasks.task_id and tasks.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.tasks
    where tasks.id = subtasks.task_id and tasks.user_id = auth.uid()
  ));

revoke all on public.tasks from anon;
revoke all on public.subtasks from anon;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.subtasks to authenticated;
grant select on public.task_types to authenticated;
revoke insert, update, delete on public.task_types from authenticated;

drop policy if exists "authenticated read task types" on public.task_types;
create policy "authenticated read task types" on public.task_types
  for select to authenticated using (true);

-- รายชื่ออีเมล Admin หลัก เก็บฝั่งฐานข้อมูลเท่านั้น
create table if not exists public.admin_allowlist (
  email text primary key,
  created_at timestamptz not null default now()
);
alter table public.admin_allowlist enable row level security;
revoke all on public.admin_allowlist from anon, authenticated;
insert into public.admin_allowlist (email) values ('aalita1234@gmail.com')
on conflict (email) do nothing;

-- User profiles and role-based access: admin / user
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'user' check (role in ('admin', 'user')),
  is_approved boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.profiles add column if not exists is_approved boolean not null default true;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email, role, is_approved, created_at, updated_at)
  values (
    new.id,
    coalesce(new.email, ''),
    case when exists (
      select 1 from public.admin_allowlist a where lower(a.email) = lower(coalesce(new.email, ''))
    ) then 'admin' else 'user' end,
    case when exists (
      select 1 from public.admin_allowlist a where lower(a.email) = lower(coalesce(new.email, ''))
    ) then true else coalesce(new.raw_app_meta_data ->> 'provider', '') <> 'google' end,
    now(),
    now()
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute procedure public.handle_new_user();

insert into public.profiles (id, email, role, created_at, updated_at)
select id, coalesce(email, ''), 'user', created_at, now() from auth.users
on conflict (id) do nothing;

-- คืนและคงสิทธิ์ Admin ตาม allowlist แม้ profile เคยถูกสร้างใหม่
update public.profiles p
set role = 'admin', is_approved = true, updated_at = now()
from public.admin_allowlist a
where lower(p.email) = lower(a.email);

update public.profiles set role = 'admin', updated_at = now()
where id = (select id from public.profiles order by created_at asc limit 1)
and not exists (select 1 from public.profiles where role = 'admin');

-- Admin เข้าใช้งานได้เสมอ ส่วนบัญชี Google ที่มีอยู่จะรอ Admin อนุมัติ
update public.profiles set is_approved = true, updated_at = now() where role = 'admin';
update public.profiles p set is_approved = false, updated_at = now()
from auth.users u
where p.id = u.id and p.role <> 'admin'
  and p.updated_at = p.created_at
  and coalesce(u.raw_app_meta_data ->> 'provider', '') = 'google';

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create or replace function public.is_approved()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and (is_approved = true or role = 'admin')
  );
$$;
revoke all on function public.is_approved() from public;
grant execute on function public.is_approved() to authenticated;

-- ซ่อมบัญชีที่มีอยู่ใน auth.users แต่ยังไม่มีแถวใน profiles
create or replace function public.ensure_my_profile()
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email, role, is_approved, created_at, updated_at)
  select
    u.id,
    coalesce(u.email, ''),
    case when exists (
      select 1 from public.admin_allowlist a where lower(a.email) = lower(coalesce(u.email, ''))
    ) then 'admin' else 'user' end,
    case when exists (
      select 1 from public.admin_allowlist a where lower(a.email) = lower(coalesce(u.email, ''))
    ) then true else coalesce(u.raw_app_meta_data ->> 'provider', '') <> 'google' end,
    now(),
    now()
  from auth.users u
  where u.id = auth.uid()
  on conflict (id) do nothing;
end;
$$;
revoke all on function public.ensure_my_profile() from public;
grant execute on function public.ensure_my_profile() to authenticated;

drop policy if exists "users read own profile admins read all" on public.profiles;
create policy "users read own profile admins read all" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());
grant select on public.profiles to authenticated;
revoke insert, update, delete on public.profiles from authenticated;

create or replace function public.admin_set_user_role(target_user_id uuid, new_role text)
returns void language plpgsql security definer set search_path = '' as $$
declare admin_count integer; target_current_role text;
begin
  if not public.is_admin() then raise exception 'Admin permission required'; end if;
  if new_role not in ('admin', 'user') then raise exception 'Invalid role'; end if;
  select role into target_current_role from public.profiles where id = target_user_id;
  if target_current_role is null then raise exception 'User not found'; end if;
  if target_current_role = 'admin' and new_role = 'user' then
    select count(*) into admin_count from public.profiles where role = 'admin';
    if admin_count <= 1 then raise exception 'Cannot demote the last admin'; end if;
  end if;
  update public.profiles set role = new_role, updated_at = now() where id = target_user_id;
end;
$$;
revoke all on function public.admin_set_user_role(uuid, text) from public;
grant execute on function public.admin_set_user_role(uuid, text) to authenticated;

create or replace function public.admin_set_user_approval(target_user_id uuid, approved boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare target_role text;
begin
  if not public.is_admin() then raise exception 'Admin permission required'; end if;
  select role into target_role from public.profiles where id = target_user_id;
  if target_role is null then raise exception 'User not found'; end if;
  if target_role = 'admin' and not approved then raise exception 'Admin accounts cannot be disabled'; end if;
  update public.profiles set is_approved = approved, updated_at = now()
  where id = target_user_id;
end;
$$;
revoke all on function public.admin_set_user_approval(uuid, boolean) from public;
grant execute on function public.admin_set_user_approval(uuid, boolean) to authenticated;

create or replace function public.admin_save_task_type(
  type_code text, type_name text, type_template_kind text, type_is_active boolean
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admin permission required'; end if;
  type_code := lower(trim(type_code));
  type_name := trim(type_name);
  if type_code !~ '^[a-z0-9][a-z0-9_-]{1,39}$' then raise exception 'Invalid type code'; end if;
  if char_length(type_name) < 1 or char_length(type_name) > 100 then raise exception 'Invalid type name'; end if;
  if type_template_kind not in ('project', 'general') then raise exception 'Invalid template kind'; end if;
  insert into public.task_types (code, name, template_kind, is_active, sort_order, updated_at)
  values (type_code, type_name, type_template_kind, type_is_active,
    coalesce((select max(sort_order) + 10 from public.task_types), 10), now())
  on conflict (code) do update set
    name = excluded.name,
    template_kind = excluded.template_kind,
    is_active = excluded.is_active,
    updated_at = now();
end;
$$;
revoke all on function public.admin_save_task_type(text, text, text, boolean) from public;
grant execute on function public.admin_save_task_type(text, text, text, boolean) to authenticated;

create or replace function public.admin_delete_task_type(type_code text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admin permission required'; end if;
  if type_code in ('project', 'general') then raise exception 'Default task types cannot be deleted'; end if;
  if exists (select 1 from public.tasks where type = type_code) then
    raise exception 'Task type is currently in use';
  end if;
  delete from public.task_types where code = type_code;
end;
$$;
revoke all on function public.admin_delete_task_type(text) from public;
grant execute on function public.admin_delete_task_type(text) to authenticated;

drop policy if exists "users manage own tasks" on public.tasks;
create policy "users manage own tasks" on public.tasks for all to authenticated
  using ((auth.uid() = user_id and public.is_approved()) or public.is_admin())
  with check ((auth.uid() = user_id and public.is_approved()) or public.is_admin());

drop policy if exists "users manage subtasks of own tasks" on public.subtasks;
create policy "users manage subtasks of own tasks" on public.subtasks for all to authenticated
  using (exists (select 1 from public.tasks where tasks.id = subtasks.task_id and ((tasks.user_id = auth.uid() and public.is_approved()) or public.is_admin())))
  with check (exists (select 1 from public.tasks where tasks.id = subtasks.task_id and ((tasks.user_id = auth.uid() and public.is_approved()) or public.is_admin())));
