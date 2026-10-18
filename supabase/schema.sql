-- هيكل قاعدة بيانات برنامج جمعية آيات الخيرية
-- مبني على هيكل برنامج تراث (بدون أي بيانات، وبدون جداول بوت واتساب والكلمة الطيبة).

create extension if not exists "uuid-ossp" with schema extensions;

-- ========== الجداول ==========

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role = any (array['admin','supervisor','teacher','parent'])),
  phone text,
  created_at timestamptz default now(),
  civil_id text,
  civil_id_photo text
);

create table public.circles (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  teacher_id uuid references public.profiles(id),
  schedule text,
  location text,
  created_at timestamptz default now(),
  teacher_name text,
  teacher_profile_id uuid references public.profiles(id)
);

create table public.students (
  id uuid primary key default extensions.uuid_generate_v4(),
  full_name text not null,
  circle_id uuid references public.circles(id),
  parent_id uuid references public.profiles(id),
  birth_year integer,
  total_points integer default 0,
  created_at timestamptz default now(),
  civil_id text,
  civil_id_photo text,
  photo text,
  school_level text,
  school_type text,
  area text,
  current_level text,
  parent_name text,
  parent_civil_id text,
  parent_relation text,
  parent_phone text,
  birth_date date
);

create table public.attendance (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id),
  circle_id uuid references public.circles(id),
  date date not null,
  status text check (status = any (array['present','absent','excused'])),
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table public.memorization_log (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id),
  date date not null,
  surah_from text not null,
  ayah_from integer not null,
  surah_to text not null,
  ayah_to integer not null,
  verses_count integer not null,
  mastery text check (mastery = any (array['excellent','good','needs_review','weak'])),
  notes text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table public.review_log (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id),
  date date not null,
  surah_from text not null,
  ayah_from integer not null,
  surah_to text not null,
  ayah_to integer not null,
  notes text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  mastery text default 'good'
);

create table public.teacher_evaluations (
  id uuid primary key default extensions.uuid_generate_v4(),
  teacher_id uuid references public.profiles(id),
  evaluator_id uuid references public.profiles(id),
  eval_date date not null,
  memorization_plan integer,
  review_plan integer,
  circle_record integer,
  student_errors integer,
  circle_appearance integer,
  parent_communication integer,
  total_score integer,
  notes text,
  created_at timestamptz default now(),
  supervisor_name text,
  teacher_name text,
  visits integer default 1
);

create table public.points_log (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id),
  points integer not null,
  reason text,
  awarded_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table public.behavior_log (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id) on delete cascade,
  date date not null,
  score integer check (score >= 1 and score <= 5),
  notes text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table public.student_weekly_score (
  id uuid primary key default extensions.uuid_generate_v4(),
  student_id uuid references public.students(id) on delete cascade,
  circle_id uuid references public.circles(id),
  week_start date not null,
  memo_score numeric default 0,
  attendance_score numeric default 0,
  behavior_score numeric default 0,
  total_score numeric default 0,
  rank_in_circle integer,
  created_at timestamptz default now()
);

create table public.supervisor_circles (
  id uuid primary key default extensions.uuid_generate_v4(),
  supervisor_id uuid references public.profiles(id) on delete cascade,
  circle_id uuid references public.circles(id) on delete cascade,
  created_at timestamptz default now(),
  unique (supervisor_id, circle_id)
);

create table public.monthly_reports (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references public.profiles(id),
  circle_id uuid references public.circles(id),
  month integer not null,
  year integer not null,
  report_data jsonb,
  teacher_notes text,
  status text default 'draft' check (status = any (array['draft','submitted'])),
  submitted_at timestamptz,
  created_at timestamptz default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  to_user_id uuid references public.profiles(id),
  from_user_id uuid references public.profiles(id),
  type text,
  title text,
  body text,
  is_read boolean default false,
  related_id uuid,
  created_at timestamptz default now()
);

create table public.donors (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  notes text,
  created_at timestamptz default now()
);

create table public.donor_circles (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid references public.donors(id) on delete cascade,
  circle_id uuid references public.circles(id) on delete cascade
);

create table public.student_leave (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.students(id) on delete cascade,
  from_date date not null,
  to_date date not null,
  reason text,
  notes text,
  recorded_by uuid,
  created_at timestamptz default now()
);

create table public.weekly_report_sends (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references public.profiles(id) on delete cascade,
  week_start date not null,
  sent_count integer default 0,
  created_at timestamptz default now(),
  circle_id uuid references public.circles(id) on delete cascade
);

-- ========== الفهارس ==========
create index idx_attendance_circle_date on public.attendance (circle_id, date);
create index idx_attendance_student on public.attendance (student_id);
create index idx_behavior_student on public.behavior_log (student_id);
create index idx_memo_date on public.memorization_log (date);
create index idx_memo_student on public.memorization_log (student_id);
create index idx_monthly_reports_teacher on public.monthly_reports (teacher_id, month, year);
create index idx_profiles_role on public.profiles (role);
create index idx_review_student on public.review_log (student_id);
create index idx_students_circle on public.students (circle_id);
create index idx_supervisor_circles on public.supervisor_circles (supervisor_id);

-- ========== الدوال المساعدة ==========
create or replace function public.current_user_role() returns text
  language sql stable security definer set search_path to 'public' as
$$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_admin() returns boolean
  language sql stable security definer set search_path to 'public' as
$$ select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false) $$;

create or replace function public.is_staff() returns boolean
  language sql stable security definer set search_path to 'public' as
$$ select coalesce((select role in ('admin','supervisor') from public.profiles where id = auth.uid()), false) $$;

create or replace function public.parent_has_child_in_circle(p_circle uuid) returns boolean
  language sql stable security definer set search_path to 'public' as
$$ select exists (select 1 from public.students s where s.circle_id = p_circle and s.parent_id = auth.uid()) $$;

create or replace function public.public_stats() returns json
  language sql stable security definer set search_path to 'public' as
$$
  select json_build_object(
    'circles_count', (select count(*) from circles),
    'students_count', (select count(*) from students),
    'total_verses_memorized', (
      select coalesce(sum(verses_count), 0)
      from memorization_log
      where date >= date_trunc('month', current_date)::date
    )
  );
$$;

-- الصلاحيات على الدوال: المساعدة للمسجّلين فقط، والإحصاءات العامة للجميع
revoke execute on function public.current_user_role() from public, anon;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_staff() from public, anon;
revoke execute on function public.parent_has_child_in_circle(uuid) from public, anon;
revoke execute on function public.public_stats() from public;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_staff() to authenticated;
grant execute on function public.parent_has_child_in_circle(uuid) to authenticated;
grant execute on function public.public_stats() to anon, authenticated;

-- ========== أمان الصفوف ==========
alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.students enable row level security;
alter table public.attendance enable row level security;
alter table public.memorization_log enable row level security;
alter table public.review_log enable row level security;
alter table public.teacher_evaluations enable row level security;
alter table public.points_log enable row level security;
alter table public.behavior_log enable row level security;
alter table public.student_weekly_score enable row level security;
alter table public.supervisor_circles enable row level security;
alter table public.monthly_reports enable row level security;
alter table public.notifications enable row level security;
alter table public.donors enable row level security;
alter table public.donor_circles enable row level security;
alter table public.student_leave enable row level security;
alter table public.weekly_report_sends enable row level security;

-- صلاحيات الجداول للمستخدمين المسجّلين فقط (الزائر غير المسجّل لا يصل لأي جدول)
grant select, insert, update, delete on
  public.profiles, public.circles, public.students, public.attendance, public.memorization_log,
  public.review_log, public.teacher_evaluations, public.points_log, public.behavior_log,
  public.student_weekly_score, public.supervisor_circles, public.monthly_reports,
  public.notifications, public.donors, public.donor_circles, public.student_leave,
  public.weekly_report_sends
to authenticated;

-- profiles
create policy profiles_admin_all on public.profiles for all to authenticated using (is_admin()) with check (is_admin());
create policy profiles_select_own on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_update_own on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = current_user_role());

-- circles
create policy admin_all_circles on public.circles for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy circles_parent_read on public.circles for select to authenticated using (parent_has_child_in_circle(id));
create policy teacher_read_circles on public.circles for select using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','teacher','supervisor'])));

-- students
create policy admin_all_students on public.students for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy parent_own_child on public.students for select using (auth.uid() = parent_id);
create policy teacher_manage_own_students on public.students for all using (exists (select 1 from circles where circles.id = students.circle_id and circles.teacher_id = auth.uid()));
create policy teacher_own_students on public.students for select using ((exists (select 1 from circles where circles.id = students.circle_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));
create policy teacher_sees_own_students on public.students for select using (circle_id in (select circles.id from circles where circles.teacher_id = auth.uid()));

-- attendance
create policy admin_all_attendance on public.attendance for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy parent_child_attendance on public.attendance for select using (exists (select 1 from students where students.id = attendance.student_id and students.parent_id = auth.uid()));
create policy teacher_own_attendance on public.attendance for all using ((exists (select 1 from circles where circles.id = attendance.circle_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));

-- memorization_log
create policy admin_all_memo on public.memorization_log for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy parent_child_memo on public.memorization_log for select using (exists (select 1 from students where students.id = memorization_log.student_id and students.parent_id = auth.uid()));
create policy teacher_own_memo on public.memorization_log for all using ((exists (select 1 from students join circles on circles.id = students.circle_id where students.id = memorization_log.student_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));

-- review_log
create policy admin_all_review on public.review_log for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy parent_child_review on public.review_log for select using (exists (select 1 from students where students.id = review_log.student_id and students.parent_id = auth.uid()));
create policy teacher_own_review on public.review_log for all using ((exists (select 1 from students join circles on circles.id = students.circle_id where students.id = review_log.student_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));

-- behavior_log
create policy admin_all_behavior on public.behavior_log for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy parent_child_behavior on public.behavior_log for select using (exists (select 1 from students where students.id = behavior_log.student_id and students.parent_id = auth.uid()));
create policy teacher_own_behavior on public.behavior_log for all using ((exists (select 1 from students join circles on circles.id = students.circle_id where students.id = behavior_log.student_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));

-- points_log
create policy points_admin_all on public.points_log for all to authenticated using (is_admin()) with check (is_admin());
create policy points_parent_read on public.points_log for select to authenticated using (exists (select 1 from students s where s.id = points_log.student_id and s.parent_id = auth.uid()));
create policy points_teacher_own on public.points_log for all to authenticated
  using (is_staff() or exists (select 1 from students s join circles c on c.id = s.circle_id where s.id = points_log.student_id and c.teacher_id = auth.uid()))
  with check (is_staff() or exists (select 1 from students s join circles c on c.id = s.circle_id where s.id = points_log.student_id and c.teacher_id = auth.uid()));

-- student_weekly_score
create policy weekly_score_admin_all on public.student_weekly_score for all to authenticated using (is_admin()) with check (is_admin());
create policy weekly_score_parent_read on public.student_weekly_score for select to authenticated using (exists (select 1 from students s where s.id = student_weekly_score.student_id and s.parent_id = auth.uid()));
create policy weekly_score_teacher on public.student_weekly_score for all to authenticated
  using (is_staff() or exists (select 1 from circles c where c.id = student_weekly_score.circle_id and c.teacher_id = auth.uid()))
  with check (is_staff() or exists (select 1 from circles c where c.id = student_weekly_score.circle_id and c.teacher_id = auth.uid()));

-- supervisor_circles
create policy admin_all_sup_circles on public.supervisor_circles for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy supervisor_own_circles on public.supervisor_circles for select using ((auth.uid() = supervisor_id) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin')));

-- teacher_evaluations
create policy admin_all_evaluations on public.teacher_evaluations for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy supervisor_evaluations on public.teacher_evaluations for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor'])));

-- monthly_reports
create policy admin_all_monthly_reports on public.monthly_reports for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy teacher_own_reports on public.monthly_reports for all using ((auth.uid() = teacher_id) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));
create policy teachers_can_read_own_monthly_reports on public.monthly_reports for select using (teacher_id = auth.uid());

-- notifications
create policy admin_all_notifications on public.notifications for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy own_notifications on public.notifications for all using ((auth.uid() = to_user_id) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin')));
create policy parent_can_notify_admin on public.notifications for insert to authenticated with check ((auth.uid() = from_user_id) and exists (select 1 from profiles where profiles.id = notifications.to_user_id and profiles.role = 'admin'));

-- donors / donor_circles
create policy admin_all_donors on public.donors for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy donor_circles_admin_all on public.donor_circles for all to authenticated using (is_admin()) with check (is_admin());

-- student_leave
create policy admin_all_leave on public.student_leave for all using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy teacher_own_leave on public.student_leave for all using ((exists (select 1 from students join circles on circles.id = students.circle_id where students.id = student_leave.student_id and circles.teacher_id = auth.uid())) or (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))));

-- weekly_report_sends
create policy admin_supervisor_read_weekly_sends on public.weekly_report_sends for select to authenticated using ((exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','supervisor']))) or (auth.uid() = teacher_id));
create policy teacher_insert_own_weekly_send on public.weekly_report_sends for insert to authenticated with check (auth.uid() = teacher_id);

-- ========== التخزين (صور الطلاب والهويات) ==========
-- ملاحظة: الحاويتان عامتان لأن البرنامج يحفظ روابط عامة للصور. يُنصح لاحقاً بالتحويل إلى روابط موقّعة.
insert into storage.buckets (id, name, public) values ('civil-ids','civil-ids',false), ('student-photos','student-photos',true)
  on conflict (id) do nothing;

create policy "Auth upload civil-ids" on storage.objects for insert with check (bucket_id = 'civil-ids' and auth.role() = 'authenticated');
create policy "Auth upload student-photos" on storage.objects for insert with check (bucket_id = 'student-photos' and auth.role() = 'authenticated');
create policy "Staff read civil-ids" on storage.objects for select using (bucket_id = 'civil-ids' and is_staff());
create policy "Staff delete civil-ids" on storage.objects for delete to authenticated using (bucket_id = 'civil-ids' and is_staff());
create policy "Staff read student-photos" on storage.objects for select using (bucket_id = 'student-photos' and is_staff());

-- ========== طبقة المراكز (مركز ← حلقات) ==========
create table if not exists public.centers (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  location text,
  created_at timestamptz default now()
);
alter table public.centers enable row level security;
create policy admin_all_centers on public.centers for all
  using (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'))
  with check (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'));
create policy staff_read_centers on public.centers for select to authenticated
  using (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = any (array['admin','teacher','supervisor'])));
alter table public.circles add column if not exists center_id uuid references public.centers(id) on delete set null;
alter table public.circles add column if not exists label text;
create index if not exists circles_center_id_idx on public.circles(center_id);
grant select, insert, update, delete on public.centers to authenticated;
