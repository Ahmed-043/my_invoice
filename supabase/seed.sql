-- Seed data for local Supabase development environment

-- Sample User Profile
insert into public.users (id, name, business_name, phone, email, app_status)
values (
  '11111111-1111-1111-1111-111111111111',
  'John Doe',
  'Acme Creative Studio',
  '+1234567890',
  'john@example.com',
  'allowed'
) on conflict (id) do nothing;

-- Sample Predefined Services
insert into public.predefined_services (id, user_id, name, description, default_price)
values (
  '66666666-6666-6666-6666-666666666666',
  '11111111-1111-1111-1111-111111111111',
  'Mobile App Development',
  'Custom Flutter mobile application development',
  500.00
) on conflict (id) do nothing;

-- Sample Project
insert into public.projects (id, user_id, client_name, brand_name, date_from, date_to, total_no_of_tasks, total_payment, paid_amount, services, shared_with)
values (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'Tech Corp',
  'TechCorp Global',
  '2025-01-01',
  '2025-01-15',
  2,
  1000.00,
  400.00,
  '[{"name": "UI/UX Design", "quantity": 1, "unit_price": 500.00, "total": 500.00}, {"name": "Mobile App Development", "quantity": 1, "unit_price": 500.00, "total": 500.00}]'::jsonb,
  '[]'::jsonb
) on conflict (id) do nothing;

-- Sample Tasks
insert into public.tasks (id, project_id, user_id, task_name, status)
values
  ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Design Figma Wireframes', 'completed'),
  ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Build Flutter UI Components', 'started')
on conflict (id) do nothing;

-- Sample Payment Entry
insert into public.payment_entries (id, project_id, user_id, account_no, payment_method, currency_type, discount_adjustments, payment_amount)
values (
  '55555555-5555-5555-5555-555555555555',
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'PK00123456789',
  'Bank Transfer',
  'USD',
  0.00,
  400.00
) on conflict (id) do nothing;
